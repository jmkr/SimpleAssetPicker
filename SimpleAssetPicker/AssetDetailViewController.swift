//
//  AssetDetailViewController.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/27/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

private var AdjustmentFormatIdentifier = "com.example.apple-samplecode.SamplePhotosApp"

@available(iOS 9.1, *)
class AssetDetailViewController: UIViewController, PHPhotoLibraryChangeObserver, PHLivePhotoViewDelegate {
    
    var asset: PHAsset?
    var assetCollection: PHAssetCollection?
    
    @IBOutlet weak var livePhotoView: PHLivePhotoView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet var playButton: UIBarButtonItem!
    @IBOutlet var space: UIBarButtonItem!
    @IBOutlet var trashButton: UIBarButtonItem!
    
    private var playerLayer: AVPlayerLayer?
    private var lastTargetSize: CGSize?
    private var playingHint: Bool?
    
    deinit {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.livePhotoView.delegate = self
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.asset?.mediaType == .Video {
            self.showPlaybackToolbar()
        } else {
            self.showStaticToolbar()
        }
        
        let isEditable = self.asset?.canPerformEditOperation(.Properties) == true || self.asset?.canPerformEditOperation(.Content) == true
        self.editButton.enabled = isEditable
        
        var isTrashable = false
        if self.assetCollection != nil {
            isTrashable = self.assetCollection?.canPerformEditOperation(.RemoveContent) == true
        } else {
            isTrashable = self.asset?.canPerformEditOperation(.Delete) == true
        }
        self.trashButton.enabled = isTrashable
        
        self.updateImage()
        
        self.view.layoutIfNeeded()
    }
    
    //MARK: - View & Toolbar setup methods.
    
    func showLivePhotoView() {
        self.livePhotoView.hidden = false
        self.imageView.hidden = true
    }
    
    func showStaticPhotoView() {
        self.livePhotoView.hidden = true
        self.imageView.hidden = false
    }
    
    func showPlaybackToolbar() {
        self.toolbarItems = [self.playButton, self.space, self.trashButton]
    }
    
    func showStaticToolbar() {
        self.toolbarItems = [self.space, self.trashButton]
    }
    
    func targetSize() -> CGSize {
        let scale = UIScreen.mainScreen().scale
        let targetSize = CGSize(width: CGRectGetWidth(self.imageView.bounds) * scale, height: CGRectGetHeight(self.imageView.bounds) * scale)
        return targetSize
    }
    
    //MARK: - ImageView/LivePhotoView Image Setting methods.
    
    func updateImage() {
        self.lastTargetSize = self.targetSize()
        
        // Check the asset's `mediaSubtypes` to determine if this is a live photo or not.
        if #available(iOS 9.1, *) {
            let assetHasLivePhotoSubType = self.asset?.mediaSubtypes.contains(.PhotoLive) == true
            if assetHasLivePhotoSubType {
                self.updateLiveImage()
            } else {
                self.updateStaticImage()
            }
        } else {
            self.updateStaticImage()
        }
        
    }
    
    @available(iOS 9.1, *)
    func updateLiveImage() {
        let livePhotoOptions = PHLivePhotoRequestOptions()
        livePhotoOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
        livePhotoOptions.networkAccessAllowed = true
        
        let progressHandler:(Double, NSError?, UnsafeMutablePointer<ObjCBool>, [NSObject : AnyObject]?) -> Void = { progress,error,_,_ in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.progressView.progress = Float(progress)
            })
        }
        livePhotoOptions.progressHandler = progressHandler
        
        // Request the live photo for the asset from the default PHImageManager.
        PHImageManager.defaultManager().requestLivePhotoForAsset(self.asset!, targetSize: self.targetSize(), contentMode: .AspectFit, options: livePhotoOptions) { (livePhoto: PHLivePhoto?, info:[NSObject : AnyObject]?) -> Void in
            
            // Hide the progress view now the request has completed.
            self.progressView.hidden = true
            
            // Check if the request was successful.
            if let livePhoto = livePhoto {
                print("Got a live photo")
                
                // Show the PHLivePhotoView and use it to display the requested image.
                self.showLivePhotoView()
                self.livePhotoView.livePhoto = livePhoto
                
                if info![PHImageResultIsDegradedKey]?.boolValue == true && self.playingHint != true {
                    // Playback a short section of the live photo; similar to the Photos share sheet.
                    print("playing hint...")
                    self.playingHint = true
                    self.livePhotoView.startPlaybackWithStyle(.Hint)
                }
                
                self.showPlaybackToolbar()
            }
        }
    }
    
    func updateStaticImage() {
        let options = PHImageRequestOptions()
        options.networkAccessAllowed = true
        
        let progressHandler:(Double, NSError?, UnsafeMutablePointer<ObjCBool>, [NSObject : AnyObject]?) -> Void = { progress,error,_,_ in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.progressView.progress = Float(progress)
            })
        }
        options.progressHandler = progressHandler
        
        PHImageManager.defaultManager().requestImageForAsset(self.asset!, targetSize: self.targetSize(), contentMode: .AspectFit, options: options) { (resultImage:UIImage?,  info:[NSObject : AnyObject]?) -> Void in
            self.progressView.hidden = true
            
            if let resultImage = resultImage {
                self.showStaticPhotoView()
                self.imageView.image = resultImage
            }
        }
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(changeInstance: PHChange) {
        // Call might come on any background queue. Re-dispatch to the main queue to handle it.
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            // Check if there are changes to the asset we're displaying.
            let changeDetails = changeInstance.changeDetailsForObject(self.asset!)
            if let changeDetails = changeDetails {
                
                // Get the updated asset.
                self.asset = changeDetails.objectAfterChanges as? PHAsset
                
                // If the asset's content changed, update the image and stop any video playback.
                if changeDetails.assetContentChanged {
                    self.updateImage()
                    
                    self.playerLayer?.removeFromSuperlayer()
                    self.playerLayer = nil
                }
            }
        }
    }
    
    // MARK: - Target Actions Methods.
    @IBAction func handleEditButtonItem(sender: AnyObject) {
        // Use a UIAlertController to display the editing options to the user.
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alertController.modalPresentationStyle = .Popover
        alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        alertController.popoverPresentationController?.permittedArrowDirections = [.Up]
        
        // Add an action to dismiss the UIAlertController.
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel, handler: nil))
        
        // If PHAsset supports edit operations, allow the user to toggle its favorite status.
        if self.asset?.canPerformEditOperation(PHAssetEditOperation.Properties) == true {
            let favoriteActionTitle = self.asset?.favorite == true ? NSLocalizedString("Unfavorite", comment: "") : NSLocalizedString("Favorite", comment: "")
            alertController.addAction(UIAlertAction(title: favoriteActionTitle, style: .Default, handler: { (UIAlertAction) -> Void in
                //self.toggleFavoriteStyle()
            }))
        }
        
        // Only allow editing if the PHAsset supports edit operations and it is not a Live Photo.
//        if self.asset?.canPerformEditOperation(.Content) == true && self.asset?.mediaSubtypes.contains(.PhotoLive) != true {
//            // Allow filters to be applied if the PHAsset is an image.
//            if self.asset?.mediaType == .Image {
//                alertController.addAction(UIAlertAction(title: NSLocalizedString("Sepia", comment: ""), style: .Default, handler: { (UIAlertAction) -> Void in
//                    // self.applyFilterWithName("CISepiaTone")
//                }))
//                alertController.addAction(UIAlertAction(title: NSLocalizedString("Chrome", comment: ""), style: .Default, handler: { (UIAlertAction) -> Void in
//                    // self.applyFilterWithName("CIPhotoEffectChrome")
//                }))
//            }
//        }
        
        // Add actions to revert any edits that have been made to the PHAsset.
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Revert", comment: ""), style: .Default, handler: { (UIAlertAction) -> Void in
            // self.revertToOriginal()
        }))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func handleTrashButton(sender: AnyObject) {
        let completionHandler:(Bool, NSError?) -> Void = { success, error in
            if success {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.navigationController?.popViewControllerAnimated(true)
                })
            } else {
                print("Error: \(error)")
            }
        }
        
        if self.assetCollection != nil {
            // Remove asset from album
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                let changeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection!)
                changeRequest?.removeAssets([self.asset!])
                }, completionHandler: completionHandler)
        } else {
            // Delete asset from library
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                PHAssetChangeRequest.deleteAssets([self.asset!])
                }, completionHandler: completionHandler)
        }
    }
    
    @IBAction func handlePlayButtonItem(sender: AnyObject) {
        if self.livePhotoView.livePhoto != nil {
            // We're displaying a live photo, begin playing it.
            self.livePhotoView.startPlaybackWithStyle(.Full)
        } else if self.playerLayer != nil {
            // An AVPlayerLayer has already been created for this asset.
            self.playerLayer?.player?.play()
        } else {
            // Enable network access to fetch cloud assets.
            let videoOptions = PHVideoRequestOptions()
            videoOptions.deliveryMode = PHVideoRequestOptionsDeliveryMode.Automatic
            videoOptions.networkAccessAllowed = true
            
            // Request an AVAsset for the PHAsset we're displaying.
            PHImageManager.defaultManager().requestAVAssetForVideo(self.asset!, options: videoOptions, resultHandler: { (asset: AVAsset?, audioMix: AVAudioMix?, info: [NSObject : AnyObject]?) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if self.playerLayer == nil {
                        guard let asset = asset else { return }
                        
                        let viewLayer = self.view.layer
                        
                        // Create an AVPlayerItem for the AVAsset.
                        let playerItem = AVPlayerItem(asset: asset)
                        playerItem.audioMix = audioMix
                        
                        // Create an AVPlayer with the AVPlayerItem.
                        let player = AVPlayer(playerItem: playerItem)
                        
                        // Create an AVPlayerLayer with the AVPlayer.
                        let playerLayer = AVPlayerLayer(player: player)
                        
                        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
                        playerLayer.frame = CGRect(x: 0, y: 0, width: viewLayer.bounds.size.width, height: viewLayer.bounds.size.height)
                        
                        viewLayer.addSublayer(playerLayer)
                        player.play()
                        
                        // Store a reference to the player layer we added to the view.
                        self.playerLayer = playerLayer
                    }
                })
            })
        }
    }
    
    // MARK: - PHLivePhotoViewDelegate Protocol Methods.
    
    @available(iOS 9.1, *)
    func livePhotoView(livePhotoView: PHLivePhotoView, willBeginPlaybackWithStyle playbackStyle: PHLivePhotoViewPlaybackStyle) {
        print("Will Beginning Playback of Live Photo...")
    }
    
    @available(iOS 9.1, *)
    func livePhotoView(livePhotoView: PHLivePhotoView, didEndPlaybackWithStyle playbackStyle: PHLivePhotoViewPlaybackStyle) {
        print("Did End Playback of Live Photo...")
        self.playingHint = false
    }
    
    // MARK: Photo editing methods.
    
    func applyFilterWithName(filterName: String) {
        // Prepare the options to pass when requesting to edit the image.
        let options = PHContentEditingInputRequestOptions()
        let canHandleAdjustmentData:(PHAdjustmentData) -> Bool = { adjustmentData in
            return adjustmentData.formatIdentifier == AdjustmentFormatIdentifier && adjustmentData.formatVersion == "1.0"
        }
        options.canHandleAdjustmentData = canHandleAdjustmentData
        
        self.asset!.requestContentEditingInputWithOptions(options) { (contentEditingInput:PHContentEditingInput?, info:[NSObject : AnyObject]) -> Void in
            // Create a CIImage from the full image representation.
            let url = contentEditingInput?.fullSizeImageURL
            let orientation = contentEditingInput?.fullSizeImageOrientation
            var inputImage = CIImage(contentsOfURL: url!)
            inputImage = inputImage?.imageByApplyingOrientation(orientation!)
            
            // Create the filter to apply.
            let filter = CIFilter(name: filterName)
            filter?.setDefaults()
            filter?.setValue(inputImage, forKey: kCIInputImageKey)
            
            // Apply the filter.
            let outputImage = filter?.outputImage
            
            // Create a PHAdjustmentData object that describes the filter that was applied.
            let adjustmentData = PHAdjustmentData(formatIdentifier: AdjustmentFormatIdentifier, formatVersion: "1.0", data: filterName.dataUsingEncoding(NSUTF8StringEncoding)!)
            
            /*
             Create a PHContentEditingOutput object and write a JPEG representation
             of the filtered object to the renderedContentURL.
             */
            let contentEditingOutput = PHContentEditingOutput(contentEditingInput: contentEditingInput!)
            let jpegData = outputImage?.aapl_jpegRepresentationWithCompressionQuality(0.9)
            jpegData?.writeToURL(contentEditingOutput.renderedContentURL, atomically: true)
            contentEditingOutput.adjustmentData = adjustmentData
            
            // Ask the shared PHPhotoLinrary to perform the changes.
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                let request = PHAssetChangeRequest(forAsset: self.asset!)
                request.contentEditingOutput = contentEditingOutput
                }, completionHandler:{ success, error in
                    if !success {
                        print("Error: \(error)")
                    }
            })
        }
    }
    
    func toggleFavoriteState() {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            let request = PHAssetChangeRequest(forAsset: self.asset!)
            request.favorite = self.asset?.favorite == true ? false : true
            }, completionHandler: { success, error in
                if !success {
                    print("Error: \(error)")
                }
        })
    }
    
    func revertToOriginal() {
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            let request = PHAssetChangeRequest(forAsset: self.asset!)
            request.revertAssetContentToOriginal()
            }, completionHandler: { success, error in
                if !success {
                    print("Error: \(error)")
                }
        })
    }
}
