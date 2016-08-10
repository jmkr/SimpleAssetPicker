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

private var AssetCollectionCellReuseIdentifier = "AssetCollectionViewCell"

public protocol SimpleAssetPickerDelegate: class {
    func didCancel(picker: SimpleAssetPickerViewController)
    func didSatisfyMediaRequirements(picker: SimpleAssetPickerViewController, assets: [PHAsset]?)
    func didBreakMediaRequirements(picker: SimpleAssetPickerViewController)
}

public class SimpleAssetPickerViewController: UIViewController {

    // Public vars
    public weak var delegate: SimpleAssetPickerDelegate?
    public lazy var assetsFetchResults: PHFetchResult = {
        let mediaFetchOptions = PHFetchOptions()
        mediaFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if let mediaType = SimpleAssetPickerConfig.sharedConfig().pickerMediaType {
            if mediaType == .Video || mediaType == .Image || mediaType == .Audio {
                mediaFetchOptions.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
            }
        }
        return PHAsset.fetchAssetsWithOptions(mediaFetchOptions)
    }()
    public var selectedAssets = [PHAsset]()

    // Private vars
    private var imageManager: PHCachingImageManager?
    private var libraryAccessGranted: Bool = false
    private var previousPreheatRect: CGRect?
    private var AssetGridThumbnailSize = CGSize()
    private var assetBundle: NSBundle?
    private var collectionView: UICollectionView?
    private var collectionViewLayout: UICollectionViewLayout?
    private var topConstraint: NSLayoutConstraint?

    public convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }

//    public init(mediaType type: SimpleAssetPickerMediaType) {
//        super.init(nibName: nil, bundle: nil)
//    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()

        self.setupCollectionView()

        // Make sure we have access to Photos Library before attempting to load assets.
        requestPermissions { (granted) -> Void in
            if granted == true {
                self.libraryAccessGranted = true
                self.imageManager = PHCachingImageManager()
                self.resetCachedAssets()
                PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
            } else {
                print("no access")
                // self.showNoAccessView()
            }
        }

        let podBundle = NSBundle(forClass: self.classForCoder)
        if let bundleURL = podBundle.URLForResource("SimpleAssetPicker", withExtension: "bundle") {
            if let bundle = NSBundle(URL: bundleURL) {
                self.assetBundle = bundle
            }
        }
    }

    deinit {
        if libraryAccessGranted == true {
            PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
        }
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("viewWillLayoutSubviews")

        if let collectionView = self.collectionView {
            let config = SimpleAssetPickerConfig.sharedConfig()

            // Configure contentInset, scrollIndicatorInset, and flowLayout properties for collectionView.
            if let edgeInsets = config.collectionViewEdgeInsets, let numberOfItemsPerRow = config.numberOfItemsPerRow {
                self.collectionView?.contentInset = edgeInsets
                self.collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

                let screenWidth = UIScreen.mainScreen().bounds.width
                let horizontalSections = numberOfItemsPerRow + 1
                let cellWidth = floor((screenWidth - (CGFloat(horizontalSections) * (edgeInsets.left)) ) / CGFloat(numberOfItemsPerRow))

                if let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
                    flowLayout.minimumLineSpacing = CGFloat(config.verticalCellSpacing ?? 0.0)
                    flowLayout.itemSize = CGSize(width: cellWidth, height: cellWidth)
                }

                AssetGridThumbnailSize = CGSize(width: cellWidth * 2.0, height: cellWidth * 2.0)
            }

            self.topConstraint?.autoRemove()
            if UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation) {
                self.topConstraint = self.collectionView!.autoPinEdgeToSuperviewEdge(.Top, withInset: 44)
            } else {
                self.topConstraint = self.collectionView!.autoPinEdgeToSuperviewEdge(.Top, withInset: 64)
            }
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // Begin caching assets in and around collection view's visible rect.
        dispatch_async(dispatch_get_main_queue()) {
            self.updateCachedAssets()
            if let visibleIndexPaths = self.collectionView?.indexPathsForVisibleItems() {
                self.collectionView?.reloadItemsAtIndexPaths(visibleIndexPaths)
            }
        }
    }

    private func setupCollectionView() {
        print("setupCollectionView")
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionViewLayout = layout

        collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: collectionViewLayout!)
        collectionView!.translatesAutoresizingMaskIntoConstraints = false
        collectionView!.backgroundColor = .whiteColor()
        collectionView!.delegate   = self
        collectionView!.dataSource = self
        collectionView!.registerClass(AssetCollectionViewCell.self, forCellWithReuseIdentifier: AssetCollectionCellReuseIdentifier)
        collectionView!.allowsSelection = true
        collectionView!.allowsMultipleSelection = true
        self.view.addSubview(collectionView!)

        topConstraint = collectionView!.autoPinEdgeToSuperviewEdge(.Top, withInset: 64)
        collectionView!.autoPinEdgeToSuperviewEdge(.Bottom)
        collectionView!.autoPinEdgeToSuperviewEdge(.Right)
        collectionView!.autoPinEdgeToSuperviewEdge(.Left)
    }


    // MARK: - Public methods
    public func setAppearanceConfig(config: SimpleAssetPickerConfig)  {
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
    private func requestPermissions(completion: ((granted: Bool) -> Void)?) {
        guard let completion = completion else { return }
        switch PHPhotoLibrary.authorizationStatus() {
        case .Authorized:
            completion(granted: true)
            break
        case .NotDetermined:
            PHPhotoLibrary.requestAuthorization({ (authStatus) -> Void in
                if authStatus == .Authorized {
                    completion(granted: true)
                } else {
                    completion(granted: false)
                }
            })
            break
        default:
            completion(granted: false)
            break
        }
    }

    // MARK: Media selection
    func updateSelectedAssetsWithIndexPaths(indexPaths: [NSIndexPath]) {
        let config = SimpleAssetPickerConfig.sharedConfig()
        if indexPaths.count >= config.minMediaSelectionAmount && indexPaths.count <= config.maxMediaSelectionAmount {
            print("Meets requirements \(indexPaths.count)")
            var assets = [PHAsset]()
            for indexPath in indexPaths {
                assets.append(self.assetsFetchResults.objectAtIndex(indexPath.item) as! PHAsset)
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
        self.previousPreheatRect = CGRectZero
    }

    func updateCachedAssets() {
        if self.isViewLoaded() != true && self.view.window == nil {
            print("returning before updating cached assets")
            return
        }

        // The preheat window is twice the height of the visible rect.
        var preheatRect = self.collectionView?.bounds ?? CGRectZero
        preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect))

        /*
         Check if the collection view is showing an area that is significantly
         different to the last preheated area.
         */
        let delta = abs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect!))
        if delta > CGRectGetHeight((self.collectionView?.bounds)!) / 3.0 {

            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths = [NSIndexPath]()
            var removedIndexPaths = [NSIndexPath]()

            self.computeDifferenceBetweenRect(self.previousPreheatRect!, newRect: preheatRect, removedHandler: { (removedRect) -> Void in
                if let indexPaths = self.indexPathsForElementsInRect(removedRect) {
                    removedIndexPaths.appendContentsOf(indexPaths)
                }
                }, addedHandler: { (addedRect) -> Void in
                    if let indexPaths = self.indexPathsForElementsInRect(addedRect) {
                        addedIndexPaths.appendContentsOf(indexPaths)
                    }
            })

            let assetsToStartCaching = self.assetsAtIndexPaths(addedIndexPaths)
            let assetsToStopCaching = self.assetsAtIndexPaths(removedIndexPaths)

            // Update the assets the PHCachingImageManager is caching.
            if let assetsToStartCaching = assetsToStartCaching {
                self.imageManager?.startCachingImagesForAssets(assetsToStartCaching, targetSize: self.AssetGridThumbnailSize, contentMode: .AspectFill, options: nil)
            }

            if let assetsToStopCaching = assetsToStopCaching {
                self.imageManager?.stopCachingImagesForAssets(assetsToStopCaching, targetSize: self.AssetGridThumbnailSize, contentMode: .AspectFill, options: nil)
            }

            // Store the preheat rect to compare against in the future.
            self.previousPreheatRect = preheatRect
        }
    }

    func computeDifferenceBetweenRect(oldRect: CGRect, newRect: CGRect, removedHandler: ((removedRect: CGRect) -> Void)?, addedHandler: ((addedRect: CGRect) -> Void)?) {
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY = CGRectGetMaxY(oldRect)
            let oldMinY = CGRectGetMinY(oldRect)
            let newMaxY = CGRectGetMaxY(newRect)
            let newMinY = CGRectGetMinY(newRect)

            if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: oldMaxY, width: newRect.size.width, height: (newMaxY - oldMaxY))
                if let addedHandler = addedHandler {
                    addedHandler(addedRect: rectToAdd)
                }
            }

            if oldMinY > newMinY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: (oldMinY - newMinY))
                if let addedHandler = addedHandler {
                    addedHandler(addedRect: rectToAdd)
                }
            }

            if newMaxY < oldMinY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: (oldMaxY - newMaxY))
                if let removedHandler = removedHandler {
                    removedHandler(removedRect: rectToRemove)
                }
            }

            if oldMinY < newMinY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: (newMinY - oldMinY))
                if let removedHandler = removedHandler {
                    removedHandler(removedRect: rectToRemove)
                }
            }
        } else {
            if let addedHandler = addedHandler {
                addedHandler(addedRect: newRect)
            }
            if let removedHandler = removedHandler {
                removedHandler(removedRect: oldRect)
            }
        }
    }

    func assetsAtIndexPaths(indexPaths: NSArray) -> [PHAsset]? {
        if indexPaths.count == 0 { return nil }

        var assets = [PHAsset]()
        for indexPath in indexPaths {
            let asset = self.assetsFetchResults[indexPath.item]
            assets.append(asset as! PHAsset)
        }

        return assets
    }

    func indexPathsForElementsInRect(rect: CGRect) -> [NSIndexPath]? {
        let allLayoutAttributes = self.collectionView?.collectionViewLayout.layoutAttributesForElementsInRect(rect)
        if allLayoutAttributes?.count == 0 { return nil }
        var indexPaths = [NSIndexPath]()
        for layoutAttributes in allLayoutAttributes! {
            indexPaths.append(layoutAttributes.indexPath)
        }
        return indexPaths
    }
}

extension SimpleAssetPickerViewController: UICollectionViewDelegate {
    public func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems() else { return true }

        for toDeselect in selectedIndexPaths {
            if toDeselect == indexPath {
                collectionView.deselectItemAtIndexPath(indexPath, animated: true)
                return false
            }
        }

        return true
    }

    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems() else { return }

        if selectedIndexPaths.count > SimpleAssetPickerConfig.sharedConfig().maxMediaSelectionAmount {
            for toDeselect in selectedIndexPaths {
                if indexPath != toDeselect {
                    collectionView.deselectItemAtIndexPath(toDeselect, animated: true)
                    break
                }
            }
        }

        self.updateSelectedAssetsWithIndexPaths(collectionView.indexPathsForSelectedItems() ?? [])
    }

    public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        self.updateSelectedAssetsWithIndexPaths(collectionView.indexPathsForSelectedItems() ?? [])
    }
}

extension SimpleAssetPickerViewController: UICollectionViewDataSource {
    // MARK: - UICollectionViewDataSource
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assetsFetchResults.count
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let asset = self.assetsFetchResults[indexPath.item] as? PHAsset else {
            return UICollectionViewCell()
        }

        // Dequeue a AssetCollectionViewCell.
        if let cell = collectionView.dequeueReusableCellWithReuseIdentifier(AssetCollectionCellReuseIdentifier, forIndexPath: indexPath) as? AssetCollectionViewCell {
            cell.representedAssetIdentifier = asset.localIdentifier

            // Load icon assets from Bundle.
            if let bundle = self.assetBundle {
                let checkMarkImage = UIImage.imageInBundle(bundle, named: SimpleAssetPickerConfig.sharedConfig().assetSelectedImageName!)
                cell.checkMarkImageView.image = checkMarkImage

                let cameraImage = UIImage.imageInBundle(bundle, named: "camera-icon")
                cell.cameraIconImageView.image = cameraImage
            }

            // Initial cell config.
            cell.livePhotoBadgeImageView.hidden = true
            cell.cameraIconImageView.hidden = true
            cell.videoLengthLabel.hidden = true
            cell.gradientView.hidden = true

            // Show UI for Video asset.
            if asset.mediaType == .Video {
                cell.cameraIconImageView.hidden = false
                cell.videoLengthLabel.hidden = false
                cell.gradientView.hidden = false
                cell.videoLengthLabel.text = cell.getTimeStringOfTimeInterval(asset.duration)
            }

            // Show UI for Live Photo asset.
            if #available(iOS 9.1, *) {
                if asset.mediaSubtypes == PHAssetMediaSubtype.PhotoLive {
                    let badge = PHLivePhotoView.livePhotoBadgeImageWithOptions(.OverContent)
                    cell.livePhotoBadgeImageView.image = badge
                    cell.livePhotoBadgeImageView.hidden = false
                    cell.gradientView.hidden = false
                }
            } else {
                // Fallback on earlier versions
            }

            // Request an image for the asset from the PHCachingImageManager.
            self.imageManager?.requestImageForAsset(asset, targetSize: self.AssetGridThumbnailSize, contentMode: .AspectFill, options: nil, resultHandler: { (result, info) -> Void in
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

    public func photoLibraryDidChange(changeInstance: PHChange) {
        // Check if there are changes to the assets we are showing.
        guard let collectionChanges = changeInstance.changeDetailsForFetchResult(assetsFetchResults) else { return }

        /*
         Change notifications may be made on a background queue. Re-dispatch to the
         main queue before acting on the change as we'll be updating the UI.
         */
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
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
                            collectionView.deleteItemsAtIndexPaths(removedIndexes.aapl_indexPathsFromIndexesWithSection(0) as! [NSIndexPath])
                        }
                    }

                    if let insertedIndexes = collectionChanges.insertedIndexes {
                        if insertedIndexes.count > 0 {
                            collectionView.insertItemsAtIndexPaths(insertedIndexes.aapl_indexPathsFromIndexesWithSection(0) as! [NSIndexPath])
                        }
                    }

                    if let changedIndexes = collectionChanges.changedIndexes {
                        if changedIndexes.count > 0 {
                            collectionView.reloadItemsAtIndexPaths(changedIndexes.aapl_indexPathsFromIndexesWithSection(0) as! [NSIndexPath])
                        }
                    }

                    }, completion: nil)
            }

            self.resetCachedAssets()
        })
    }
}