//
//  VerificationRegisterController.swift
//  SnowHub
//
//  Created by Liubov Perova on 10/28/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//
import UIKit
import Foundation

class VerificationRegisterController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var verificationText1: UITextField!
    @IBOutlet weak var verificationText2: UITextField!
    @IBOutlet weak var verificationText3: UITextField!
    @IBOutlet weak var verificationText4: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var nextItem: UIBarButtonItem!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var navigationBar: UINavigationBar!
    
    private struct Constants {
        static let InvisibleSign = "\u{200B}"
    }
    
    var dataManager:DataManager = DataManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.limitTextField(Notif:)), name: NSNotification.Name.UITextFieldTextDidChange, object: verificationText1)
        NotificationCenter.default.addObserver(self, selector: #selector(self.limitTextField(Notif:)), name: NSNotification.Name.UITextFieldTextDidChange, object: verificationText2)
        NotificationCenter.default.addObserver(self, selector: #selector(self.limitTextField(Notif:)), name: NSNotification.Name.UITextFieldTextDidChange, object: verificationText3)
        NotificationCenter.default.addObserver(self, selector: #selector(self.limitTextField(Notif:)), name: NSNotification.Name.UITextFieldTextDidChange, object: verificationText4)
        verificationText1.text = Constants.InvisibleSign
        verificationText1.becomeFirstResponder()
        
        verificationText1.delegate = self
        verificationText2.delegate = self
        verificationText3.delegate = self
        verificationText4.delegate = self
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.bottomConstraint.constant = (keyboardFrame.size.height) + 20
            })
        }
    }
    
    
    func keyboardWillHide(notification: NSNotification) {
        
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.bottomConstraint.constant = (keyboardFrame.size.height) + 20
            })
        }
    }
    
    func limitTextField(Notif:NSNotification) {
        
        var activeText = verificationText1
        var nextToBeActive = verificationText2
        if(verificationText2.isFirstResponder)
        {
            activeText = verificationText2
            nextToBeActive = verificationText3
        }
        else if(verificationText3.isFirstResponder)
        {
            activeText = verificationText3
            nextToBeActive = verificationText4
        }
        else if(verificationText4.isFirstResponder)
        {
            activeText = verificationText4
            nextToBeActive = nil
        }
        
        if var text = activeText!.text {
            if text.characters.count == 2 && text != Constants.InvisibleSign {
                //text = Constants.InvisibleSign + text
                activeText!.text = text
                if(nextToBeActive != nil)
                {
                  nextToBeActive?.text = Constants.InvisibleSign
                  nextToBeActive?.becomeFirstResponder()
                }
            }
            else if text.characters.count == 1 && text != Constants.InvisibleSign
            {
                text = Constants.InvisibleSign + text
                activeText!.text = text
                if(nextToBeActive != nil)
                {
                    nextToBeActive?.text = Constants.InvisibleSign
                    nextToBeActive?.becomeFirstResponder()
                }
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        
        let  char = string.cString(using: String.Encoding.utf8)!
        let isBackSpace = strcmp(char, "\\b")
        
        print("is backs \(isBackSpace)")
        
        if(Int(string) == nil && isBackSpace != -92)
        {
           return false
        }
        
        var prevToBeActive:UITextField? = nil
        if(verificationText2.isFirstResponder)
        {
            prevToBeActive = verificationText1
        }
        else if(verificationText3.isFirstResponder)
        {
            prevToBeActive = verificationText2
        }
        else if(verificationText4.isFirstResponder)
        {
            prevToBeActive = verificationText3
        }
        
        if (isBackSpace == -92) {
            if var str = textField.text {
                str = str.replacingOccurrences(of: Constants.InvisibleSign, with: "")
                if str.characters.count == 1 {
                    //last visible character, if needed u can skip replacement and detect once even in empty text field
                    //for example u can switch to prev textField
                    //do stuff here
                    
                    return true
                }
                else if str.characters.count == 0 {
                    if(prevToBeActive != nil)
                    {
                      prevToBeActive?.becomeFirstResponder()
                    }
                    return true
                }
            }
        }
        else if (textField.text?.characters.count)! > 1 { //1 char limit
                        print("char limit: \((textField.text?.characters.count)!)")
                        return false
                   }
        
        return true
    }
    
    /*
     // MARK: - Navigation
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    @IBAction func goNext()
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
            
            nextButton.isEnabled = false
            nextItem.isEnabled = false
            dataManager.sendLoginCode(completionCallback: {(success, message) in
                
                DispatchQueue.main.async(execute: {
                self.nextButton.isEnabled = true
                self.nextItem.isEnabled = true
                })
                
                if(success)
                {
                    self.dataManager.setUserPreferences()
                    if(self.dataManager.user.SID != "" && self.dataManager.user.user_id != 0 && self.dataManager.user.number != "")
                    {
                        if(self.dataManager.user.isDriver)
                        {
                            DispatchQueue.main.async(execute: {
                                self.performSegue(withIdentifier: "goToDriverMapRegistered", sender:self)
                            })
                        }
                        else
                        {
                            DispatchQueue.main.async(execute: {
                                self.performSegue(withIdentifier: "goToCustomerMapRegistered", sender:self)
                            })
                        }
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
    
    @IBAction func resendVerification()
    {
        self.resendButton.isEnabled = false
        dataManager.sendVerifyNumber(completionCallback: {(success, error) in
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

    
}
