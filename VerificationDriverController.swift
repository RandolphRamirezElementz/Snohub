//
//  VerificationDriverController.swift
//  SnowHub
//
//  Created by Liubov Perova on 4/24/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit

class VerificationDriverController: VerificationRegisterController {

    private struct Constants {
        static let InvisibleSign = "\u{200B}"
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction override func goNext()
    {
        dataManager.checkCode = verificationText1.text!.replacingOccurrences(of: Constants.InvisibleSign, with: "") +
            verificationText2.text!.replacingOccurrences(of: Constants.InvisibleSign, with: "") +
            verificationText3.text!.replacingOccurrences(of: Constants.InvisibleSign, with: "") +
            verificationText4.text!.replacingOccurrences(of: Constants.InvisibleSign, with: "")
        if(dataManager.checkCode.characters.count < 4)
        {
            let alert = UIAlertController(title: "Error", message: "Verification code should be no less than 4 characters long", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            //DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
            //})
        }
        else
        {
            
            self.nextButton.isEnabled = false
            self.nextItem.isEnabled = false
            dataManager.registerCheckCodeDriver(code:dataManager.checkCode, completionCallback: {(success, message) in
                
                
                self.nextButton.isEnabled = true
                self.nextItem.isEnabled = true
                
                if(success)
                {
                    self.dataManager.setUserPreferences()
                    if(self.dataManager.user.SIDunaccepted != "" && self.dataManager.user.number != "")
                    {
                       
                        DispatchQueue.main.async(execute: {
                            //go to first step if there's no SID and no other steps
                            if(self.dataManager.user.SID != "")
                            {
                              self.checkSession()
                            }
                            else
                            {
                                if( self.numberOfStepsFinished() == 0)
                                {
                                    self.performSegue(withIdentifier: "goToSummaryFromCode", sender:self)
                                    //self.performSegue(withIdentifier: "goToStep1", sender:self)
                                }
                                else
                                {
                                    self.performSegue(withIdentifier: "goToSummaryFromCode", sender:self)
                                }
                            }
                            
                        })
                        
                    }
                    
                }
                else
                {
                    let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    
                    DispatchQueue.main.async(execute: {
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                
            })
            
        }
        
    }
    
    @IBAction override func resendVerification()
    {
        self.resendButton.isEnabled = false
        dataManager.registerSendSmsDriver(completionCallback: {(success, error) in
            self.resendButton.isEnabled = true
            if(success)
            {
                //on success we do nothing
            }
            else
            {
                let alert = UIAlertController(title: "Error resending code!", message: error, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                DispatchQueue.main.async(execute: {
                    self.present(alert, animated: true, completion: nil)
                })
            }
            
        })
    }
    
    func numberOfStepsFinished() -> Int{
        if dataManager.onboarding_info.count > 0
        {
            var passed_step = 0
            for (_, element) in dataManager.onboarding_info
            {
                if let step_info = element as? NSDictionary
                {
                    if let is_checked = step_info["passed"] as? Bool
                    {
                        if is_checked
                        {
                          passed_step += 1
                        }
                    }
                }
            }
          return passed_step
        }
        else {
            return 0
        }
    }
    
    //check if sessiou valid
    func checkSession()
    {
        //check if our session is valid and if it is - go get drivers, and if not then go to login
        print("checkSession from driver check code!")
        
        let dataManager = DataManager.sharedInstance
        dataManager.checkSession(completionCallback: {(success, message) in
            if(success)
            { //session is valid
                print("session is valid")
                DispatchQueue.main.async(execute: {
                    self.performSegue(withIdentifier: "goToDriverMapFromCode", sender:self)
                })
                
            }
            else //session is invalid or interned connection is gone
            {
                print("Session is invalid: \(message)")

                let alert = UIAlertController(title: "Error checking session!", message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                DispatchQueue.main.async(execute: {
                    self.present(alert, animated: true, completion: nil)
                })

            }
        })
        //---check session end
    }


}
