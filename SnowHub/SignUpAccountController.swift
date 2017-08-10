//
//  SignUpAccountController.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/25/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//
import UIKit
import Stripe

class SignUpAccountController: UIViewController {
    
    @IBOutlet weak var accountHolder: UITextField!
    @IBOutlet weak var routingNumber: UITextField!
    @IBOutlet weak var accountNumber: UITextField!
    @IBOutlet weak var reAccountNumber: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var nextItem: UIBarButtonItem!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var driverSwitch: UISwitch!
    @IBOutlet var navigationBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        accountHolder.becomeFirstResponder()
        
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
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    @IBAction func goToNumber(){
        
        let dataManager:DataManager = DataManager.sharedInstance
    
        dataManager.user.bankAccountHolder = accountHolder.text!
        dataManager.user.bankAccountNumber = accountNumber.text!
        dataManager.user.bankRoutingNumber = routingNumber.text!
        
        let valid_repeat:Bool = (accountNumber.text! == reAccountNumber.text!)
        let valid_account:Bool = isValidAccountNumber(testStr: dataManager.user.bankAccountNumber)
        let valid_number:Bool = isValidRoutingNumber(testStr: dataManager.user.bankRoutingNumber)
        
        if(valid_account && valid_number && dataManager.user.bankAccountHolder != "" && valid_repeat){
            dataManager.setUserPreferences() //save to preferences
            self.performSegue(withIdentifier: "goToPhoneNumber", sender:self) //go to next stage
        }
        else
        {
            let alert = UIAlertController(title: "Error", message: "All fields should be valid", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    
    func isValidAccountNumber(testStr:String?) -> Bool {
        var charset = NSCharacterSet.decimalDigits
        charset.invert()
        let dataManager:DataManager = DataManager.sharedInstance
        if let length_text = testStr?.trimmingCharacters(in: charset){
            if(length_text.characters.count == 12) {
                dataManager.user.bankAccountNumber = length_text
                return true}
            else {return false}
        }
        else {return false}
    }
    
    func isValidRoutingNumber(testStr:String?) -> Bool {
        var charset = NSCharacterSet.decimalDigits
        charset.invert()
         let dataManager:DataManager = DataManager.sharedInstance
        if let length_text = testStr?.trimmingCharacters(in: charset){
            if(length_text.characters.count >= 6 && length_text.characters.count <= 9)
            {
                dataManager.user.bankRoutingNumber = length_text
                return true}
            else {return false}
        }
        else {return false}
    }
    
}
