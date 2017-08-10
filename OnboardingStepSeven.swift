//
//  OnboardingStepSeven.swift
//  SnowHub
//
//  Created by Liubov Perova on 4/26/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit

class OnboardingStepSeven: UIViewController {

   
    @IBOutlet weak var emailTextBusiness: UITextField!
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet weak var waitingWheel: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        
        waitingWheel.stopAnimating()
        waitingWheel.isHidden = true
        
        emailTextBusiness.becomeFirstResponder()

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        
        let dataManager:DataManager = DataManager.sharedInstance
        if dataManager.onboarding_info.count > 0
        {
            if let stepFive = dataManager.onboarding_info["7"] as? Dictionary<String, Any>
            {
                if let email = stepFive["email"] as? String
                {
                    self.emailTextBusiness.text = email
                }
                
            }
            
        }
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

    func isValidEmail(testStr:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    @IBAction func goBack(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goNext(){
        
        let dataManager:DataManager = DataManager.sharedInstance
        
        let stringEmail = emailTextBusiness.text
        
        if !stepDidChange(){
            goToNextStep()
            return
        }
        
        if( isValidEmail(testStr: stringEmail!)){
            
            nextButton.isEnabled = false
            waitingWheel.isHidden = false
            waitingWheel.startAnimating()
            nextButton.isEnabled = false
            
            dataManager.registerSendEmailDriver(email: stringEmail!, completionCallback: {(success, message) in
                
                DispatchQueue.main.async(execute: {
                    self.nextButton.isEnabled = true
                    self.waitingWheel.stopAnimating()
                    self.waitingWheel.isHidden = true
                })
                
                if(success)
                {
                    DispatchQueue.main.async(execute: {
                        dataManager.onboarding_info["7"] = ["step_status":"PASSED","email":stringEmail!]
                        self.goToNextStep()
                    })
                }
                else
                {
                    let alert = UIAlertController(title: "Error", message: "Some error happened while processing your data. \(message) ", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    
                    DispatchQueue.main.async(execute: {
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                
            })
            
        }
        else
        {
            let alert = UIAlertController(title: "Error", message: "Please enter valid email", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }

    func goToNextStep(){
        if OnboardingSummary.numberOfStepsFinished() == 8
        {
            self.performSegue(withIdentifier: "goToSummaryFromStep7", sender: self)
        }
        else
        {
            //self.performSegue(withIdentifier: "goToStep8", sender:self)
            self.goToMinUnfinishedStep()
        }
    }
    
    func stepDidChange() -> Bool
    {
        var changed = true
        
        let dManager = DataManager.sharedInstance
        
        let stringEmail = emailTextBusiness.text
        
        if dManager.onboarding_info.count > 0
        {
            if let step_info = dManager.onboarding_info["7"] as? NSDictionary
            {
                if let is_checked = step_info["step_status"] as? String, let email = step_info["email"] as? String
                {
                    if is_checked != StepStatus.NOT_PASSED.rawValue && email == stringEmail
                    {
                        changed = false
                    }
                }
            }
            
        }
        
        return changed
    }

    //go to min unfinished step
    func goToMinUnfinishedStep()
    {
        
        let dataManager = DataManager.sharedInstance
        
        var controllerID = "OnboardingStep"
        var min_step = 9;
        for (index, element) in dataManager.onboarding_info
        {
            if let step_info = element as? NSDictionary
            {
                if let is_checked = step_info["step_status"] as? String, !OnboardingSummary.stepIsUploading(step_number: index)
                {
                    if is_checked == StepStatus.NOT_PASSED.rawValue || is_checked == StepStatus.REJECTED.rawValue
                    {
                        if(min_step > Int(index)!)
                        {
                            min_step = Int(index)!
                        }
                    }
                }
            }
        }
        
        if min_step < 9
        {
            controllerID = "OnboardingStep\(String(min_step))"
            let nextController = self.storyboard?.instantiateViewController(withIdentifier: controllerID)
            if let _ = nextController
            {
                let navigationController = UINavigationController(rootViewController: nextController!)
                self.present(navigationController, animated: true, completion: nil)
            }
        }
        else
        {
            self.performSegue(withIdentifier: "goToSummaryFromStep7", sender: self)
        }
    }


}
