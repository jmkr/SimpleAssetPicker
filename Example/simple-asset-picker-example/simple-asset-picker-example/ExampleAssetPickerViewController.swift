//
//  ExamplePickerViewController.swift
//  simple-asset-picker-example
//
//  Created by John Meeker on 7/17/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit
import Photos
import SimpleAssetPicker

class ExamplePickerViewController: UIViewController {
    
    @IBOutlet weak var nextButton: UIBarButtonItem!
    var selectedAssets = [PHAsset]()
    var simpleAssetPickerViewController: SimpleAssetPickerViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        hideNextButton()

        self.title = SimpleAssetPickerConfig.sharedConfig().pickerMediaType?.description

        self.simpleAssetPickerViewController = SimpleAssetPickerViewController()
        self.simpleAssetPickerViewController.delegate = self
        self.view.addSubview(self.simpleAssetPickerViewController.view)
        self.simpleAssetPickerViewController.didMove(toParentViewController: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Actions
    @IBAction func handleNextButtonItem(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "showSelectedTableViewController", sender: sender)
    }

    // MARK: - UI
    fileprivate func hideNextButton() {
        nextButton.isEnabled = false
        nextButton.tintColor = .clear
    }

    fileprivate func showNextButton() {
        nextButton.isEnabled = true
        nextButton.tintColor = nil
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSelectedTableViewController" {
            let selectedTableVC = segue.destination as! SelectedTableViewController
            selectedTableVC.selectedAssets = self.selectedAssets
        }
    }
}

extension ExamplePickerViewController: SimpleAssetPickerDelegate {
    func didCancel(_ picker: SimpleAssetPickerViewController) {
        
    }
    func didSatisfyMediaRequirements(_ picker: SimpleAssetPickerViewController, assets: [PHAsset]?) {
        if let assets = assets {
            selectedAssets = assets
        }
        showNextButton()
    }
    func didBreakMediaRequirements(_ picker: SimpleAssetPickerViewController) {
        selectedAssets = []
        hideNextButton()
    }
}
