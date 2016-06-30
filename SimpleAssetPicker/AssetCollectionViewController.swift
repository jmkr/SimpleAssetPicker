//
//  AssetCollectionViewController.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/27/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//


import UIKit
import Photos
import PhotosUI

private var CellReuseIdentifier = "AssetCollectionViewCell"

public class AssetCollectionViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {
    
    public var assetsFetchResults: PHFetchResult = PHFetchResult()
    var assetCollection: PHAssetCollection = PHAssetCollection()
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    
    private var imageManager: PHCachingImageManager?
    private var previousPreheatRect: CGRect?
    private var assetBundle: NSBundle?
    
    private var AssetGridThumbnailSize = CGSize()
    
    override public func awakeFromNib() {
        self.imageManager = PHCachingImageManager()
        self.resetCachedAssets()
        self.collectionView?.allowsSelection = true

        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)

        let podBundle = NSBundle(forClass: self.classForCoder)
        if let bundleURL = podBundle.URLForResource("SimpleAssetPicker", withExtension: "bundle") {
            if let bundle = NSBundle(URL: bundleURL) {
                self.assetBundle = bundle
            }
        }
    }
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = SimpleAssetPickerConfig.sharedConfig()

        // Determine the size of the thumbnails to request from the PHCachingImageManager
        if let edgeInsets = config.collectionViewEdgeInsets {
            self.collectionView?.contentInset = edgeInsets
            
            if let numCellsPerRow = config.numCellsPerRow {
                let screenWidth = UIScreen.mainScreen().bounds.width
                let horizSections = numCellsPerRow + 1
                let cellWidth = floor((screenWidth - (CGFloat(horizSections) * (edgeInsets.left)) ) / CGFloat(numCellsPerRow))
                print("Cell Width \(cellWidth)")
                print("Screen width \(screenWidth)")

                if let flowLayout = self.collectionViewLayout as? UICollectionViewFlowLayout {
                    flowLayout.minimumLineSpacing = CGFloat(config.verticalCellSpacing ?? 0.0)
                    let cellSize = CGSize(width: cellWidth, height: cellWidth)
                    flowLayout.itemSize = cellSize

                    let scale = UIScreen.mainScreen().scale
                    AssetGridThumbnailSize = CGSize(width: cellSize.width * 2.0, height: cellSize.height * 2.0)
                }
            }
        }
        
        // Add button to the navigation bar if the asset collection supports adding content.
        if self.assetCollection.canPerformEditOperation(.AddContent) == true {
            self.navigationItem.rightBarButtonItem = self.addButton;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Begin caching assets in and around collection view's visible rect.
        self.updateCachedAssets()
    }
    
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Configure the destination AssetViewController.
        if #available(iOS 9.1, *) {
            if segue.destinationViewController.isKindOfClass(AssetDetailViewController.classForCoder()) {
                let assetViewController = segue.destinationViewController as! AssetDetailViewController
                if let cell = sender as? UICollectionViewCell {
                    guard let indexPath = self.collectionView?.indexPathForCell(cell) else { return }
                    if let asset = self.assetsFetchResults[indexPath.item] as? PHAsset {
                        assetViewController.asset = asset
                        assetViewController.assetCollection = self.assetCollection
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    
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
    
    // MARK: - UICollectionViewDataSource
    
    override public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.assetsFetchResults.count
    }
    
    override public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let asset = self.assetsFetchResults[indexPath.item] as? PHAsset else {
            return UICollectionViewCell()
        }
        
        // Dequeue a GridViewCell.
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellReuseIdentifier, forIndexPath: indexPath) as? AssetCollectionViewCell
        cell?.representedAssetIdentifier = asset.localIdentifier
        
        // Add a badge to the cell if the PHAsset represents a Live Photo.
        if #available(iOS 9.1, *) {
            if asset.mediaSubtypes == PHAssetMediaSubtype.PhotoLive {
                let badge = PHLivePhotoView.livePhotoBadgeImageWithOptions(.OverContent)
                cell?.livePhotoBadgeImageView.image = badge
            }
        } else {
            // Fallback on earlier versions
        }
        
        // Request an image for the asset from the PHCachingImageManager.
        self.imageManager?.requestImageForAsset(asset, targetSize: self.AssetGridThumbnailSize, contentMode: .AspectFill, options: nil, resultHandler: { (result, info) -> Void in
            // Set the cell's thumbnail image if it's still showing the same asset.
            if cell?.representedAssetIdentifier == asset.localIdentifier {
                cell?.imageView.image = result
            }
        })

        if let bundle = self.assetBundle {
            let image = UIImage(named: SimpleAssetPickerConfig.sharedConfig().assetSelectedImageName!, inBundle: bundle, compatibleWithTraitCollection: nil)
            cell?.checkMarkImageView.image = image
        }

        return cell!
    }

//    override public func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
//        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems() else { return true }
//        for toDeselect in selectedIndexPaths {
//            if toDeselect == indexPath {
//                print("already selected???")
//                collectionView.deselectItemAtIndexPath(indexPath, animated: true)
////                return false
//            }
//        }
//        return true
//    }

    override public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems() else { return }
        
        
//        print("selectedIndexPaths \(selectedIndexPaths)")
        
        for toDeselect in selectedIndexPaths {
            print("toDeselect \(toDeselect)")
            if indexPath != toDeselect {
                
                print("deselecting \(toDeselect.row)")
                collectionView.deselectItemAtIndexPath(toDeselect, animated: true)
            }
        }
    }

    override public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        print("didDeselect \(indexPath.row)")
//        collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
    }

    // MARK: UIScrollViewDelegate
    
    override public func scrollViewDidScroll(scrollView: UIScrollView) {
        // Update cached assets for the new visible area.
        self.updateCachedAssets()
    }
    
    // MARK: - Asset Caching
    
    func resetCachedAssets() {
        self.imageManager?.stopCachingImagesForAllAssets()
        self.previousPreheatRect = CGRectZero
    }
    
    func updateCachedAssets() {
        if self.isViewLoaded() != true && self.view.window == nil {
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
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElementsInRect(rect)
        if allLayoutAttributes?.count == 0 { return nil }
        var indexPaths = [NSIndexPath]()
        for layoutAttributes in allLayoutAttributes! {
            indexPaths.append(layoutAttributes.indexPath)
        }
        return indexPaths
    }
    
    // MARK: - Actions
    
    @IBAction func handleAddButtonItem(sender: AnyObject) {
        // Create a random dummy image.
        let rect = rand() % 2 == 0 ? CGRect(x: 0, y: 0, width: 400, height: 300) : CGRect(x: 0, y: 0, width: 300, height: 400)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 1.0)
        UIColor(hue: CGFloat((rand() % 100) / 100), saturation: 1.0, brightness: 1.0, alpha: 1.0).setFill()
        UIRectFillUsingBlendMode(rect, CGBlendMode.Normal)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Add it to the photo library
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
            
            let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection)
            assetCollectionChangeRequest?.addAssets([assetChangeRequest.placeholderForCreatedAsset!])
        }) { (success, error) -> Void in
            if success == false {
                print("Error creation asset: \(error)")
            }
        }
    }
    
}