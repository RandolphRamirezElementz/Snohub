//
//  OnboardingStepFour.swift
//  SnowHub
//
//  Created by Liubov Perova on 4/25/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit
import Kingfisher

class OnboardingStepFour: OnboardingStepOne {
  
    override var image_key:String { get { return "onboarding_step_4" } }
    override var step_key:String  { get { return "4" } }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction override func goNext()
    {
        if(!imageTaken && isStepPassed())
        {
            self.goToNextStep()
            return
        }
        
        let dataManager:DataManager = DataManager.sharedInstance
        
        if((dataManager.user.SIDunaccepted == "" && dataManager.user.SID == "") || self.UIImageData == nil /*|| !imageTaken */)
        {
            var message = "Please choose an image"
            if((dataManager.user.SIDunaccepted == "" && dataManager.user.SID == ""))
            {
                message = "Your login is invalid!"
            }
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            //DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
            //})
        }
        else
        {
            
            self.nextButton.isEnabled = false
            self.prevItem.isEnabled = false
//            self.waitingWheel.startAnimating()
//            self.waitingWheel.isHidden = false
//            
//            let parameters = [
//                "session_id": dataManager.user.SIDunaccepted as Any,
//                "image": self.takenImage.image as Any
//            ]
//            
//            dataManager.postFormData(parameters: parameters, urlstring: "/users/registerDriver/4", completionCallback: { (success, message) in
//                
//                DispatchQueue.main.async(execute: {
//                    self.nextButton.isEnabled = true
//                    self.prevItem.isEnabled = true
//                    self.waitingWheel.stopAnimating()
//                    self.waitingWheel.isHidden = true
//                })
//                
//                if(success)
//                {
//                    //go to next step
//                    DispatchQueue.main.async(execute: {
//                        //ImageCache.default.store(self.takenImage.image!, forKey: self.image_key)
//                        dataManager.onboarding_info["4"] = ["step_status":"PASSED"]
//                        self.goToNextStep()
//                    })
//                }
//                else
//                {
//                    let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
//                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
//                    
//                    DispatchQueue.main.async(execute: {
//                        self.present(alert, animated: true, completion: nil)
//                    })
//                }
//                
//            })

            //upload image asynchronously via the upload manager
            let uploadManager = UploadsManager.sharedInstance
            uploadManager.startUpload(step_number: self.step_key, image: self.imageRotatedNormal(image:self.takenImage.image!))

            //maenwhile go to next step
            DispatchQueue.main.async(execute: {
                self.goToNextStep()
            })

        }
        
    }

    override func goToNextStep(){
        if OnboardingSummary.numberOfStepsFinished() == 8
        {
            self.performSegue(withIdentifier: "goToSummaryFromStep4", sender: self)
        }
        else
        {
            //self.performSegue(withIdentifier: "goToStep5", sender:self)
            self.goToMinUnfinishedStep()
        }
    }

    
}