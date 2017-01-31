//
//  UIImage+SAPAdditions.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/30/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import Foundation

extension UIImage {
    class func imageInBundle(_ podBundle: Bundle, named: String) -> UIImage? {
        if let bundleURL = podBundle.url(forResource: "SimpleAssetPicker", withExtension: "bundle") {
            if let bundle = Bundle(url: bundleURL) {
                let image = UIImage(named: named, in: bundle, compatibleWith: nil)
                return image
            }
        }
        return nil
    }
}
