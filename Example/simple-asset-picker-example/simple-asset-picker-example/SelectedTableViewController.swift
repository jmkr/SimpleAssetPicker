//
//  SelectedTableViewController.swift
//  simple-asset-picker-example
//
//  Created by John Meeker on 1/31/17.
//  Copyright © 2017 John Meeker. All rights reserved.
//

import UIKit
import Photos

private var SelectedTableViewCellReuseIdentifier = "SelectedTableViewCell"

class SelectedTableViewController: UITableViewController {

    var selectedAssets: Array<PHAsset>?

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let selectedAssets = selectedAssets {
            return selectedAssets.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SelectedTableViewCellReuseIdentifier, for: indexPath)

        if let selectedAssets = selectedAssets {
            let asset = selectedAssets[indexPath.row]
            cell.textLabel?.text = asset.description
//            cell.imageView.image 
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
