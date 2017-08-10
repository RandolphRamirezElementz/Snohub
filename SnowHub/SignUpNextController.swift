//
//  SignUpNextController.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/2/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class SignUpNextController: UIViewController {

    @IBOutlet weak var firstNameText: UITextField!
    @IBOutlet weak var lastNameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
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
    
        firstNameText.becomeFirstResponder()
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true

        driverSwitch.onTintColor =  UIColor(red:1.0, green:(87.0/255.0), blue:0.0, alpha:1.00)
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
        
        dataManager.user.name = firstNameText.text! + " " + lastNameText.text!
        dataManager.user.email = emailText.text!
        dataManager.user.isDriver = driverSwitch.isOn
        
        
        let valid_email:Bool = isValidEmail(testStr: dataManager.user.email)
        
        if(valid_email && dataManager.user.name != ""){
            dataManager.setUserPreferences() //save to preferences
            if(dataManager.user.isDriver)
            {
             //self.performSegue(withIdentifier: "goToAccountNumber", sender:self) //go to next stage
             self.performSegue(withIdentifier: "goToCustomerNumber", sender:self) //go to next stage
            }
            else
            {
             self.performSegue(withIdentifier: "goToCustomerNumber", sender:self) //go to next stage
                
            }
        }
        else
        {
            let alert = UIAlertController(title: "Error", message: "User name and email shold be valid", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
   }
    
   
    func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }

}
