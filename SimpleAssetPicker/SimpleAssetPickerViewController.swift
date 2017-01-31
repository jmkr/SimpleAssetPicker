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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


private var AssetCollectionCellReuseIdentifier = "AssetCollectionViewCell"

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
    fileprivate var previousPreheatRect: CGRect? = CGRect.zero
    fileprivate var AssetGridThumbnailSize = CGSize()
    fileprivate var assetBundle: Bundle?
    fileprivate var collectionView: UICollectionView?
    fileprivate var collectionViewLayout: UICollectionViewLayout?
    fileprivate var topConstraint: NSLayoutConstraint?

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
                DispatchQueue.main.async {
                    self.setupCollectionView()
                }
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

        if self.libraryAccessGranted == false { return }

        if let collectionView = self.collectionView {
            let config = SimpleAssetPickerConfig.sharedConfig()

            // Configure contentInset, scrollIndicatorInset, and flowLayout properties for collectionView.
            if let edgeInsets = config.collectionViewEdgeInsets, let numberOfItemsPerRow = config.numberOfItemsPerRow {
                self.collectionView?.contentInset = edgeInsets
                self.collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

                let screenWidth = UIScreen.main.bounds.width
                let horizontalSections = numberOfItemsPerRow + 1
                let cellWidth = floor((screenWidth - (CGFloat(horizontalSections) * (edgeInsets.left)) ) / CGFloat(numberOfItemsPerRow))

                if let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
                    flowLayout.minimumLineSpacing = CGFloat(config.verticalCellSpacing ?? 0.0)
                    flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
                }

                AssetGridThumbnailSize = CGSize(width: cellWidth * 2.0, height: cellWidth * 2.0)
            }

            self.topConstraint?.autoRemove()
            if UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation) {
                self.topConstraint = self.collectionView!.autoPinEdge(toSuperviewEdge: .top, withInset: 44)
            } else {
                self.topConstraint = self.collectionView!.autoPinEdge(toSuperviewEdge: .top, withInset: 64)
            }
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Begin caching assets in and around collection view's visible rect.
        DispatchQueue.main.async {
            self.updateCachedAssets()
            if let visibleIndexPaths = self.collectionView?.indexPathsForVisibleItems {
                self.collectionView?.reloadItems(at: visibleIndexPaths)
            }
        }
    }

    fileprivate func setupCollectionView() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionViewLayout = layout

        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: collectionViewLayout!)
        collectionView!.translatesAutoresizingMaskIntoConstraints = false
        collectionView!.backgroundColor = .white
        collectionView!.delegate   = self
        collectionView!.dataSource = self
        collectionView!.register(AssetCollectionViewCell.self, forCellWithReuseIdentifier: AssetCollectionCellReuseIdentifier)
        collectionView!.allowsSelection = true
        collectionView!.allowsMultipleSelection = true
        self.view.addSubview(collectionView!)

        topConstraint = collectionView!.autoPinEdge(toSuperviewEdge: .top, withInset: 64)
        collectionView!.autoPinEdge(toSuperviewEdge: .bottom)
        collectionView!.autoPinEdge(toSuperviewEdge: .right)
        collectionView!.autoPinEdge(toSuperviewEdge: .left)
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
            print("Meets requirements \(indexPaths.count)")
            var assets = [PHAsset]()
            for indexPath in indexPaths {
                assets.append(self.assetsFetchResults.object(at: indexPath.item) )
            }
            self.selectedAssets = assets
            if let delegate = self.delegate {
                delegate.didSatisfyMediaRequirements(self, assets: assets)
            }
        } else {
            print("Broke selection requirements")
            self.selectedAssets = []
            if let delegate = self.delegate {
                delegate.didBreakMediaRequirements(self)
            }
        }
    }

    // MARK: UIScrollViewDelegate
//    public func scrollViewDidScroll(scrollView: UIScrollView) {
        // Update cached assets for the new visible area.
//        self.updateCachedAssets()
//    }

    // MARK: - Asset Caching
    func resetCachedAssets() {
        self.imageManager?.stopCachingImagesForAllAssets()
        self.previousPreheatRect = CGRect.zero
    }

    func updateCachedAssets() {
        if (self.isViewLoaded != true && self.view.window == nil) || self.libraryAccessGranted == false {
            print("returning before updating cached assets")
            return
        }

        // The preheat window is twice the height of the visible rect.
        var preheatRect = self.collectionView?.bounds ?? CGRect.zero
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)

        /*
         Check if the collection view is showing an area that is significantly
         different to the last preheated area.
         */
        let delta = abs(preheatRect.midY - self.previousPreheatRect!.midY)
        if delta > (self.collectionView?.bounds)!.height / 3.0 {

            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths = [IndexPath]()
            var removedIndexPaths = [IndexPath]()

            self.computeDifferenceBetweenRect(self.previousPreheatRect!, newRect: preheatRect, removedHandler: { (removedRect) -> Void in
                if let indexPaths = self.indexPathsForElementsInRect(removedRect) {
                    removedIndexPaths.append(contentsOf: indexPaths)
                }
                }, addedHandler: { (addedRect) -> Void in
                    if let indexPaths = self.indexPathsForElementsInRect(addedRect) {
                        addedIndexPaths.append(contentsOf: indexPaths)
                    }
            })

            let assetsToStartCaching = self.assetsAtIndexPaths(addedIndexPaths as NSArray)
            let assetsToStopCaching = self.assetsAtIndexPaths(removedIndexPaths as NSArray)

            // Update the assets the PHCachingImageManager is caching.
            if let assetsToStartCaching = assetsToStartCaching {
                self.imageManager?.startCachingImages(for: assetsToStartCaching, targetSize: self.AssetGridThumbnailSize, contentMode: .aspectFill, options: nil)
            }

            if let assetsToStopCaching = assetsToStopCaching {
                self.imageManager?.stopCachingImages(for: assetsToStopCaching, targetSize: self.AssetGridThumbnailSize, contentMode: .aspectFill, options: nil)
            }

            // Store the preheat rect to compare against in the future.
            self.previousPreheatRect = preheatRect
        }
    }

    func computeDifferenceBetweenRect(_ oldRect: CGRect, newRect: CGRect, removedHandler: ((_ removedRect: CGRect) -> Void)?, addedHandler: ((_ addedRect: CGRect) -> Void)?) {
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
        let allLayoutAttributes = self.collectionView?.collectionViewLayout.layoutAttributesForElements(in: rect)
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

        self.updateSelectedAssetsWithIndexPaths(collectionView.indexPathsForSelectedItems ?? [])
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        self.updateSelectedAssetsWithIndexPaths(collectionView.indexPathsForSelectedItems ?? [])
    }
}

extension SimpleAssetPickerViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assetsFetchResults.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let asset = self.assetsFetchResults[indexPath.item]

        // Dequeue a AssetCollectionViewCell.
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetCollectionCellReuseIdentifier, for: indexPath) as? AssetCollectionViewCell {
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
            self.imageManager?.requestImage(for: asset, targetSize: self.AssetGridThumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { (result, info) -> Void in
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

            guard let collectionView = self.collectionView else { return }

            if collectionChanges.hasIncrementalChanges == true || collectionChanges.hasMoves == true {
                // Reload the collection view if the incremental diffs are not available
                collectionView.reloadData()
            } else {
                /*
                 Tell the collection view to animate insertions and deletions if we
                 have incremental diffs.
                 */
                collectionView.performBatchUpdates({ () -> Void in
                    if let removedIndexes = collectionChanges.removedIndexes {
                        if removedIndexes.count > 0 {
                            collectionView.deleteItems(at: removedIndexes.aapl_indexPathsFromIndexesWithSection(0) as! [IndexPath])
                        }
                    }

                    if let insertedIndexes = collectionChanges.insertedIndexes {
                        if insertedIndexes.count > 0 {
                            collectionView.insertItems(at: insertedIndexes.aapl_indexPathsFromIndexesWithSection(0) as! [IndexPath])
                        }
                    }

                    if let changedIndexes = collectionChanges.changedIndexes {
                        if changedIndexes.count > 0 {
                            collectionView.reloadItems(at: changedIndexes.aapl_indexPathsFromIndexesWithSection(0) as! [IndexPath])
                        }
                    }

                    }, completion: nil)
            }

            self.resetCachedAssets()
        })
    }
}
