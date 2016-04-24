//
//  BottomNavBar.swift
//  Lupy
//
//  Created by Agree Ahmed on 4/21/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit

class BottomNavBar: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    override func layoutSubviews() {
        super.layoutSubviews()
        var cumulativeWidth = CGFloat(0.0)
        let widthPerButton = self.frame.width / 5
        let height = self.frame.height
        for subview in self.subviews {
            if let _ = subview as? UIImageView {
                continue
            }
            let oldOrigin = subview.frame.origin
            let newOrigin = CGPointMake(cumulativeWidth, oldOrigin.y)
            subview.frame = CGRect(origin: newOrigin, size: CGSize(width: widthPerButton, height: height))
            print(subview.frame.width)
            cumulativeWidth += widthPerButton
            subview.setNeedsLayout()
        }
    }
}
