//
//  AssetCollectionViewCell.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/27/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit

class AssetCollectionViewCell: UICollectionViewCell {
    
    var representedAssetIdentifier: String = ""
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var livePhotoBadgeImageView: UIImageView!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var cameraIconImageView: UIImageView!
    @IBOutlet weak var videoLengthLabel: UILabel!
    @IBOutlet weak var gradientView: GradientView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.livePhotoBadgeImageView.image = nil
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override var selected: Bool {
        get {
            return super.selected
        }
        set {
            if newValue {
                super.selected = true
                self.imageView.alpha = 0.6

                UIView.animateWithDuration(0.1, delay: 0.0, options: [.CurveEaseIn, .AllowUserInteraction], animations: { () -> Void in
                    self.transform = CGAffineTransformMakeScale(0.98, 0.98)
                    self.checkMarkImageView.alpha = 1.0
                    }, completion: { (finished) -> Void in
                        UIView.animateWithDuration(0.1, delay: 0.0, options: [.CurveEaseOut, .AllowUserInteraction], animations: { () -> Void in
                            self.transform = CGAffineTransformIdentity
                            }, completion:nil)
                })
            } else if newValue == false {
                super.selected = false
                self.imageView.alpha = 1.0

                UIView.animateWithDuration(0.1, delay: 0.0, options: [.CurveEaseIn, .AllowUserInteraction], animations: { () -> Void in
                    //self.transform = CGAffineTransformMakeScale(1.02, 1.02)
                    self.checkMarkImageView.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        UIView.animateWithDuration(0.1, delay: 0.0, options: [.CurveEaseOut, .AllowUserInteraction], animations: { () -> Void in
                            self.transform = CGAffineTransformIdentity
                            }, completion:nil)
                })
                
            }
        }
    }

    func getTimeStringOfTimeInterval(timeInterval: NSTimeInterval) -> String {
        let ti = NSInteger(timeInterval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        if hours > 0 {
            return String(format: "%0.d:%0.d:%0.2d",hours,minutes,seconds)
        } else if minutes > 0 {
            return String(format: "%0.d:%0.2d",minutes,seconds)
        } else {
            return String(format: "0:%0.2d",seconds)
        }
    }
}
