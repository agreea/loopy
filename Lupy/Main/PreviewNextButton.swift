//
//  PreviewNextButton.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/7/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class PreviewNextButton: UIButton {

//    override func drawRect(rect: CGRect) {
//        //set up the width and height variables
//        //for the horizontal stroke
//        let rect1 = CGRect(x: rect.origin.x + 10, y: rect.origin.y + 10, width: rect.width - 20, height: rect.height - 20)
//        //create the path
//        let path = UIBezierPath()
//        let originX = rect.origin.x
//        let originY = rect.origin.y
//        //set the path's line width to the height of the stroke
//        path.lineWidth = 5.0
//        
//        // v1 \-----------\ v2
//        // v6  \           \ v3
//        //     /           /
//        // v5 /-----------/ v4
//        let v1 = CGPoint(
//            x: originX + 0.5,
//            y: originY + 0.5)
//        
//        let v2 = CGPoint(
//            x: originX + rect1.width * 0.7 + 0.5,
//            y: originY + 0.5)
//        
//        let v3 = CGPoint(
//            x: originX + rect1.width * 0.9 + 0.5,
//            y: originY + rect1.height/2 + 0.5)
//        
//        let v4 = CGPoint(
//            x: originX + rect1.width * 0.7 + 0.5,
//            y: originY + rect1.height + 0.5)
//        
//        let v5 = CGPoint(
//            x: originX + 0.5,
//            y: originY + rect1.height + 0.5)
//        
//        let v6 = CGPoint(
//            x: originX + rect1.width * 0.2 + 0.5,
//            y: originY + rect1.height/2 + 0.5)
//
//        // ----------
//        path.moveToPoint(v1)
//        path.addLineToPoint(v2)
//        
//        path.moveToPoint(v2)
//        path.addLineToPoint(v3)
//        
//        path.moveToPoint(v3)
//        path.addLineToPoint(v4)
//        
//        path.moveToPoint(v4)
//        path.addLineToPoint(v5)
//        
//        path.moveToPoint(v5)
//        path.addLineToPoint(v6)
//
//        path.moveToPoint(v6)
//        path.addLineToPoint(v1)
//        
//        UIColor.whiteColor().setStroke()
//        
//        //draw the stroke
//        path.stroke()
//    }
}