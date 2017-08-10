//
//  OnboardingStepFive.swift
//  SnowHub
//
//  Created by Liubov Perova on 4/25/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit

class OnboardingStepFive: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var accountTextPersonal: UITextField!
    @IBOutlet weak var accountTextBusiness: UITextField!

    @IBOutlet weak var businessAccType: CheckBoxButton!
    @IBOutlet weak var personalAccType: CheckBoxButton!
    
    @IBOutlet weak var businessAccButton: UIButton!
    @IBOutlet weak var personalAccButton: UIButton!
    
    @IBOutlet weak var AccTypeLabel: UILabel!
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet weak var waitingWheel: UIActivityIndicatorView!


    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        //set Business acc to work
        accountTextPersonal.isHidden = true
        businessAccType.setChecked()
        
        accountTextBusiness.isHidden = false
        personalAccType.setUnchecked()
        
        AccTypeLabel.text = "Employer Identificational Number"
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        
        let dataManager:DataManager = DataManager.sharedInstance
        if dataManager.onboarding_info.count > 0
        {
            if let stepFive = dataManager.onboarding_info["5"] as? Dictionary<String, Any>
            {
                if let employer_number = stepFive["employer_identification_number"] as? String
                {
                    if employer_number != ""
                    {
                        accountTextPersonal.isHidden = true
                        accountTextBusiness.isHidden = false
                        businessAccType.setChecked()
                        personalAccType.setUnchecked()
                        
                        personalAccButton.titleLabel!.font = UIFont(name: "GothamPro-Light", size: 18)
                        businessAccButton.titleLabel!.font = UIFont(name: "GothamPro", size: 18)
                        
                        accountTextBusiness.text = employer_number
                        AccTypeLabel.text = "Employer Identificational Number"
                    }
                }
                else if let social_number = stepFive["social_secure_number"] as? String
                {
                    if social_number != ""
                    {
                        accountTextPersonal.isHidden = false
                        accountTextBusiness.isHidden = true
                        businessAccType.setUnchecked()
                        personalAccType.setChecked()
                        
                        personalAccButton.titleLabel!.font = UIFont(name: "GothamPro", size: 18)
                        businessAccButton.titleLabel!.font = UIFont(name: "GothamPro-Light", size: 18)
                        
                        accountTextPersonal.text = social_number
                        AccTypeLabel.text = "Social Security Number"
                    }
                }
            }
            
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
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.bottomConstraint.constant = (keyboardFrame.size.height) + 35
            })
        }
    }
    
    
    func keyboardWillHide(notification: NSNotification) {
        
        if let _ = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.bottomConstraint.constant = 0
            })
        }
    }

    //make personal acc input active
    @IBAction func setPersonalAccActive(){
        
        accountTextPersonal.isHidden = false
        accountTextBusiness.isHidden = true
        businessAccType.setUnchecked()
        personalAccType.setChecked()
        
        personalAccButton.titleLabel!.font = UIFont(name: "GothamPro", size: 18)
        businessAccButton.titleLabel!.font = UIFont(name: "GothamPro-Light", size: 18)
        
        accountTextPersonal.becomeFirstResponder()
        AccTypeLabel.text = "Social Security Number"
    }
    
    //make business acc input active
    @IBAction func setBusinessAccActive(){
        
        accountTextPersonal.isHidden = true
        accountTextBusiness.isHidden = false
        businessAccType.setChecked()
        personalAccType.setUnchecked()
        
        personalAccButton.titleLabel!.font = UIFont(name: "GothamPro-Light", size: 18)
        businessAccButton.titleLabel!.font = UIFont(name: "GothamPro", size: 18)
        
        accountTextBusiness.becomeFirstResponder()
        AccTypeLabel.text = "Employer Identificational Number"
    
    }
    
    @IBAction func goBack(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goNext(){
        
        if !stepDidChange(){
           goToNextStep()
           return
        }
        
        let dataManager:DataManager = DataManager.sharedInstance
        
        var acc_type = "business"
        var stringNumber = ( (self.accountTextBusiness.text?.characters.count)! > 0 ? dataManager.clearNumber(testStr: (self.accountTextBusiness.text)) : "" )
        if(self.personalAccType.checked){
            acc_type = "personal"
            stringNumber = ( (self.accountTextPersonal.text?.characters.count)! > 0 ? dataManager.clearNumber(testStr: (self.accountTextPersonal.text)) : "" )
        }
        
        
        
        print("account number: \(String(describing: stringNumber))")
        
        
        if( (stringNumber?.characters.count)! > 6 && (stringNumber?.characters.count)! <= 15){
    
            nextButton.isEnabled = false
            waitingWheel.isHidden = false
            waitingWheel.startAnimating()
            nextButton.isEnabled = false
            
            dataManager.registerSendAccountDriver(accNumber: stringNumber!, accType: acc_type, completionCallback: {(success, message) in
                
                DispatchQueue.main.async(execute: {
                    self.nextButton.isEnabled = true
                    self.waitingWheel.stopAnimating()
                    self.waitingWheel.isHidden = true
                })
                
                if(success)
                {
                    DispatchQueue.main.async(execute: {
                        dataManager.onboarding_info["5"] = ["step_status":"PASSED",
                                                            "employer_identification_number": self.accountTextBusiness.text ?? "",
                                                            "social_secure_number": self.accountTextPersonal.text ?? ""]
                        
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
            let alert = UIAlertController(title: "Error", message: "Please enter valid account number", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func goToNextStep(){
        if OnboardingSummary.numberOfStepsFinished() == 8
        {
            self.performSegue(withIdentifier: "goToSummaryFromStep5", sender: self)
        }
        else
        {
            //self.performSegue(withIdentifier: "goToStep6", sender:self)
            self.goToMinUnfinishedStep()
        }
    }
    
    func stepDidChange() -> Bool
    {
        var changed = true
        
        let dManager = DataManager.sharedInstance
        
        var stringNumber = ( (self.accountTextBusiness.text?.characters.count)! > 0 ? dManager.clearNumber(testStr: (self.accountTextBusiness.text)) : "" )
        var acc_type =  "employer_identification_number"
        if(self.personalAccType.checked)
          {
             acc_type = "social_secure_number"
             stringNumber = ( (self.accountTextPersonal.text?.characters.count)! > 0 ? dManager.clearNumber(testStr: (self.accountTextPersonal.text)) : "" )
          }
        
        if dManager.onboarding_info.count > 0
        {
            if let step_info = dManager.onboarding_info["5"] as? NSDictionary
            {
                if let is_checked = step_info["step_status"] as? String, let acc_number = step_info[acc_type] as? String
                {
                    if is_checked != StepStatus.NOT_PASSED.rawValue && acc_number == stringNumber
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
          self.performSegue(withIdentifier: "goToSummaryFromStep5", sender: self)
        }
    }

    
}
