//
//  LoopyLandingViewController.swift
//  Loopy
//
//  Created by Agree Ahmed on 4/7/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit
import Contacts

class LoopyLandingViewController: UIViewController {
    var contactDictionary = [String: String]()
    var phoneNumbers = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initBackButton()
        initBarColors()
        // Do any additional setup after loading the view.
    }
    
    private func initBackButton() {
        self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: "NavbarBack")
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "NavbarBack")
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
    }
    
    private func initBarColors() {
        let navigationBarAppearace = UINavigationBar.appearance()
        navigationBarAppearace.barTintColor = UIColor(netHex: 0x7F00FF)
        navigationBarAppearace.tintColor = UIColor.whiteColor()
        navigationBarAppearace.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "Arial Rounded MT Bold", size: 20)!]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBarHidden = false
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
