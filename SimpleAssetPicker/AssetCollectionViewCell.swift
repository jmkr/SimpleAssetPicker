//
//  AssetCollectionViewCell.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/27/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit
import PureLayout

class AssetCollectionViewCell: UICollectionViewCell {
    
    var representedAssetIdentifier: String = ""
    private var didSetupConstraints: Bool = false

    lazy var imageView: UIImageView! = {
        let imageView = UIImageView.newAutoLayoutView()
        imageView.contentMode = .ScaleAspectFill
        return imageView
    }()

    lazy var gradientView: GradientView! = {
        return GradientView.newAutoLayoutView()
    }()

    lazy var checkMarkImageView: UIImageView! = {
        let imageView = UIImageView.newAutoLayoutView()
        imageView.alpha = 0.0
        return imageView
    }()

    lazy var livePhotoBadgeImageView: UIImageView! = {
       return UIImageView.newAutoLayoutView()
    }()

    lazy var cameraIconImageView: UIImageView! = {
        return UIImageView.newAutoLayoutView()
    }()
    
    lazy var videoLengthLabel: UILabel! = {
        let label = UILabel.newAutoLayoutView()
        label.textColor = .whiteColor()
        label.font = UIFont.systemFontOfSize(13.0)
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.livePhotoBadgeImageView.image = nil
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        updateConstraints()
    }

    private func setupViews() {
        self.clipsToBounds = true
        self.backgroundColor = .whiteColor()
        self.addSubview(self.imageView)
        self.addSubview(self.gradientView)
        self.addSubview(self.checkMarkImageView)
        self.addSubview(self.livePhotoBadgeImageView)
        self.addSubview(self.cameraIconImageView)
        self.addSubview(self.videoLengthLabel)
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

    override func updateConstraints() {
        if !didSetupConstraints {
            self.imageView.autoPinEdgesToSuperviewEdges()

            self.gradientView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: .Top)
            self.gradientView.autoSetDimension(.Height, toSize: 30)

            self.checkMarkImageView.autoPinEdgeToSuperviewEdge(.Top, withInset: 4)
            self.checkMarkImageView.autoPinEdgeToSuperviewEdge(.Right, withInset: 4)
            self.checkMarkImageView.autoSetDimensionsToSize(CGSize(width: 18, height: 18))

            self.livePhotoBadgeImageView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 4)
            self.livePhotoBadgeImageView.autoPinEdgeToSuperviewEdge(.Left, withInset: 4)
            self.livePhotoBadgeImageView.autoSetDimensionsToSize(CGSize(width: 20, height: 20))

            self.cameraIconImageView.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 4)
            self.cameraIconImageView.autoPinEdgeToSuperviewEdge(.Left, withInset: 4)
            self.cameraIconImageView.autoSetDimensionsToSize(CGSize(width: 20, height: 17))

            self.videoLengthLabel.autoPinEdgeToSuperviewEdge(.Bottom, withInset: 4)
            self.videoLengthLabel.autoPinEdgeToSuperviewEdge(.Right, withInset: 4)

            didSetupConstraints = true
        }

        super.updateConstraints()
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
