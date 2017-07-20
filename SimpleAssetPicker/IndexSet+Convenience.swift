//
//  IndexSet+Convenience.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/27/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit

extension IndexSet {
    public func indexPathsFromIndexesWithSection(_ section: Int) -> [IndexPath] {
        var indexPaths = [IndexPath]()
        for indexPath in self {
            indexPaths.append(IndexPath(item: indexPath, section: section))
        }
        return indexPaths
    }
}

