//
//  EULAController.swift
//  Lupy
//
//  Created by Agree Ahmed on 5/11/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit

class EULAController: UIViewController {
    var dismissAction: (() -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressClose(sender: AnyObject) {
        // close the eula
        dismissAction?()
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
