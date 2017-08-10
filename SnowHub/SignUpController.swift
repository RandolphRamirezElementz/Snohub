//
//  SignUpController.swift
//  SnowHub
//
//  Created by Liubov Perova on 10/28/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class SignUpController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var numberText: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var nextItem: UIBarButtonItem!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var checkBoxAgree: CheckBoxButton!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet weak var waitingWheel: UIActivityIndicatorView!
    
    var isLoading: Bool = false;

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        
        let dataManager:DataManager = DataManager.sharedInstance
        numberText.text = dataManager.user.number
        numberText.delegate = self
        numberText.becomeFirstResponder()
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true

         waitingWheel.stopAnimating()
         waitingWheel.isHidden = true
        
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
            // Else if 4 and delete is allowed
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
    
    @IBAction func checkSwitch(){
        checkBoxAgree.switchButton()
    }

    
    @IBAction func goToVerification(){
        if(isLoading || !checkBoxAgree.checked)
        {
         return
        }

        
        let dataManager:DataManager = DataManager.sharedInstance
        
        let stringNumber = (numberText.text?.characters.count)! > 0 ? dataManager.clearNumber(testStr: numberText.text) : ""//numberText.text?.replacingOccurrences(of: "\\D", with: "")
        print("number: \(String(describing: stringNumber))")
        
        dataManager.user.number = stringNumber!
         print("user: \(dataManager.user)")
        
        if( dataManager.user.number != "" && dataManager.user.number.characters.count >= 10){
            dataManager.setUserPreferences() //save to preferences
            
            nextButton.isEnabled = false
            waitingWheel.isHidden = false
            waitingWheel.startAnimating()
            isLoading = true
            nextButton.isEnabled = false
            
            dataManager.sendSignUpNumber(completionCallback: {(success, message) in
                
                DispatchQueue.main.async(execute: {
                   self.nextButton.isEnabled = true
                   self.waitingWheel.stopAnimating()
                   self.waitingWheel.isHidden = true
                   self.isLoading = false
                })
                
                if(success)
               {
                 DispatchQueue.main.async(execute: {
                  self.nextButton.isEnabled = true
                  self.performSegue(withIdentifier: "goToRegsterVerification", sender:self) //go to next stage
                 })
               }
               else
               {
                 let alert = UIAlertController(title: "Error", message: "Some error happened while processing your data. \(message) ", preferredStyle: UIAlertControllerStyle.alert)
                 alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                 DispatchQueue.main.async(execute: {
                 self.nextButton.isEnabled = true
                 self.present(alert, animated: true, completion: nil)
                 })
               }
                
            })
           
             //self.performSegue(withIdentifier: "goToVerificationCode", sender:self) //go to next stage
            
         }
         else
         {
            let alert = UIAlertController(title: "Error", message: "Please enter valid phone number", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
         }
        
    }
    

    @IBAction func goToTerms(){
        if let url = URL(string: "https://snohub.com/terms/") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        
    }
}
