//
//  LoadingCell.swift
//  Lupy
//
//  Created by Agree Ahmed on 4/27/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit

protocol UploadingCellDelegate {
    func retry()
    func cancelUpload()
}

class UploadingCell: UITableViewCell {
    var gl: CAGradientLayer?
    var delegate: UploadingCellDelegate?
    
    var colorPairs = [
        [UIColor(netHex: 0x59F1FF).CGColor, UIColor(netHex: 0x0012BC).CGColor], // 1
        [UIColor(netHex: 0x0012BC).CGColor, UIColor(netHex: 0xF759FF).CGColor], // 2
        [UIColor(netHex: 0xF759FF).CGColor, UIColor(netHex: 0xF6FF59).CGColor], // 3
        [UIColor(netHex: 0xF6FF59).CGColor, UIColor(netHex: 0xEAFF47).CGColor], // 3
        [UIColor(netHex: 0xEAFF47).CGColor, UIColor(netHex: 0xFF5959).CGColor], // 4
        [UIColor(netHex: 0x52DB46).CGColor, UIColor(netHex: 0x59F1FF).CGColor], // 5
    ]
    
    var currentColorPair = 0
    var nextColorPair: Int {
        get {
            if currentColorPair >= colorPairs.count - 1 {
                return 0
            } else {
                return currentColorPair + 1
            }
        }
    }

    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var gestureView: UIImageView!
    
    private var _errorState = false
    var errorState: Bool {
        get {
            return _errorState
        }
        set(newValue) {
            _errorState = newValue
            updateCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        gl = CAGradientLayer()
        gl!.frame = contentView.bounds
        gl!.colors = colorPairs[currentColorPair]
        gl!.locations = [0.0, 1.0]
        gl!.startPoint = CGPoint(x: 0.0, y: 0.0)
        gl!.endPoint = CGPoint(x: 1.0, y: 1.0)
        contentView.layer.insertSublayer(gl!, atIndex: 0)
        contentView.backgroundColor = UIColor.clearColor()
        let retryListener = UITapGestureRecognizer()
        retryListener.numberOfTapsRequired = 1
        retryListener.addTarget(self, action: #selector(UploadingCell.retry))
        gestureView.addGestureRecognizer(retryListener)
        startAnimation()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    private func startAnimation() {
        let fromColors = gl!.colors
        let toColors = colorPairs[nextColorPair]
        let animation = CABasicAnimation(keyPath: "colors")
        gl!.colors = toColors
        animation.fromValue = fromColors
        animation.toValue = toColors
        animation.duration = 0.7
        animation.removedOnCompletion = true
        animation.fillMode = kCAFillModeForwards
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.delegate = self
        gl!.addAnimation(animation, forKey: "animateGradient")
        if currentColorPair > colorPairs.count - 2 {
            currentColorPair = 0
        } else {
            currentColorPair += 1
        }
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        startAnimation()
    }
    
    
    @IBAction func didPressCancel(sender: AnyObject) {
        delegate!.cancelUpload()
    }
    
    func retry() {
        print("Retry press")
        if errorState {
            print("Was in error state, retrying")
            delegate?.retry()
        }
    }
    
    func updateCell(){
        if errorState {
            contentView.backgroundColor = UIColor(netHex: 0xED5B5B)
            label.text = "Tap to retry upload"
            gl!.hidden = true
            cancelButton.hidden = false
        } else {
            gl!.hidden = false
            cancelButton.hidden = true
            contentView.backgroundColor = UIColor.clearColor()
            label.text = "Uploading Loop"
            label!.textColor = UIColor.whiteColor()
            // hide the x button
        }
    }
}
