//
//  Extensions.swift
//  AugmentedPhoneBook
//
//  Created by Stephen Heaps on 2017-08-01.
//  Copyright © 2017 Stephen Heaps. All rights reserved.
//

import Foundation
import UIKit

extension Double {
    func randomInRange(start: Double, end: Double) -> Double {
        return Double(arc4random_uniform(UInt32(end))) + start
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 1.0)
    }
}
