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

protocol SimpleAssetPickerDelegate: class {
    func didFinishPickingAssets(picker: SimpleAssetPickerViewController, assets: [PHAsset]?)
    func didCancel(picker: SimpleAssetPickerViewController)
    func didExceedMaxSelectionAmount(picker: SimpleAssetPickerViewController)
    func didSatisfyMediaRequirements(picker: SimpleAssetPickerViewController, assets: [PHAsset]?)
    func didBreakMediaRequirements(picker: SimpleAssetPickerViewController)
}


public class SimpleAssetPickerViewController: AssetCollectionViewController {
    
    // Public vars
    weak var delegate: SimpleAssetPickerDelegate?
    var maxVideoSelectionAmount: Int = 0
    var maxPhotoSelectionAmount: Int = 0
    var maxMediaSelectionAmount: Int = 0
    
    // Private vars
    private var imageManager: PHCachingImageManager?
    private var previousPreheatRect: CGRect?
    private var AssetGridThumbnailSize = CGSize()
    
    
    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    
    // MARK: - Public methods
    public func setAppearanceConfig(config: SimpleAssetPickerConfig)  {
        let appearanceConfig = SimpleAssetPickerConfig.sharedConfig()
        appearanceConfig.assetSelectedImageName = config.assetSelectedImageName
        appearanceConfig.assetDeselectedImageName = config.assetDeselectedImageName
        appearanceConfig.initialSelectionBtnColor = config.initialSelectionBtnColor
        appearanceConfig.finishedSelectionBtnColor = config.finishedSelectionBtnColor
        appearanceConfig.cellSize = config.cellSize
        appearanceConfig.collectionViewEdgeInsets = config.collectionViewEdgeInsets
        appearanceConfig.verticalCellSpacing = config.verticalCellSpacing
    }
}