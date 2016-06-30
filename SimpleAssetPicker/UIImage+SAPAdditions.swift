//
//  UIImage+SAPAdditions.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/30/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import Foundation

extension UIImage {
    class func bundledImage(named: String) -> UIImage? {
        let podBundle = NSBundle(forClass: self.classForCoder())
        if let bundleURL = podBundle.URLForResource("SimpleAssetPicker", withExtension: "bundle") {
            if let bundle = NSBundle(URL: bundleURL) {
                let image = UIImage(named: named, inBundle: bundle, compatibleWithTraitCollection: nil)
                return image
            }
        }
        return nil
    }
}
