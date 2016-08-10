//
//  GradientView.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 7/4/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit

class GradientView: UIView {
    
    //1 - the properties for the gradient
    var startColor: UIColor = UIColor.blackColor()
    var endColor: UIColor = UIColor.clearColor()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    private func commonInit() {
        self.backgroundColor = .clearColor()
    }

    override func drawRect(rect: CGRect) {

        //2 - get the current context
        let context = UIGraphicsGetCurrentContext()

        //3 - set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        //4 - set up the color stops
        let colors = [startColor.CGColor, endColor.CGColor]
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
