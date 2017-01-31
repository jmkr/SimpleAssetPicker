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
    fileprivate var didSetupConstraints: Bool = false

    lazy var imageView: UIImageView! = {
        let imageView = UIImageView.newAutoLayout()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    lazy var gradientView: GradientView! = {
        return GradientView.newAutoLayout()
    }()

    lazy var checkMarkImageView: UIImageView! = {
        let imageView = UIImageView.newAutoLayout()
        imageView.alpha = 0.0
        return imageView
    }()

    lazy var livePhotoBadgeImageView: UIImageView! = {
       return UIImageView.newAutoLayout()
    }()

    lazy var cameraIconImageView: UIImageView! = {
        return UIImageView.newAutoLayout()
    }()
    
    lazy var videoLengthLabel: UILabel! = {
        let label = UILabel.newAutoLayout()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13.0)
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

    fileprivate func setupViews() {
        self.clipsToBounds = true
        self.backgroundColor = .white
        self.addSubview(self.imageView)
        self.addSubview(self.gradientView)
        self.addSubview(self.checkMarkImageView)
        self.addSubview(self.livePhotoBadgeImageView)
        self.addSubview(self.cameraIconImageView)
        self.addSubview(self.videoLengthLabel)
    }

    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set {
            if newValue {
                super.isSelected = true
                self.imageView.alpha = 0.6

                UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseIn, .allowUserInteraction], animations: { () -> Void in
                    self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
                    self.checkMarkImageView.alpha = 1.0
                    }, completion: { (finished) -> Void in
                        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: { () -> Void in
                            self.transform = CGAffineTransform.identity
                            }, completion:nil)
                })
            } else if newValue == false {
                super.isSelected = false
                self.imageView.alpha = 1.0

                UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseIn, .allowUserInteraction], animations: { () -> Void in
                    //self.transform = CGAffineTransformMakeScale(1.02, 1.02)
                    self.checkMarkImageView.alpha = 0.0
                    }, completion: { (finished) -> Void in
                        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: { () -> Void in
                            self.transform = CGAffineTransform.identity
                            }, completion:nil)
                })
                
            }
        }
    }

    override func updateConstraints() {
        if !didSetupConstraints {
            self.imageView.autoPinEdgesToSuperviewEdges()

            self.gradientView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
            self.gradientView.autoSetDimension(.height, toSize: 30)

            self.checkMarkImageView.autoPinEdge(toSuperviewEdge: .top, withInset: 4)
            self.checkMarkImageView.autoPinEdge(toSuperviewEdge: .right, withInset: 4)
            self.checkMarkImageView.autoSetDimensions(to: CGSize(width: 18, height: 18))

            self.livePhotoBadgeImageView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 4)
            self.livePhotoBadgeImageView.autoPinEdge(toSuperviewEdge: .left, withInset: 4)
            self.livePhotoBadgeImageView.autoSetDimensions(to: CGSize(width: 20, height: 20))

            self.cameraIconImageView.autoPinEdge(toSuperviewEdge: .bottom, withInset: 4)
            self.cameraIconImageView.autoPinEdge(toSuperviewEdge: .left, withInset: 4)
            self.cameraIconImageView.autoSetDimensions(to: CGSize(width: 20, height: 17))

            self.videoLengthLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 4)
            self.videoLengthLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 4)

            didSetupConstraints = true
        }

        super.updateConstraints()
    }

    func getTimeStringOfTimeInterval(_ timeInterval: TimeInterval) -> String {
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
