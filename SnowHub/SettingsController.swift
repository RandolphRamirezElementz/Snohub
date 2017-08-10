//
//  SettingsController.swift
//  SnowHub
//
//  Created by Liubov Perova on 2/8/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit
import Stripe

class SettingsController: UIViewController, UITextFieldDelegate, STPPaymentContextDelegate {
    
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var emailInput: UITextField!
    @IBOutlet weak var numberInput: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cardsButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var soundsSwitch: UISwitch!
    @IBOutlet var navigationBar: UINavigationBar!
    
    var settingsChanged = false
    
    var dataManager:DataManager = DataManager.sharedInstance
    let settingsVC = SettingsViewController()
    let config = STPPaymentConfiguration.shared()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        numberInput.delegate = self
        emailInput.delegate = self
        firstName.delegate = self
        lastName.delegate = self
        
        self.soundsSwitch.isOn = dataManager.soundsOn
        
        let fullName    = dataManager.user.name
        let fullNameArr = fullName.components(separatedBy: " ")
        
        firstName.text = fullNameArr[0]
        
        if(fullNameArr.count > 1)
        {
           var last_name = ""
           for(index, value) in fullNameArr.enumerated()
           {
             if(index > 0)
             {
               last_name += value
             }
           }
           
           lastName.text = last_name
        }
        
        numberInput.text = dataManager.user.number
        emailInput.text = dataManager.user.email
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        self.navigationBar.layer.masksToBounds = false;
        self.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 8);
        self.navigationBar.layer.shadowRadius = 5;
        self.navigationBar.layer.shadowOpacity = 0.3;

    }

    @IBAction func setupStripeEnv()
    {
        // for stripe
        let stripePublishableKey = DataManager.sharedInstance.stripePublicKey
        let backendBaseURL: String? =  DataManager.sharedInstance.urlBase
        let appleMerchantID: String? = "merchant.snohub.app"
        let companyName = "SnoHub"
        let theme = self.settingsVC.settings.theme
        
        StripeAPIClient.sharedClient.baseURLString = backendBaseURL
        config.publishableKey = stripePublishableKey
        config.appleMerchantIdentifier = appleMerchantID
        config.companyName = companyName
        config.requiredBillingAddressFields = self.settingsVC.settings.requiredBillingAddressFields
        config.requiredShippingAddressFields = self.settingsVC.settings.requiredShippingAddressFields
        config.shippingType = self.settingsVC.settings.shippingType
        config.additionalPaymentMethods = .applePay
        config.smsAutofillDisabled = !self.settingsVC.settings.smsAutofillEnabled
        
        let paymentContext = STPPaymentContext(apiAdapter: StripeAPIClient.sharedClient,
                                               configuration: config,
                                               theme: theme)
       
        paymentContext.delegate = self
        paymentContext.hostViewController = self
        let paymentMethodsViewController = STPPaymentMethodsViewController.init(paymentContext: paymentContext)
        print("paymentMethodsViewController created. \(String(describing: paymentContext.paymentMethods))")
        print("apple pay enabled: \(Stripe.deviceSupportsApplePay)")
        let navController = UINavigationController(rootViewController: paymentMethodsViewController)
        self.present(navController, animated: true, completion: nil)

        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
         self.bottomConstraint.constant = 20
        
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
        
        //if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        //{
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.bottomConstraint.constant = 20
            })
        //}
    }
    
    //textfield delegate method
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
     
        settingsChanged = true
        
         textField.textColor = UIColor.white
        if textField == numberInput
        {
            if (numberInput.text?.characters.count)! < 15 {
                return true
                // Else if 10 and delete is allowed
            }else if (string.characters.count) == 0 {
                return true
                // Else limit reached
            }else{
                return false
            }
        }
        else
        {
           return true
        }
        
    }

    //if email is valid
    func isValidEmail(testStr:String?) -> Bool {
        // print("validate calendar: \(testStr)")
        if let _ = testStr
        {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
            let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailTest.evaluate(with: testStr)
        }
        else
        {
          return false
        }
    }

    //if number is valid
    func isValidNumber() -> Bool {
        if let text = numberInput.text
        {
         if let cleanText = dataManager.clearNumber(testStr: text)
         {
            return (cleanText.characters.count >= 10 ? true : false)
         }
         else
         {
           return false
         }
        }
        else
        {
         return false
        }
    }

    //if name is valid
    func isValidName(textInput: UITextField) -> Bool {
        if let charactersCount = textInput.text?.characters.count
        {
          return (charactersCount >= 2 && charactersCount < 256)
        }
        else
        {
         return false
        }
    }
    
    
    @IBAction func goSave(){
    
        dataManager.soundsOn = soundsSwitch.isOn
        dataManager.saveAppSettings() //save sounds
        
        //dismiss keyboard
        self.view.endEditing(true)
        
        if(!settingsChanged)
        {
           self.dismiss(animated: true, completion: nil)
           return
        }
        
        if( settingsChanged && isValidNumber() && isValidName(textInput: firstName) && isValidEmail(testStr: emailInput.text))
        {
            saveButton.isEnabled = false
            //dataManager.user.name = fullName.text!
            //dataManager.user.email = emailInput.text!
            //dataManager.user.number = dataManager.clearNumber(testStr: numberInput.text)!
    
            dataManager.changeSettings(firstName: firstName.text!, lastName: lastName.text!, login: dataManager.clearNumber(testStr: numberInput.text)!, email: emailInput.text!, completionCallback: { (success, message) in
                var messageText = message
                if(success)
                {
                  messageText = "You will receive links on email and/or SMS to confirm changes"
                  self.dataManager.user.name = self.firstName.text! + " " + self.lastName.text!
                  self.dataManager.setUserPreferences()
                }
                
                
                DispatchQueue.main.async(execute: {
                    self.saveButton.isEnabled = true
                    let alert = UIAlertController(title: "Settings change", message: messageText, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                })
            })
            
        }
        else
        {
            if(!isValidNumber())
            {
              numberInput.textColor = UIColor(red:0.09, green:0.81, blue:0.51, alpha:1.00)
            }
            
            if(!isValidEmail(testStr: emailInput.text))
            {
                emailInput.textColor = UIColor(red:0.09, green:0.81, blue:0.51, alpha:1.00)
            }
            
            if(!isValidName(textInput: firstName))
            {
               firstName.textColor = UIColor(red:0.09, green:0.81, blue:0.51, alpha:1.00)
            }
            
            let alert = UIAlertController(title: "Error", message: "All values shold be valid", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }

    @IBAction  func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    //payment context delegate methods
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        StripeAPIClient.sharedClient.completeCharge(paymentResult, amount: 0,
                                                    completion: completion)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
      
        let alertController = UIAlertController(title: title,  message:"Payment did finish", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
    
        })
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    
    }
    

    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
       print("Payment context been changed!")
        
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        let alertController = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            // Need to assign to _ because optional binding loses @discardableResult value
            _ = self.navigationController?.popViewController(animated: true)
        })
        let retry = UIAlertAction(title: "Retry", style: .default, handler: { action in
            paymentContext.retryLoading()
        })
        alertController.addAction(cancel)
        alertController.addAction(retry)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didUpdateShippingAddress address: STPAddress, completion: @escaping STPShippingMethodsCompletionBlock) {
        
    }
    

}
