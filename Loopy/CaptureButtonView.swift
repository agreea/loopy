//
//  CaptureButtonView.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/6/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable class CaptureViewButton: UIButton {
    var recordingMode: Bool = false
    override func drawRect(rect: CGRect) {
        let innerRect = CGRect(x: rect.origin.x + 20,
                               y: rect.origin.y + 20,
                               width: rect.width - 40,
                               height: rect.height - 40)
        if !recordingMode {
            renderNormal(innerRect)
        } else {
            renderRecording(innerRect)
        }
        renderStatic(rect)
    }
    
    private func renderNormal(innerRect: CGRect) {
        let innerFill = UIBezierPath(ovalInRect: innerRect)
        UIColor(netHex: 0xFFFFFF, alpha: 0.7).setFill()
        innerFill.fill()
    }
    
    private func renderRecording(innerRect: CGRect) {
        let innerFill = UIBezierPath(ovalInRect: innerRect)
        UIColor(netHex: 0xFF0000, alpha: 1.0).setFill()
        innerFill.fill()
    }
    
    // renders the black outline and white middle, which don't change during recording
    private func renderStatic(rect: CGRect) {
        let middleRect = CGRect(x: rect.origin.x + 16, y: rect.origin.y + 16, width: rect.width - 32, height: rect.height - 32)
        let middleCircle = UIBezierPath(ovalInRect: middleRect)
        middleCircle.lineWidth = CGFloat(16.0)
        UIColor.whiteColor().setStroke()
        middleCircle.stroke()
        let outerRect = CGRect(x: rect.origin.x + 8, y: rect.origin.y + 8, width: rect.width - 16, height: rect.height - 16)
        let outerCircle = UIBezierPath(ovalInRect: outerRect)
        outerCircle.lineWidth = 1.5
        UIColor(netHex: 0x333333, alpha: 1.0).setStroke()
        outerCircle.stroke()
    }
}