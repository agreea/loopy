//
//  RoundedButton.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/10/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit

class RoundedButton: UIButton {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    */
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        self.layer.cornerRadius = CGFloat(6.0)
        self.clipsToBounds = true
    }
}
