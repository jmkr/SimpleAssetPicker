//
//  GradientView.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 7/4/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit

@IBDesignable class GradientView: UIView {
    
    //1 - the properties for the gradient
    @IBInspectable var startColor: UIColor = UIColor.blackColor()
    @IBInspectable var endColor: UIColor = UIColor.clearColor()
    
    override func drawRect(rect: CGRect) {
        
        //2 - get the current context
        let context = UIGraphicsGetCurrentContext()
        let colors = [startColor.CGColor, endColor.CGColor]
        
        //3 - set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //4 - set up the color stops
        let colorLocations:[CGFloat] = [0.0, 0.9]
        
        //5 - create the gradient
        let gradient = CGGradientCreateWithColors(colorSpace,
                                                  colors,
                                                  colorLocations)
        
        //6 - draw the gradient
        let startPoint = CGPoint(x:0, y:self.bounds.height)
        let endPoint = CGPoint(x:0, y:2)
        CGContextDrawLinearGradient(context,
                                    gradient,
                                    startPoint,
                                    endPoint,
                                    CGGradientDrawingOptions(rawValue: 0))
    }
}
