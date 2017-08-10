//
//  LoginController.swift
//  SnowHub
//
//  Created by Liubov Perova on 10/28/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class LoginController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var numberText: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var waitingWheel: UIActivityIndicatorView!
    @IBOutlet var navigationBar: UINavigationBar!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        numberText.delegate = self
        numberText.becomeFirstResponder()

        
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
    
    
    //textfield delegate methods
    func textField(_: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (numberText.text?.characters.count)! < 15 {
            return true
            // Else if 10 and delete is allowed
        }else if (string.characters.count) == 0 {
            return true
            // Else limit reached
        }else{
            return false
        }
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func goToVerification(){
        
        let dataManager:DataManager = DataManager.sharedInstance
        
        let stringNumber = (numberText.text?.characters.count)! > 0 ? dataManager.clearNumber(testStr: numberText.text) : ""
        print("number: \(stringNumber ?? defaultValue)")
        
        dataManager.user.number = stringNumber!
        
        if( dataManager.user.number != "" && dataManager.user.number.characters.count >= 10){
            
            self.nextButton.isEnabled = false
            waitingWheel.isHidden = false
            waitingWheel.startAnimating()
            dataManager.setUserPreferences() //save to preferences
            
            dataManager.sendLoginNumber(completionCallback: {(success, error) in
                
                  DispatchQueue.main.async(execute: {
                    self.nextButton.isEnabled = true
                    self.waitingWheel.stopAnimating()
                    self.waitingWheel.isHidden = true
                  })
                
                if(success)
                {
                    DispatchQueue.main.async(execute: {
                     self.performSegue(withIdentifier: "goToVerificationLogin", sender:self) //go to next stage
                    })
                }
                else
                {
                    let alert = UIAlertController(title: "Error", message: error, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    
                    DispatchQueue.main.async(execute: {
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                
            })
            //self.performSegue(withIdentifier: "goToVerificationLogin", sender:self) //go to next stage

        }
        else
        {
            let alert = UIAlertController(title: "Error", message: "Please enter valid phone number", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }

}
