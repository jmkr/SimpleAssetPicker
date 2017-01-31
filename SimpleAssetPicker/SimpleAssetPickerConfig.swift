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
    case any    = -1
    case image  = 1
    case video  = 2
    case audio  = 3
    
    public var description: String {
        get {
            switch(self) {
            case .any:   return "All media"
            case .image: return "Photos"
            case .video: return "Videos"
            case .audio: return "Audio"
            }
        }
    }
}

open class SimpleAssetPickerConfig: NSObject {
    fileprivate static var instance: SimpleAssetPickerConfig!

    // Asset selection constraints
    open var minMediaSelectionAmount: Int?
    open var maxMediaSelectionAmount: Int?

    // Appearance config variables
    open var numberOfItemsPerRow: Int?
    open var pickerMediaType: SimpleAssetPickerMediaType?
    open var assetSelectedImageName: String?
    open var cellSize: CGSize?
    open var collectionViewEdgeInsets: UIEdgeInsets?
    open var verticalCellSpacing: Float?

    // Shared Instance
    open class func sharedConfig() -> SimpleAssetPickerConfig {
        self.instance = (self.instance ?? SimpleAssetPickerConfig())
        return self.instance
    }

    // Default values
    override init() {
        self.minMediaSelectionAmount = 1
        self.maxMediaSelectionAmount = 3
        self.numberOfItemsPerRow = 3
        self.pickerMediaType = .any
        self.assetSelectedImageName = "thumb-check"
        self.cellSize = CGSize(width: 120.0, height: 120.0)
        self.collectionViewEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        self.verticalCellSpacing = 10.0
    }
}
