//
//  NSIndexSet+Convenience.swift
//  SimpleAssetPicker
//
//  Created by John Meeker on 6/27/16.
//  Copyright © 2016 John Meeker. All rights reserved.
//

import UIKit

extension IndexSet {
    public func aapl_indexPathsFromIndexesWithSection(_ section: Int) -> NSArray {
        let indexPaths = NSMutableArray()
        (self as NSIndexSet).enumerate({ (idx, stop) -> Void in
            indexPaths.add(IndexPath(item: idx, section: section))
        })
        return indexPaths
    }
}

