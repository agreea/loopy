//
//  CustomButton.swift
//  Lupy
//
//  Created by Agree Ahmed on 5/17/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit

@IBDesignable public class CustomButton: UIButton {

    @IBInspectable var borderColor: UIColor = UIColor.clearColor() {
        didSet {
            layer.borderColor = borderColor.CGColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
    }

}
