//
//  SimpleAssetPickerConfig.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/27/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import Foundation
import UIKit

public class SimpleAssetPickerConfig: NSObject {
    private static var instance: SimpleAssetPickerConfig!
    
    // Public vars
    var numCellsPerRow: Int?
    var assetSelectedImageName: String?
    var assetDeselectedImageName: String?
    var initialSelectionBtnColor: UIColor?
    var finishedSelectionBtnColor: UIColor?
    var cellSize: CGSize?
    var collectionViewEdgeInsets: UIEdgeInsets?
    var verticalCellSpacing: Float?
    
    // Shared Instance
    public class func sharedConfig() -> SimpleAssetPickerConfig {
        self.instance = (self.instance ?? SimpleAssetPickerConfig())
        return self.instance
    }
    
    override init() {
        self.numCellsPerRow = 3
        self.assetSelectedImageName = "thumb-check.png"
        self.assetDeselectedImageName = "uzysAP_ico_photo_thumb_uncheck"
        self.initialSelectionBtnColor = UIColor.grayColor()
        self.finishedSelectionBtnColor = UIColor.blackColor()
        self.cellSize = CGSize(width: 120.0, height: 120.0)
        self.collectionViewEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.verticalCellSpacing = 10.0
    }
}
