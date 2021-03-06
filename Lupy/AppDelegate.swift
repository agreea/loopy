//
//  AppDelegate.swift
//  Loopy
//
//  Created by Agree Ahmed on 3/19/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
// 

/*
Here's the code to update the logo INSTANTLY:
sh iconsmith.sh /Users/agree/ios/Lupy/Lupy/images/keyframe_logo.pdf Lupy
 */

import UIKit
import CoreData
import Contacts
import AVFoundation
import Kingfisher

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let contactStore = CNContactStore()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        print("launching!!!")
        self.window!.makeKeyAndVisible()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryAmbient,
                                          withOptions: .MixWithOthers)
        } catch {
            print("\(error)")
        }
        if getSession() != nil {
            return true
        }
        let cache = KingfisherManager.sharedManager.cache
        cache.maxDiskCacheSize = 25 * 1024 * 1024 // max cache disk space 25mb
        cache.maxCachePeriodInSecond = 60 * 60 * 24 // max cache duration 1 day
        launchLoginSignup()
        return true
    }
    
    func launchLoginSignup() {
        let loginSignup = UIStoryboard(name: "LoginSignup", bundle: nil)
        let landingViewController = loginSignup.instantiateViewControllerWithIdentifier("LoopyLanding") as! LoopyLandingViewController
        self.window!.rootViewController = landingViewController
    }
    
    func launchAddContacts(enterFromSignup: Bool) {
        let contactViewController = AddContactsViewController(nibName: "AddContactsViewController", bundle: nil)
        contactViewController.enterFromSetup = enterFromSignup
        contactViewController.configureUserList(AddContactsViewController.CONFIG_CONTACTS){}
        self.window!.rootViewController = contactViewController
    }
    
    func launchMainExperience() {
        let loginSignup = UIStoryboard(name: "Main", bundle: nil)
        let landingViewController = loginSignup.instantiateViewControllerWithIdentifier("MasterViewController") as! MasterViewController
        self.window!.rootViewController = landingViewController
    }

    func launchFindMyFriends() {
        let loginSignup = UIStoryboard(name: "LoginSignup", bundle: nil)
        let findMyFriendsViewController = loginSignup.instantiateViewControllerWithIdentifier("FindFriendsViewController") as! FindFriendsViewController
        self.window!.rootViewController = findMyFriendsViewController
    }
    
    class func launchEULAFromViewController(vc: UIViewController) {
        let eula = EULAController(nibName: "EULAController", bundle: nil)
        eula.dismissAction = { vc.dismissViewControllerAnimated(true, completion: nil) }
        vc.presentViewController(eula, animated: true, completion: nil)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        dispatch_async(dispatch_queue_create("com.getkeyframe.cache_movie_cleanup", DISPATCH_QUEUE_SERIAL)) {
            let shouldRun = true
            while shouldRun {
                print("calling clean video cache")
                VideoFetcher.cleanVideoCache()
                NSThread.sleepForTimeInterval(300)
            }
        }
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.agreeahmed.Loopy" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Loopy", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                            NSInferMappingModelAutomaticallyOption: true]

            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
//            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
//                abort()
            }
        }
    }
    
    // fetch user data
    func saveUserData(userId: Int, session: String, username: String) -> Bool {
        let managedContext = self.managedObjectContext
        let entity =  NSEntityDescription.entityForName("User_data",
                                                        inManagedObjectContext:managedContext)
        var userData = getUserData()
        if userData == nil {
            userData = NSManagedObject(entity: entity!,
                                           insertIntoManagedObjectContext: managedContext)
        }
        userData!.setValue(username, forKey: "username")
        userData!.setValue(session, forKey: "session")
        userData!.setValue(userId, forKey: "id")
        do {
            try managedContext.save()
            print("Saved user data")
            return true
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        return false
    }

    // CoreDataDelegateMethods
    func getUserId() -> Int? {
        if let userData = getUserData() {
            return userData.valueForKey("id") as? Int
        }
        return nil
    }
    
    func getSession() -> String? {
        if let userData = getUserData() {
            return userData.valueForKey("session") as? String
        }
        return nil
    }
    
    func getUsername() -> String? {
        if let userData = getUserData() {
            return userData.valueForKey("username") as? String
        }
        return nil
    }

    func setPhoneVerified() -> Bool {
        let managedContext = self.managedObjectContext
        if let userData = getUserData() {
            userData.setValue(true, forKey: "verified_phone")
            do {
                try managedContext.save()
                print("Saved user data")
                return true
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
        }
        return false
    }
    
    private func getUserData() -> NSManagedObject? {
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "User_data")
        do {
            let results =
                try managedContext.executeFetchRequest(fetchRequest)
            if let userCredentials = results as? [NSManagedObject],
                let userData = userCredentials.first {
                return userData
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return nil
    }
    
    // returns true if successful
    func logout() -> Bool {
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "User_data")
        do {
            let results =
                try managedContext.executeFetchRequest(fetchRequest)
            if let userCredentials = results as? [NSManagedObject] {
                for credential in userCredentials {
                    managedContext.deleteObject(credential)
                    print("Deleting \(credential)")
                }
                try managedContext.save()
                print("Successfully deleted all user credentials")
                return true
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return false
        }
        return false
    }
    
    func showMessage(message: String) {
        let alertController = UIAlertController(title: "Loopy", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let pushedViewControllers = (self.window?.rootViewController as! UINavigationController).viewControllers
        let presentedViewController = pushedViewControllers[pushedViewControllers.count - 1]
        
        presentedViewController.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func requestForContactsAccess(completionHandler: (accessGranted: Bool) -> Void) {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        
        switch authorizationStatus {
        case .Authorized:
            completionHandler(accessGranted: true)
            
        case .Denied, .NotDetermined:
            self.contactStore.requestAccessForEntityType(CNEntityType.Contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    completionHandler(accessGranted: access)
                }
                else {
                    if authorizationStatus == CNAuthorizationStatus.Denied {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                            self.showMessage(message)
                        })
                    }
                }
            })
            
        default:
            completionHandler(accessGranted: false)
        }
    }
    
    func getAllContacts() -> [CNContact] {
        var contacts = [CNContact]()
        let fetchReq = CNContactFetchRequest(keysToFetch: [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey])
        do {
            try self.contactStore.enumerateContactsWithFetchRequest(fetchReq) { (contact, unsafePointer) in
                contacts.append(contact)
            }
        } catch {
            print("Error fetching results for container")
        }
        return contacts
    }
    
    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.window!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showErrorFromController(title: String, message: String, viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showSettingsAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { action in
            print("default")
            if let url = NSURL(string: UIApplicationOpenSettingsURLString){
                UIApplication.sharedApplication().openURL(url)
            }
        }))
        self.window!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
    }
    
    class func getAppDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
}

