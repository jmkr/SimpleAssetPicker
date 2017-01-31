# SimpleAssetPicker

[![Version](https://img.shields.io/github/release/jmkr/SimpleAssetPicker.svg)](https://github.com/jmkr/SimpleAssetPicker/releases)
[![Build Status](https://travis-ci.org/jmkr/SimpleAssetPicker.svg?branch=master)](https://travis-ci.org/jmkr/SimpleAssetPicker) 
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/SimpleAssetPicker.svg)](https://cocoapods.org/pods/SimpleAssetPicker)



SimpleAssetPicker is a modern Swift library that lets users browse and select media assets from their Photo library. It is built using the Photos framework and is highly customizable to match the theme of your app.



![Demo Gif](https://www.meeker.io/assets/sapDemoGif.gif "SimpleAssetPicker Demo Gif")

## Installation
```swift
use_frameworks!
platform :ios, '8.0'
pod 'SimpleAssetPicker'
```

## Using in your project
In any view controller you can start by adding:
```swift
import SimpleAssetPicker

override func viewDidLoad() {
    super.viewDidLoad()

    SimpleAssetPickerConfig.sharedConfig().pickerMediaType = .Video
    SimpleAssetPickerConfig.sharedConfig().maxMediaSelectionAmount = 1

    let simpleAssetPickerViewController = SimpleAssetPickerViewController()
    simpleAssetPickerViewController.delegate = self
    self.view.addSubview(simpleAssetPickerViewController.view)
}
```

## SimpleAssetPickerDelegate
Use these protocol methods to handle events sent from SimpleAssetPicker:
```swift
func didCancel(picker: SimpleAssetPickerViewController)
func didSatisfyMediaRequirements(picker: SimpleAssetPickerViewController, assets: [PHAsset]?)
func didBreakMediaRequirements(picker: SimpleAssetPickerViewController)
```

## Customization
SimpleAssetPickerConfig contains several variables which you can change to modify the behavior and appearance of your asset picker. You can access and modify these variables through the shared instance:
```swift
SimpleAssetPickerConfig.sharedConfig().maxMediaSelectionAmount = 1
```

Some customization options include:
```swift
// Asset selection constraints
public var minMediaSelectionAmount: Int?
public var maxMediaSelectionAmount: Int?

// Appearance config variables
public var numberOfItemsPerRow: Int?
public var pickerMediaType: SimpleAssetPickerMediaType?
public var assetSelectedImageName: String?
public var cellSize: CGSize?
public var collectionViewEdgeInsets: UIEdgeInsets?
public var verticalCellSpacing: Float?
```

## Thank you
Pull requests, comments, and suggestions are always welcome.

Distributed with the MIT license. Enjoy.
