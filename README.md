# SimpleAssetPicker

SimpleAssetPicker is a modern Swift library that lets users browse and select media assets from their Photo library. It is built using the Photos framework and is highly customizable to match the theme of your app.

# Installation
```swift
platform :ios, '8.0'
pod 'SimpleAssetPicker'
```

# Using in your project
In any view controller you can start by adding:
```swift
override func viewDidLoad() {
    super.viewDidLoad()

    SimpleAssetPickerConfig.sharedConfig().pickerMediaType = .Video
    SimpleAssetPickerConfig.sharedConfig().maxMediaSelectionAmount = 1

    self.simpleAssetPickerViewController = SimpleAssetPickerViewController()
    self.simpleAssetPickerViewController?.delegate = self
    self.view.addSubview(self.simpleAssetPickerViewController!.view)
}
```

# SimpleAssetPickerDelegate
Use these protocol methods to handle events sent from SimpleAssetPicker:
```swift
func didCancel(picker: SimpleAssetPickerViewController)
func didSatisfyMediaRequirements(picker: SimpleAssetPickerViewController, assets: [PHAsset]?)
func didBreakMediaRequirements(picker: SimpleAssetPickerViewController)
```

