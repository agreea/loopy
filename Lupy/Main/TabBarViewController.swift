//
//  TabBarViewController.swift
//  Lupy
//
//  Created by Agree Ahmed on 4/22/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import UIKit

class TabBarViewController: UIViewController {
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var discoverButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var alertsButton: UIButton!
    @IBOutlet weak var userButton: UIButton!
    @IBOutlet weak var tabBar: UIView!
    
    enum TabSelection {
        case Home, Me
    }
    
    var _selectedTab = TabSelection.Home
    
    var selectedTab: TabSelection {
        get {
            return _selectedTab
        }
        set(newValue) {
            _selectedTab = newValue
            switch(_selectedTab) {
            case .Home:
                homeButton.setImage(UIImage(named: "HomeIconHL"), forState: .Normal)
                userButton.setImage(UIImage(named: "UserIcon"), forState: .Normal)
                break
            case .Me:
                homeButton.setImage(UIImage(named: "HomeIcon"), forState: .Normal)
                userButton.setImage(UIImage(named: "UserIconHL"), forState: .Normal)
                break
            default:
                homeButton.setImage(UIImage(named: "HomeIconHL"), forState: .Normal)
                userButton.setImage(UIImage(named: "UserIcon"), forState: .Normal)
            }
        }
    }
    var delegate: TabBarDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedTab = .Home
    }

    
    @IBAction func didPressHomeButton(sender: AnyObject) {
        selectedTab = .Home
        delegate?.goToHome()
    }
    
    @IBAction func didPressDiscoverButton(sender: AnyObject) {
        delegate?.goToDiscover()
    }
    
    @IBAction func didPressCameraButton(sender: AnyObject) {
        delegate?.goToCamera()
    }
    
    @IBAction func didPressAlertsButton(sender: AnyObject) {
        delegate?.goToAlerts()
    }
    
    @IBAction func didPressUserButton(sender: AnyObject) {
        selectedTab = .Me
        delegate?.goToUser()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "embed" {
            if let masterVC = segue.destinationViewController as? MasterViewController {
                delegate = masterVC
                masterVC.cameraDelegate = self
//                masterViewController = masterVC
            }
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

extension TabBarViewController: CameraNavDelegate {
    func cameraDidEnter() {
        // hide the nav bar
        tabBar.hidden = true
    }
    
    func cameraDidExit() {
        // show the nav bar
        tabBar.hidden = false
    }
}
