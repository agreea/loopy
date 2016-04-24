//
//  TimerBarView.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/7/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class TimerBarView: UIImageView {
    override func drawRect(rect: CGRect) {
        let rectPath = UIBezierPath(rect: rect)
        UIColor(netHex: 0xFF0000, alpha: 1.0).setFill()
        rectPath.fill()
    }
}