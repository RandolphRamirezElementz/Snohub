//
//  SplashView.swift
//  SnowHub
//
//  Created by Liubov Perova on 10/21/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit


class SplashView: UIViewController {

    @IBOutlet weak var loginButton : BorderedButton!
    @IBOutlet weak var signUpButton : UIButton!
    
    @IBAction func loginAction(sender: UIButton) {
       //self.performSegue(withIdentifier: "GoToMap", sender:self)
    }
    
    var registration_info: Dictionary<String, Any> = [:]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dataManager = DataManager.sharedInstance
        
        // Do any additional setup after loading the view.
        print("User visible from splashView: \(dataManager.user)")
        if(dataManager.user.SID != "" ){
            checkSession()
        }
        else //no session
        {
            //SID is still null but if we're in process of onboarding, then there's temporary session for unaccepted user
            if(dataManager.user.SIDunaccepted != "")
            {
               checkSessionOnBoarding()
            }
              else
            {
                self.signUpButton.isHidden = false
                self.loginButton.isHidden = false
                self.signUpButton.isEnabled = true
                self.loginButton.isEnabled = true
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToRegistrationProcess" {
            if let destination = segue.destination as? OnboardingSummary {
                destination.registration_info = self.registration_info
            }
        }

    
    }
    
    //check if sessiou valid
    func checkSession()
    {
        //check if our session is valid and if it is - go get drivers, and if not then go to login
        print("checkSession from customer!")
        
        let dataManager = DataManager.sharedInstance
        dataManager.checkSession(completionCallback: {(success, message) in
            if(success)
            { //session is valid
                print("session is valid")
                DispatchQueue.main.async(execute: {
                    
                    if(dataManager.user.isDriver)
                    {
                        self.performSegue(withIdentifier: "goToDriverMap", sender: self)
                    }
                    else{
                        self.performSegue(withIdentifier: "GoToMap", sender: self)
                    }

                })
                
            }
            else //session is invalid or interned connection is gone
            {
                dataManager.LogOut()
                print("Session is invalid: \(message)")
                
                DispatchQueue.main.async(execute: {
                    self.signUpButton.isHidden = false
                    self.loginButton.isHidden = false
                    self.signUpButton.isEnabled = true
                    self.loginButton.isEnabled = true
                })
                
            }
        })
        //---check session end
    }
    
    //check if session valid
    func checkSessionOnBoarding()
    {
        //check if our session is valid and if it is - go get drivers, and if not then go to login
        print("checkSession from customer!")
        
        let dataManager = DataManager.sharedInstance
        dataManager.checkSessionOnBoarding(completionCallback: {(success, message, steps_info) in
            if(success)
            { //session is valid
                print("session is valid")
                DispatchQueue.main.async(execute: {
                    
                    if(dataManager.user.SID == "")
                    {
                      self.registration_info = steps_info
                      self.performSegue(withIdentifier: "goToRegistrationProcess", sender: self)
                    }
                    else
                    {
                      //self.performSegue(withIdentifier: "goToDriverMap", sender: self)
                        self.checkSession()
                    }
               
                })
                
            }
            else //session is invalid or interned connection is gone
            {
                dataManager.LogOut()
                print("Session is invalid: \(message)")
                
                DispatchQueue.main.async(execute: {
                    self.signUpButton.isHidden = false
                    self.loginButton.isHidden = false
                    self.signUpButton.isEnabled = true
                    self.loginButton.isEnabled = true
                })
                
            }
        })
        //---check session end
    }


}
