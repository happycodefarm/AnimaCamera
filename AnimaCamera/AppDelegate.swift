//
//  AppDelegate.swift
//  Video
//
//  Created by guillaume on 13/02/2017.
//  Copyright © 2017 Guillaume Stagnaro. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var secondaryWindow: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        let screenConnectionStatusChangedNotification = NotificationCenter.default
//
//        screenConnectionStatusChangedNotification.addObserver(self, selector:(#selector(ViewController.screenConnectionStatusChanged)), name:NSNotification.Name.UIScreenDidConnect, object:nil)
//
//        screenConnectionStatusChangedNotification.addObserver(self, selector:(#selector(ViewController.screenConnectionStatusChanged)), name:NSNotification.Name.UIScreenDidDisconnect, object:nil)
//
//        //Initial check on how many screens are connected to the device on launch of the application.
//        if (UIScreen.screens.count > 1) {
//            self.screenConnectionStatusChanged()
//        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
//    @objc
//    func screenConnectionStatusChanged () {
//        if (UIScreen.screens.count == 1) {
//            secondaryWindow!.rootViewController = nil
//            
//        }   else {
//            let screens : Array = UIScreen.screens
//            let newScreen : AnyObject! = screens.last
//            
//            secondaryScreenSetup(screen: newScreen as! UIScreen)
//            secondaryWindow!.rootViewController = SecondaryViewController(nibName: "SecondaryViewController", bundle: nil)
//            secondaryWindow!.makeKeyAndVisible()
//        }
//        
//    }
//    
//    //Here we set up the secondary screen.
//    func secondaryScreenSetup (screen : UIScreen) {
//        let newWindow : UIWindow = UIWindow(frame: screen.bounds)
//        newWindow.screen = screen
//        newWindow.isHidden = false
//        
//        secondaryWindow = newWindow
//    }
    
    
}

