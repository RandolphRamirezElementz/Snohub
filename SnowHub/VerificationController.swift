//
//  VerificationController.swift
//  SnowHub
//
//  Created by Liubov Perova on 10/28/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit
import Foundation

class VerificationController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var navigationBar: UINavigationBar!
    
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var successLabel: UILabel!
    
    @IBOutlet weak var waitingForAnswer: UIActivityIndicatorView!

    
    var receivedToken: String?
    var dataManager:DataManager = DataManager.sharedInstance
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.waitingForAnswer.isHidden = true
        
        self.resendButton.isHidden = true
        self.infoLabel.isHidden = true
        self.successLabel.isHidden = true

            }

    override func viewDidAppear(_ animated: Bool) {
       
        
        print("checkSession from verification! SID - \(dataManager.user.SID)")
        if(dataManager.user.SID != "")
        {
            DispatchQueue.main.async(execute: {
                self.waitingForAnswer.isHidden = false
                self.waitingForAnswer.startAnimating()
            })
            checkSession()
            
        }//sid is present
        else
        {
            self.successLabel.isHidden = true
            self.infoLabel.isHidden = false
            self.resendButton.isHidden = false
            
            //we got token
            if let token = self.receivedToken as String?
            {
                DispatchQueue.main.async(execute: {
                    self.waitingForAnswer.isHidden = false
                    self.waitingForAnswer.startAnimating()
                })

                dataManager.generateSession(token: token, completionCallback: { (success, error) in
                    if(success)
                    {
                        self.checkSession()
                    }
                    else
                    {
                        let alert = UIAlertController(title: "Error", message: error, preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        
                        DispatchQueue.main.async(execute: {
                            
                           
                                self.waitingForAnswer.isHidden = true
                                self.waitingForAnswer.stopAnimating()
                        
                            self.successLabel.isHidden = true
                            self.infoLabel.text = "Please try again"
                            self.resendButton.isHidden = false
                            self.present(alert, animated: true, completion: nil)
                        })
                        
                    }
                })
                
            }
        }

    }
    
    
    func checkSession()
    {
        dataManager.checkSession { (success, message) in
            if(success)
            {
                self.dataManager.gotLoggedOut = false
                self.dataManager.setUserPreferences()

                self.successLabel.isHidden = false
                self.infoLabel.isHidden = true
                self.resendButton.isHidden = true

                print("User received. Id: \(self.dataManager.user.user_id ), login: \(self.dataManager.user.number), SID: \(self.dataManager.user.SID) ")
                if(self.dataManager.user.SID != "" && self.dataManager.user.user_id != 0 && self.dataManager.user.number != "")
                {
                    if(self.dataManager.user.isDriver)
                    {
                        DispatchQueue.main.async(execute: {
                            
                            self.waitingForAnswer.isHidden = true
                            self.waitingForAnswer.stopAnimating()

                            self.performSegue(withIdentifier: "goToDriverMap", sender:self)
                        })
                    }
                    else
                    {
                        DispatchQueue.main.async(execute: {
                            
                            self.waitingForAnswer.isHidden = true
                            self.waitingForAnswer.stopAnimating()

                            self.performSegue(withIdentifier: "goToCustomerMap", sender:self)
                        })
                    }
                }
                
            }
            else
            {
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                DispatchQueue.main.async(execute: {
                    
                    self.waitingForAnswer.isHidden = true
                    self.waitingForAnswer.stopAnimating()
                    
                    self.successLabel.isHidden = true
                    self.infoLabel.text = "Please try again"
                    self.present(alert, animated: true, completion: nil)
                })
            }
            
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func resendVerification()
    {
        print("Resend verification for user: \(dataManager.user.number)")
        dataManager.sendLoginNumber(completionCallback: {(success, error) in
            if(success)
            {
                self.successLabel.isHidden = true
                self.infoLabel.isHidden = false
            }
            else
            {
                let alert = UIAlertController(title: "Error", message: error, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                DispatchQueue.main.async(execute: {
                    self.successLabel.isHidden = true
                    self.infoLabel.text = "Please try again"
                    self.resendButton.isHidden = false
                    self.present(alert, animated: true, completion: nil)
                })
            }
            
        })
    }

}
