//
//  AppDelegate.swift
//  SnowHub
//
//  Created by Liubov Perova on 10/21/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit
import Stripe
import GooglePlaces
//import FBSDKCoreKit
//import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var dataManager:DataManager = DataManager.sharedInstance
    var uploadsManager:UploadsManager = UploadsManager.sharedInstance

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
          //provide api key for google maps and server URL for data manager
          GMSServices.provideAPIKey("AIzaSyAkuYvAco7GALUTx1T-EG9CAgvgbug5U6U")
          GMSPlacesClient.provideAPIKey("AIzaSyAkuYvAco7GALUTx1T-EG9CAgvgbug5U6U")
          dataManager.urlBase = "https://snohub.com:5002"
          dataManager.socketBase = "wss://snohub.com:5002"
          dataManager.stripePublicKey = "pk_live_5nrDeDcgqmho6OpicmVgWJ4h"
          dataManager.readConfig()

          //provide API key for Stripe payment system
          STPPaymentConfiguration.shared().publishableKey = dataManager.stripePublicKey
          STPPaymentConfiguration.shared().appleMerchantIdentifier = "merchant.snohub.app"
        
         //register for push notifications 
         registerForPushNotifications(application: application)
        
         //FaceBook SDK singleton
         //FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        
         //check login state from stored user preferences in singleton
         dataManager.getUserPreferences()
         print("Data:  \(dataManager.user)")
        
         //init uploadsManager
         uploadsManager.getOnboardingSteps()
        
         //nullify the bage number 
         application.applicationIconBadgeNumber = 0
               
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
        
       // FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    //remote notifications
    func registerForPushNotifications(application: UIApplication) {
        let notificationSettings:UIUserNotificationSettings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != .none {
            application.registerForRemoteNotifications()
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        var token: String = ""
        for i in 0..<deviceToken.count {
            token += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        print("Device Token:", token)
        UserDefaults.standard.set(token, forKey: "APToken") //save token to user defaults
        UserDefaults.standard.synchronize()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register:", error)
    }
    
    //on remote notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
         application.applicationIconBadgeNumber = 0
    }

    //on remote notification when app is not running
    
    //deep and universal links
    //universal
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
      print("Link had been activated")
      return true
    }
    
    //deep linking
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        print("Open from URL: \(url) with query: \(url.query ?? defaultValue)")
        var paramsDictionary:Dictionary<String, Any> = [:]
        if let _ = url.query
        {
          paramsDictionary = splitQuery(query: url.query!)
        }
         if let token = paramsDictionary["token"] as? String {
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let navigationVC:VerificationController = storyboard.instantiateViewController(withIdentifier: "VerificationController") as! VerificationController
            navigationVC.receivedToken = token
            self.window?.rootViewController = navigationVC
            self.window?.makeKeyAndVisible()
            
           return true
        }
        else
        {
            return true
            //let handled:Bool = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
            //return handled
        }
                
        //return true
    }

    func splitQuery(query: String) -> Dictionary<String, Any>
    {
      let paramArray = query.components(separatedBy: "&")
      if(paramArray.count == 0)
      {
        return [:]
      }
      else
      {
        var paramDict:Dictionary<String, Any> = [:]
        for(_, param) in paramArray.enumerated(){
          let key_value = param.components(separatedBy: "=")
          if(key_value[0] != "" && key_value[1] != "")
          {
            paramDict[key_value[0]] = key_value[1]
          }
        }
        return paramDict
      }
    }
    
    //background sessions handlers
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        
    }
    
    
}

