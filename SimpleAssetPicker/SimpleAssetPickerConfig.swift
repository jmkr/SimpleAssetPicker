//
//  SimpleAssetPickerConfig.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/27/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import Foundation
import UIKit

public enum SimpleAssetPickerMediaType: Int {
    case Any    = -1
    case Image  = 1
    case Video  = 2
    case Audio  = 3
}

public class SimpleAssetPickerConfig: NSObject {
    private static var instance: SimpleAssetPickerConfig!

    // Asset selection constraints
    var maxVideoSelectionAmount: Int?
    var maxPhotoSelectionAmount: Int?
    var maxMediaSelectionAmount: Int?

    // Appearance config variables
    var numberOfItemsPerRow: Int?
    public var pickerMediaType: SimpleAssetPickerMediaType?
    var assetSelectedImageName: String?
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

    // Default values
    override init() {
        self.maxVideoSelectionAmount = 0
        self.maxPhotoSelectionAmount = 3
        self.maxMediaSelectionAmount = 3
        self.numberOfItemsPerRow = 3
        self.pickerMediaType = .Any
        self.assetSelectedImageName = "thumb-check"
        self.initialSelectionBtnColor = UIColor.grayColor()
        self.finishedSelectionBtnColor = UIColor.blackColor()
        self.cellSize = CGSize(width: 120.0, height: 120.0)
        self.collectionViewEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.verticalCellSpacing = 10.0
    }
}
