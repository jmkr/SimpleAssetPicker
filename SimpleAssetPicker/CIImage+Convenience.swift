//
//  CIImage+Convenience.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/27/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit

extension CIImage {
    public func aapl_jpegRepresentationWithCompressionQuality(_ compressionQuality: CGFloat) -> Data {
        let eaglContext = EAGLContext(api: .openGLES2)
        let ciContext = CIContext(eaglContext: eaglContext!)
        let outputImageRef = ciContext.createCGImage(self, from: self.extent)
        let uiImage = UIImage(cgImage: outputImageRef!, scale: 1.0, orientation: .up)
        let jpegRepresentation = UIImageJPEGRepresentation(uiImage, compressionQuality)
        return jpegRepresentation!
    }
}
