//
//  GradientView.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/9/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit

class GradientView: UIView {
    var recordingMode: Bool = false
    var colors: [UIColor]?
    // TODO: locations support
    // TODO: gradient support
    // TODO: angle support
    // TODO: circular gradient support
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        if colors != nil && colors!.count > 0 {
            print("Drawing gradient")
            renderGradient(rect)
        } else {
            print("no gradient")
        }
    }
    
    private func renderGradient(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let components = colorsToCGFloats()
        let gradient = CGGradientCreateWithColorComponents(colorSpace, components, [0, 1.0], components.count)
        
        let startPoint = CGPoint(x: 0, y: rect.origin.y)
        let endPoint = CGPoint(x: 0, y: rect.origin.y + rect.height)
        print("\(rect.origin.y)")
        print("\(rect.height)")
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, CGGradientDrawingOptions(rawValue: 0))
    }
    
    private func colorsToCGFloats() -> [CGFloat] {
        var floats = [CGFloat]()
        for color in colors! {
            let colorRef = CGColorGetComponents(color.CGColor)
            floats += [colorRef[0], colorRef[1], colorRef[2], colorRef[3]]
        }
        print("\(floats)")
        return floats
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
