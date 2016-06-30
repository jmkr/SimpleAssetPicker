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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.livePhotoBadgeImageView.image = nil
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override var selected: Bool {
        didSet {
            setNeedsDisplay()
            
            if selected {
                self.checkMarkImageView.hidden = false

                print("selected cell \(representedAssetIdentifier)")

                UIView.animateWithDuration(0.1, delay: 0.0, options: [.CurveEaseOut, .AllowUserInteraction], animations: { 
                    self.transform = CGAffineTransformMakeScale(0.97, 0.97)
                    }, completion: { (finished) in
                        UIView.animateWithDuration(0.1, delay: 0.0, options: [.CurveEaseIn, .AllowUserInteraction], animations: {
                            self.transform = CGAffineTransformIdentity
                            }, completion: nil)
                })
                
                
            } else {
                self.checkMarkImageView.hidden = true

                print("deselected cell \(representedAssetIdentifier)")
                
//                UIView.animateWithDuration(0.1, delay: 0.0, options: [.CurveEaseIn, .AllowUserInteraction], animations: {
//                    self.transform = CGAffineTransformMakeScale(1.03, 1.03)
//                    }, completion: { (finished) in
//                        UIView.animateWithDuration(0.1, delay: 0.0, options: [.CurveEaseOut, .AllowUserInteraction], animations: {
//                            self.transform = CGAffineTransformIdentity
//                            }, completion: nil)
//                })
            }
        }
    }
}
