//
//  CancelPreviewButton.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/7/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import Foundation
import UIKit

func DEGREES_TO_RADIANS(degrees: Double) -> CGFloat {
 return CGFloat(M_PI * (degrees) / 180.0)
}

@IBDesignable
class CancelPreviewButton: UIButton {
//    override func drawRect(rect: CGRect) {
//        //set up the width and height variables
//        //for the horizontal stroke
//        let plusHeight: CGFloat = 4.0
//        let rect1 = CGRect(x: rect.origin.x + 10, y: rect.origin.y + 10, width: rect.width - 20, height: rect.height - 20)
//        //create the path
//        let plusPath = UIBezierPath()
//        
//        //set the path's line width to the height of the stroke
//        plusPath.lineWidth = plusHeight
//        
//        //move the initial point of the path
//        //to the start of the horizontal stroke
//        plusPath.moveToPoint(CGPoint(
//            x:rect1.origin.x + 0.5,
//            y:rect1.origin.y + 0.5))
//        
//        //add a point to the path at the end of the stroke
//        plusPath.addLineToPoint(CGPoint(
//            x: rect1.origin.x + rect1.width + 0.5,
//            y: rect1.origin.y + rect1.width + 0.5))
//        
//        //move to the start of the vertical stroke
//        plusPath.moveToPoint(CGPoint(
//            x:rect1.origin.x + rect1.width + 0.5,
//            y:rect1.origin.y + 0.5))
//        
//            //add the end point to the vertical stroke
//        plusPath.addLineToPoint(CGPoint(
//            x:rect1.origin.x + 0.5,
//            y:rect1.origin.y + rect1.height + 0.5))
//
////        plusPath.applyTransform(CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(45)))
//        //set the stroke color
//        UIColor.whiteColor().setStroke()
//        
//        //draw the stroke
//        plusPath.stroke()
//
//    }
}