//
//  AppDelegate.swift
//  TurnBasedTest
//
//  Created by Markos Hatzitaskos on 349/12/15.
//  Copyright © 2015 Markos Hatzitaskos. All rights reserved.
//

import UIKit

enum Device: String {
    case iPhone4 = "iPhone4", iPhone5 = "iPhone5" , iPhone6 = "iPhone6",  iPhone6Plus = "iPhone6Plus", iPad = "iPad"
}

let appDelegate = UIApplication.shared.delegate as! AppDelegate
var currentDevice : Device!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let model = UIDevice.current.model
        if model.hasPrefix("iPad") {
            
            currentDevice = Device.iPad
            
        } else if model.hasPrefix("iPhone"){
            
            let height = UIScreen.main.bounds.height

            switch height {
            case 480:
                currentDevice = Device.iPhone4
            case 568:
                currentDevice = Device.iPhone5
            case 667:
                currentDevice = Device.iPhone6
            case 736:
                currentDevice = Device.iPhone6Plus
            default:
                currentDevice = Device.iPhone5
                
            }
            
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

