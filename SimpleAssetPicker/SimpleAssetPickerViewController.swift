//
//  SimpleAssetPickerViewController.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/21/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import PureLayout

private let AssetCollectionCellReuseIdentifier = "AssetCollectionViewCellIdentifier"

public protocol SimpleAssetPickerDelegate: class {
    func didCancel(_ picker: SimpleAssetPickerViewController)
    func didSatisfyMediaRequirements(_ picker: SimpleAssetPickerViewController, assets: [PHAsset]?)
    func didBreakMediaRequirements(_ picker: SimpleAssetPickerViewController)
}

open class SimpleAssetPickerViewController: UIViewController {

    // Public vars
    open weak var delegate: SimpleAssetPickerDelegate?
    open lazy var assetsFetchResults: PHFetchResult = { () -> PHFetchResult<PHAsset> in 
        let mediaFetchOptions = PHFetchOptions()
        mediaFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if let mediaType = SimpleAssetPickerConfig.sharedConfig().pickerMediaType {
            if mediaType == .video || mediaType == .image || mediaType == .audio {
                mediaFetchOptions.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
            }
        }
        return PHAsset.fetchAssets(with: mediaFetchOptions)
    }()
    open var selectedAssets = [PHAsset]()

    // Private vars
    fileprivate var imageManager: PHCachingImageManager?
    fileprivate var libraryAccessGranted: Bool = false
    fileprivate var previousPreheatRect: CGRect = CGRect.zero
    fileprivate var assetGridThumbnailSize = CGSize()
    fileprivate var assetBundle: Bundle?
    fileprivate var topConstraint: NSLayoutConstraint?
    fileprivate lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        return UICollectionViewFlowLayout()
        
    }()
    fileprivate lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: self.view.frame, collectionViewLayout: self.collectionViewLayout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .white
        cv.delegate   = self
        cv.dataSource = self
        cv.register(AssetCollectionViewCell.self, forCellWithReuseIdentifier: AssetCollectionCellReuseIdentifier)
        cv.allowsSelection = true
        cv.allowsMultipleSelection = true
        self.view.addSubview(cv)
        
        self.topConstraint = cv.autoPinEdge(toSuperviewEdge: .top, withInset: 64)
        cv.autoPinEdge(toSuperviewEdge: .bottom)
        cv.autoPinEdge(toSuperviewEdge: .right)
        cv.autoPinEdge(toSuperviewEdge: .left)
        return cv
    }()
    

    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }

    // MARK: - Lifecycle
    override open func viewDidLoad() {
        super.viewDidLoad()

        // Make sure we have access to Photos Library before attempting to load assets.
        requestPermissions { (granted) -> Void in
            if granted == true {
                self.libraryAccessGranted = true
                self.imageManager = PHCachingImageManager()
                self.resetCachedAssets()
                PHPhotoLibrary.shared().register(self)
            } else {
                print("No access to Photo Library.")
                // self.showNoAccessView()
            }
        }

        let podBundle = Bundle(for: self.classForCoder)
        if let bundleURL = podBundle.url(forResource: "SimpleAssetPicker", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                self.assetBundle = bundle
            }
        }
    }

    deinit {
        if libraryAccessGranted == true {
            PHPhotoLibrary.shared().unregisterChangeObserver(self)
        }
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if !libraryAccessGranted { return }

        let config = SimpleAssetPickerConfig.sharedConfig()

        // Configure contentInset, scrollIndicatorInset, and flowLayout properties for collectionView.
        if  let edgeInsets = config.collectionViewEdgeInsets,
            let numberOfItemsPerRow = config.numberOfItemsPerRow {
            collectionView.contentInset = edgeInsets
            collectionView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

            let screenWidth = UIScreen.main.bounds.width
            let horizontalSections = numberOfItemsPerRow + 1
            let cellWidth = floor((screenWidth - (CGFloat(horizontalSections) * (edgeInsets.left)) ) / CGFloat(numberOfItemsPerRow))

            collectionViewLayout.minimumLineSpacing = CGFloat(config.verticalCellSpacing ?? 0.0)
            collectionViewLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)

            assetGridThumbnailSize = CGSize(width: cellWidth * 2.0, height: cellWidth * 2.0)
        }

        topConstraint?.autoRemove()
        if UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
            topConstraint = collectionView.autoPinEdge(toSuperviewEdge: .top, withInset: 44)
        } else {
            topConstraint = collectionView.autoPinEdge(toSuperviewEdge: .top, withInset: 64)
        }
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Begin caching assets in and around collection view's visible rect.
        DispatchQueue.main.async {
            self.updateCachedAssets()
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        }
    }


    // MARK: - Public methods
    open func setAppearanceConfig(_ config: SimpleAssetPickerConfig)  {
        let appearanceConfig = SimpleAssetPickerConfig.sharedConfig()
        appearanceConfig.minMediaSelectionAmount = config.minMediaSelectionAmount
        appearanceConfig.maxMediaSelectionAmount = config.maxMediaSelectionAmount
        appearanceConfig.numberOfItemsPerRow = config.numberOfItemsPerRow
        appearanceConfig.pickerMediaType = config.pickerMediaType
        appearanceConfig.assetSelectedImageName = config.assetSelectedImageName
        appearanceConfig.cellSize = config.cellSize
        appearanceConfig.collectionViewEdgeInsets = config.collectionViewEdgeInsets
        appearanceConfig.verticalCellSpacing = config.verticalCellSpacing
    }

    // MARK: - Photos permissions
    fileprivate func requestPermissions(_ completion: ((_ granted: Bool) -> Void)?) {
        guard let completion = completion else { return }
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            completion(true)
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authStatus) -> Void in
                if authStatus == .authorized {
                    completion(true)
                } else {
                    completion(false)
                }
            })
            break
        default:
            completion(false)
            break
        }
    }

    // MARK: Media selection
    func updateSelectedAssetsWithIndexPaths(_ indexPaths: [IndexPath]) {
        let config = SimpleAssetPickerConfig.sharedConfig()
        if indexPaths.count >= config.minMediaSelectionAmount && indexPaths.count <= config.maxMediaSelectionAmount {
            // print("[SAP DEBUG] Meets requirements \(indexPaths.count)")
            var assets = [PHAsset]()
            for indexPath in indexPaths {
                assets.append(self.assetsFetchResults.object(at: indexPath.item) )
            }
            self.selectedAssets = assets
            if let delegate = self.delegate {
                delegate.didSatisfyMediaRequirements(self, assets: assets)
            }
        } else {
            // print("[SAP DEBUG] Broke selection requirements")
            self.selectedAssets = []
            if let delegate = self.delegate {
                delegate.didBreakMediaRequirements(self)
            }
        }
    }

    // MARK: - Asset Caching
    func resetCachedAssets() {
        imageManager?.stopCachingImagesForAllAssets()
        previousPreheatRect = CGRect.zero
    }

    func updateCachedAssets() {
        if (self.isViewLoaded != true && self.view.window == nil) || self.libraryAccessGranted == false {
            // print("returning before updating cached assets")
            return
        }

        // The preheat window is twice the height of the visible rect.
        var preheatRect = self.collectionView.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)

        /*
         Check if the collection view is showing an area that is significantly
         different to the last preheated area.
         */
        let delta = abs(preheatRect.midY - previousPreheatRect.midY)
        if delta > collectionView.bounds.height / 3.0 {

            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths = [IndexPath]()
            var removedIndexPaths = [IndexPath]()

            computeDifferenceBetweenRect(previousPreheatRect, newRect: preheatRect, removedHandler: { (removedRect) -> Void in
                if let indexPaths = self.indexPathsForElementsInRect(removedRect) {
                    removedIndexPaths.append(contentsOf: indexPaths)
                }
                }, addedHandler: { (addedRect) -> Void in
                    if let indexPaths = self.indexPathsForElementsInRect(addedRect) {
                        addedIndexPaths.append(contentsOf: indexPaths)
                    }
            })

            let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths as NSArray)
            let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths as NSArray)

            // Update the assets the PHCachingImageManager is caching.
            if let assetsToStartCaching = assetsToStartCaching {
                imageManager?.startCachingImages(for: assetsToStartCaching, targetSize: assetGridThumbnailSize, contentMode: .aspectFill, options: nil)
            }

            if let assetsToStopCaching = assetsToStopCaching {
                imageManager?.stopCachingImages(for: assetsToStopCaching, targetSize: assetGridThumbnailSize, contentMode: .aspectFill, options: nil)
            }

            // Store the preheat rect to compare against in the future.
            previousPreheatRect = preheatRect
        }
    }

    func computeDifferenceBetweenRect(_ oldRect: CGRect, newRect: CGRect, removedHandler: ((_ removedRect: CGRect) -> Void)?, addedHandler: ((_ addedRect: CGRect) -> Void)?) {
        print("COMPUTE DIFFERENCE")
        if newRect.intersects(oldRect) {
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minY
            let newMaxY = newRect.maxY
            let newMinY = newRect.minY

            if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: oldMaxY, width: newRect.size.width, height: (newMaxY - oldMaxY))
                if let addedHandler = addedHandler {
                    addedHandler(rectToAdd)
                }
            }

            if oldMinY > newMinY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: (oldMinY - newMinY))
                if let addedHandler = addedHandler {
                    addedHandler(rectToAdd)
                }
            }

            if newMaxY < oldMinY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: (oldMaxY - newMaxY))
                if let removedHandler = removedHandler {
                    removedHandler(rectToRemove)
                }
            }

            if oldMinY < newMinY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: (newMinY - oldMinY))
                if let removedHandler = removedHandler {
                    removedHandler(rectToRemove)
                }
            }
        } else {
            if let addedHandler = addedHandler {
                addedHandler(newRect)
            }
            if let removedHandler = removedHandler {
                removedHandler(oldRect)
            }
        }
    }

    func assetsAtIndexPaths(_ indexPaths: NSArray) -> [PHAsset]? {
        if indexPaths.count == 0 { return nil }

        var assets = [PHAsset]()
        for indexPath in indexPaths {
            let asset = self.assetsFetchResults[(indexPath as AnyObject).item]
            assets.append(asset )
        }

        return assets
    }

    func indexPathsForElementsInRect(_ rect: CGRect) -> [IndexPath]? {
        let allLayoutAttributes = self.collectionView.collectionViewLayout.layoutAttributesForElements(in: rect)
        if allLayoutAttributes?.count == 0 { return nil }
        var indexPaths = [IndexPath]()
        for layoutAttributes in allLayoutAttributes! {
            indexPaths.append(layoutAttributes.indexPath)
        }
        return indexPaths
    }
}

extension SimpleAssetPickerViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else { return true }

        for toDeselect in selectedIndexPaths {
            if toDeselect == indexPath {
                collectionView.deselectItem(at: indexPath, animated: true)
                return false
            }
        }

        return true
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else { return }

        if selectedIndexPaths.count > SimpleAssetPickerConfig.sharedConfig().maxMediaSelectionAmount {
            for toDeselect in selectedIndexPaths {
                if indexPath != toDeselect {
                    collectionView.deselectItem(at: toDeselect, animated: true)
                    break
                }
            }
        }

        updateSelectedAssetsWithIndexPaths(collectionView.indexPathsForSelectedItems ?? [])
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateSelectedAssetsWithIndexPaths(collectionView.indexPathsForSelectedItems ?? [])
    }
}

extension SimpleAssetPickerViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetsFetchResults.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        // Dequeue a AssetCollectionViewCell.
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCollectionCellReuseIdentifier, for: indexPath) as? AssetCollectionViewCell {

            let asset = assetsFetchResults[indexPath.item]
            cell.representedAssetIdentifier = asset.localIdentifier

            // Load icon assets from Bundle.
            if let bundle = self.assetBundle {
                let checkMarkImage = UIImage.imageInBundle(bundle, named: SimpleAssetPickerConfig.sharedConfig().assetSelectedImageName!)
                cell.checkMarkImageView.image = checkMarkImage

                let cameraImage = UIImage.imageInBundle(bundle, named: "camera-icon")
                cell.cameraIconImageView.image = cameraImage
            }

            // Initial cell config.
            cell.livePhotoBadgeImageView.isHidden = true
            cell.cameraIconImageView.isHidden = true
            cell.videoLengthLabel.isHidden = true
            cell.gradientView.isHidden = true

            // Show UI for Video asset.
            if asset.mediaType == .video {
                cell.cameraIconImageView.isHidden = false
                cell.videoLengthLabel.isHidden = false
                cell.gradientView.isHidden = false
                cell.videoLengthLabel.text = cell.getTimeStringOfTimeInterval(asset.duration)
            }

            // Show UI for Live Photo asset.
            if #available(iOS 9.1, *) {
                if asset.mediaSubtypes == PHAssetMediaSubtype.photoLive {
                    let badge = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
                    cell.livePhotoBadgeImageView.image = badge
                    cell.livePhotoBadgeImageView.isHidden = false
                    cell.gradientView.isHidden = false
                }
            } else {
                // Fallback on earlier versions
            }

            // Request an image for the asset from the PHCachingImageManager.
            imageManager?.requestImage(for: asset, targetSize: assetGridThumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { (result, info) -> Void in
                // Set the cell's thumbnail image if it's still showing the same asset.
                if cell.representedAssetIdentifier == asset.localIdentifier {
                    cell.imageView.image = result
                }
            })

            return cell
        }

        return UICollectionViewCell()
    }
}

extension SimpleAssetPickerViewController: PHPhotoLibraryChangeObserver {

    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Check if there are changes to the assets we are showing.
        guard let collectionChanges = changeInstance.changeDetails(for: assetsFetchResults) else { return }

        /*
         Change notifications may be made on a background queue. Re-dispatch to the
         main queue before acting on the change as we'll be updating the UI.
         */
        DispatchQueue.main.async(execute: { () -> Void in
            // Get the new fetch result.
            self.assetsFetchResults = collectionChanges.fetchResultAfterChanges

            //guard let collectionView = self.collectionView else { return }

            if collectionChanges.hasIncrementalChanges == true || collectionChanges.hasMoves == true {
                // Reload the collection view if the incremental diffs are not available
                self.collectionView.reloadData()
            } else {
                /*
                 Tell the collection view to animate insertions and deletions if we
                 have incremental diffs.
                 */
                self.collectionView.performBatchUpdates({ () -> Void in
                    if let removedIndexes = collectionChanges.removedIndexes {
                        if removedIndexes.count > 0 {
                            self.collectionView.deleteItems(at: removedIndexes.indexPathsFromIndexesWithSection(0))
                        }
                    }

                    if let insertedIndexes = collectionChanges.insertedIndexes {
                        if insertedIndexes.count > 0 {
                            self.collectionView.insertItems(at: insertedIndexes.indexPathsFromIndexesWithSection(0))
                        }
                    }

                    if let changedIndexes = collectionChanges.changedIndexes {
                        if changedIndexes.count > 0 {
                            self.collectionView.reloadItems(at: changedIndexes.indexPathsFromIndexesWithSection(0))
                        }
                    }

                    }, completion: nil)
            }

            self.resetCachedAssets()
        })
    }
}
