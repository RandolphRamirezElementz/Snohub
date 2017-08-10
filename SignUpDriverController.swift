//
//  SignUpDriverController.swift
//  SnowHub
//
//  Created by Liubov Perova on 4/24/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit

class SignUpDriverController: SignUpController {

  
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction override func goToVerification(){
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
            
            dataManager.registerSendSmsDriver(completionCallback: {(success, message) in
                
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
                        self.performSegue(withIdentifier: "goToDriverRegistrationVerify", sender:self) //go to next stage
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
            
        }
        else
        {
            let alert = UIAlertController(title: "Error", message: "Please enter valid phone number", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }


}
