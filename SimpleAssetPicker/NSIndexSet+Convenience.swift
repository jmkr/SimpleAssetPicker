//
//  NSIndexSet+Convenience.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/27/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit

extension NSIndexSet {
    public func aapl_indexPathsFromIndexesWithSection(section: Int) -> NSArray {
        let indexPaths = NSMutableArray()
        self.enumerateIndexesUsingBlock { (idx, stop) -> Void in
            indexPaths.addObject(NSIndexPath(forItem: idx, inSection: section))
        }
        return indexPaths
    }
}

