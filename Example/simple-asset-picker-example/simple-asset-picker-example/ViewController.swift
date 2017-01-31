//
//  ViewController.swift
//  simple-asset-picker-example
//
//  Created by John Meeker on 1/31/17.
//  Copyright © 2017 John Meeker. All rights reserved.
//

import UIKit
import Photos
import SimpleAssetPicker

class ViewController: UIViewController {
    
    @IBOutlet weak var showAllButton: UIButton!
    @IBOutlet weak var showVideosButton: UIButton!
    @IBOutlet weak var showPhotosButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if sender as? UIButton == self.showAllButton {
            SimpleAssetPickerConfig.sharedConfig().pickerMediaType = .any
        } else if sender as? UIButton == self.showVideosButton {
            SimpleAssetPickerConfig.sharedConfig().pickerMediaType = .video
        } else if sender as? UIButton == self.showPhotosButton {
            SimpleAssetPickerConfig.sharedConfig().pickerMediaType = .image
        }

        if segue.destination is SimpleAssetPickerViewController {
            let mediaFetchOptions = PHFetchOptions()
            mediaFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            if let mediaType = SimpleAssetPickerConfig.sharedConfig().pickerMediaType {
                if mediaType == .video || mediaType == .image || mediaType == .audio {
                    mediaFetchOptions.predicate = NSPredicate(format: "mediaType == %d", mediaType.rawValue)
                }
            }

            let fetchedMedia = PHAsset.fetchAssets(with: mediaFetchOptions)
            let simpleAssetVC = segue.destination as! SimpleAssetPickerViewController
            simpleAssetVC.assetsFetchResults = fetchedMedia

        }
    }
}

