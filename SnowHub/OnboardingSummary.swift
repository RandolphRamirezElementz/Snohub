//
//  OnboardingSummary.swift
//  SnowHub
//
//  Created by Liubov Perova on 4/26/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit
import Kingfisher
import KYCircularProgress

class OnboardingSummary: UIViewController {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet weak var waitingWheel: UIActivityIndicatorView!
    
    @IBOutlet weak var stepOneCheck: UIImageView!
    @IBOutlet weak var stepTwoCheck: UIImageView!
    @IBOutlet weak var stepThreeCheck: UIImageView!
    @IBOutlet weak var stepFourCheck: UIImageView!
    @IBOutlet weak var stepFiveCheck: UIImageView!
    @IBOutlet weak var stepSixCheck: UIImageView!
    @IBOutlet weak var stepSevenCheck: UIImageView!
    @IBOutlet weak var stepEightCheck: UIImageView!
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var loginLabel: UILabel!
    
    //circular progress bars
    @IBOutlet weak var uploadProgressOne: KYCircularProgress!
    @IBOutlet weak var uploadProgressTwo: KYCircularProgress!
    @IBOutlet weak var uploadProgressThree: KYCircularProgress!
    @IBOutlet weak var uploadProgressFour: KYCircularProgress!
    @IBOutlet weak var uploadProgressSix: KYCircularProgress!
    
    var registration_info: Dictionary<String, Any> = [:]
    var uploadStepsBars: Dictionary<String, KYCircularProgress> = [:]
    var step_checks: Dictionary<String, UIImageView> = [:]
    let dataManager = DataManager.sharedInstance
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        
        waitingWheel.stopAnimating()
        waitingWheel.isHidden = true
        
        step_checks = ["1":stepOneCheck, "2":stepTwoCheck, "3":stepThreeCheck, "4":stepFourCheck, "5":stepFiveCheck, "6":stepSixCheck, "7":stepSevenCheck, "8":stepEightCheck]
        uploadStepsBars = [
                           "1" : uploadProgressOne,
                           "2" : uploadProgressTwo,
                           "3" : uploadProgressThree,
                           "4" : uploadProgressFour,
                           "6" : uploadProgressSix
                          ]
        
        uploadProgressOne.colors = [UIColor(rgba: 0x000000FF), UIColor(rgba: 0xFFFFFFFF)]
        uploadProgressTwo.colors = [UIColor(rgba: 0x000000FF), UIColor(rgba: 0xFFFFFFFF)]
        uploadProgressThree.colors = [UIColor(rgba: 0x000000FF), UIColor(rgba: 0xFFFFFFFF)]
        uploadProgressFour.colors = [UIColor(rgba: 0x000000FF), UIColor(rgba: 0xFFFFFFFF)]
        uploadProgressSix.colors = [UIColor(rgba: 0x000000FF), UIColor(rgba: 0xFFFFFFFF)]
        
        //check if steps info i available
        //if registration_info.count == 0
        //{
          registration_info = dataManager.onboarding_info
        //}
        
        loginLabel.text = dataManager.user.number
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //add observer for uploadStatusChanged
        NotificationCenter.default.removeObserver(self, name: .onBoardingStepFinished, object: nil)
        NotificationCenter.default.removeObserver(self, name: .bytesSendForStep, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onStepFinished(withNotification:)), name: .onBoardingStepFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onProgressUpdated(withNotification:)), name: .bytesSendForStep, object: nil)
        
        print("registration info: \(self.registration_info)")
        registration_info = dataManager.onboarding_info
        if registration_info.count > 0
        {
            //check
            if OnboardingSummary.numberOfStepsFinished() < 8 {
                //nextButton.titleLabel?.text = "CONTINUE REGISTRATION"
                //nextButton.titleLabel?.sizeToFit()
                
                nextButton.setTitle("CONTINUE REGISTRATION", for: .normal)
                nextButton.setTitle("CONTINUE REGISTRATION", for: .highlighted)
                
            }
            self.showSteps()
        }
        
        self.restartUploads() //restart uploads if there're any unfinished
        self.configureAllProgressBars() //show all progress bars (or hide if no active uploads)

        self.checkSessionOnBoarding( refresh: false )
        
        topView.clipsToBounds = true
        topView.layer.masksToBounds = false
        topView.layer.shadowColor = UIColor.black.cgColor;
        topView.layer.shadowOffset = CGSize(width:5.0, height:5.0);
        topView.layer.shadowOpacity = 0.5;
        topView.layer.shadowRadius = 10.0;
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //remove observer for uploadStatusChanged
        NotificationCenter.default.removeObserver(self, name: .onBoardingStepFinished, object: nil)
        NotificationCenter.default.removeObserver(self, name: .bytesSendForStep, object: nil)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func goNext(){
        
         if(OnboardingSummary.numberOfStepsFinished() == 8)
         {
            
            checkSessionOnBoarding( refresh:true )
            
         }
         else
         {
             self.goToMinUnfinishedStep()
         }
      
        
    }
    
    func showSteps()
    {
       for (index, element) in registration_info
       {
        if let step_info = element as? NSDictionary
        {
            if let is_checked = step_info["step_status"] as? String
            {
                
                    switch (is_checked) {
                    case StepStatus.APPROVED.rawValue:
                         step_checks[index]?.image = UIImage(named: "check_mark_green")
                    case StepStatus.REJECTED.rawValue:
                        step_checks[index]?.image = UIImage(named: "rejected_cross")
                    case StepStatus.PASSED.rawValue:
                        step_checks[index]?.image = UIImage(named: "checkmark_hourglass")
                    default:
                         break
                    }
                
                step_checks[index]?.isHidden = (is_checked == StepStatus.NOT_PASSED.rawValue)
            }
         }
       }
    }
    
    //check if session valid
    func checkSessionOnBoarding( refresh:Bool )
    {
        //if we have to compare previous steps state to new ones
        let prev_state = [:].merged(with: self.dataManager.onboarding_info);
        
        //check if our session is valid and if it is - go get drivers, and if not then go to login
        print("checkSession from onboarding interface!")
        
        nextButton.isEnabled = false
        waitingWheel.isHidden = false
        waitingWheel.startAnimating()
    
        dataManager.checkSessionOnBoarding(completionCallback: {(success, message, steps_info) in
            
            DispatchQueue.main.async(execute: {
                self.nextButton.isEnabled = true
                self.waitingWheel.stopAnimating()
                self.waitingWheel.isHidden = true
            })
            
            if(success)
            { //session is valid
                print("session is valid")
                DispatchQueue.main.async(execute: {
                    
                    self.registration_info = self.dataManager.onboarding_info
                    if self.registration_info.count > 0
                    {
                        if OnboardingSummary.numberOfStepsFinished() < 8 {
                            self.nextButton.setTitle("CONTINUE REGISTRATION", for: .normal)
                            self.nextButton.setTitle("CONTINUE REGISTRATION", for: .highlighted)
                        }
                        self.showSteps()
                    }
                    
                    if(refresh)
                    {
                      self.refreshCompareState(with: prev_state)
                    }
                    
                })
                
            }
            else //session is invalid or interned connection is gone
            {
                let alert = UIAlertController(title: "Error", message: "Something gone wrong while getting your registration info: \(message) ", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                DispatchQueue.main.async(execute: {
                    self.present(alert, animated: true, completion: nil)
                })
                
            }
        })
        //---check session end
    }

    
   public static func numberOfStepsFinished() -> Int{
    let dManager = DataManager.sharedInstance
    if dManager.onboarding_info.count > 0
        {
            var passed_step = 0
            for (index, element) in dManager.onboarding_info
            {
                if let step_info = element as? NSDictionary
                {
                    if let is_checked = step_info["step_status"] as? String
                    {
                        if is_checked != StepStatus.NOT_PASSED.rawValue || OnboardingSummary.stepIsUploading(step_number: index)
                        {
                            passed_step += 1
                        }
                    }
                }
            }
            return passed_step
        }
        else {
            return 0
        }
    }

    
    @IBAction func goHome()
    {
       dataManager.LogOut()
        
        // Clear memory cache right away.
        ImageCache.default.clearMemoryCache()
        // Clear disk cache. This is an async operation.
        ImageCache.default.clearDiskCache()
        
        let uploadManager = UploadsManager.sharedInstance
        uploadManager.clearAllOnboardingUploads()
        
       self.performSegue(withIdentifier: "goLogoutDriver", sender: self)
    
    }
    
    func goToMinUnfinishedStep()
    {
      var segueName = "goToFinishStep"
      var min_step = 8;
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

      segueName = "goToFinishStep\(String(min_step))"
      self.performSegue(withIdentifier: segueName, sender: self)
    }
    
    //comapring state to previous and if driver had been approved then we go to the map
    func refreshCompareState(with dictionary: Dictionary<String, Any>)
    {
        var changes_made = ""
        
        for (index, element) in dataManager.onboarding_info
        {
            if let step_info = element as? NSDictionary
            {
                if let is_checked = step_info["step_status"] as? String
                {
                    
                        var message = ""
                        if is_checked == StepStatus.REJECTED.rawValue
                        {
                            message = "Step \(index) has been rejected by admin\n"
                        }
                        else if is_checked == StepStatus.APPROVED.rawValue
                        {
                            message = "Step \(index) has been approved by admin\n"
                        }
                        
                         //prev state
                         if let prev_state = dictionary[index] as? Dictionary<String, Any>
                         {
                           if let prev_approved = prev_state["step_status"] as? String
                           {
                             if prev_approved != is_checked
                             {
                                changes_made += message
                             }
                           }
                         }
                    
                }
            }
        }
    
        //now inform user about changes that were made
        if(dataManager.user.SID != "")
        {
          self.checkSession()
        }
        else if changes_made != ""
        {
            let alert = UIAlertController(title: "Info", message: changes_made, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:nil))
            
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        }
        
    }
    
    //gesture recognizer to tap on label
    @IBAction func showInfo(sender:UIGestureRecognizer){
        
        if let targetImageView = sender.view as? UIImageView
        {
           if let step_info = self.registration_info[String(targetImageView.tag)] as? NSDictionary
           {
            if let reason = step_info["reason"] as? String
            {
                print("reason: \"\(reason)\"")
                if reason != ""
                {
                    let alert = UIAlertController(title: "Info", message: reason, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:nil))
                    
                    DispatchQueue.main.async(execute: {
                        self.present(alert, animated: true, completion: nil)
                    })
                }
            }
            
           }
         
        }
        
        
    }

    
    //check session (not temporary)
    //check if sessiou valid
    func checkSession()
    {
        //check if our session is valid and if it is - go get drivers, and if not then go to login
        print("checkSession from customer!")
        
        let dataManager = DataManager.sharedInstance
        dataManager.checkSession(completionCallback: {(success, message) in
            if(success)
            { //session is valid
                print("session is valid")
                
                let changes_made = "You've been approved by SnoHub administrator. You can start working now"
                let alert = UIAlertController(title: "Info", message: changes_made, preferredStyle: UIAlertControllerStyle.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                    if(self.dataManager.user.SID != "")
                    {
                        DispatchQueue.main.async(execute: {
                            self.performSegue(withIdentifier: "goToDriverMap", sender: self)
                        })
                    }
                }))
                
                DispatchQueue.main.async(execute: {
                    self.present(alert, animated: true, completion: nil)
                })

                
            }
            else //session is invalid or interned connection is gone
            {
                
                print("Session is invalid: \(message)")
                
                DispatchQueue.main.async(execute: {
                 
                })
                
            }
        })
        //---check session end
    }

    
    //uploading

    //is given stap  uploading?
    static public func stepIsUploading(step_number: String) -> Bool{
        
        let uploadManager = UploadsManager.sharedInstance
        var isUploading = false
        
        if let step:Dictionary<String, Any> = uploadManager.onboardingSteps[step_number] as? Dictionary<String, Any>
        {
            if let started = step["started"] as? Bool, let finished = step["finished"] as? Bool, let active = step["active"] as? Bool
            {
                if started && !finished && active
                {
                    isUploading = true
                }
            }
            
        }
        return isUploading
    }
    

    
    //handle notifications
    func onStepFinished(withNotification notification : NSNotification)
    {
        print("Step finished info: \(String(describing: notification.userInfo))")
        if let info = notification.userInfo as? Dictionary<String, Any>
        {
            if let step_number = info["step_number"] as? String
            {
                    if let success = info["success"] as? Bool , let message = info["error"] as? String
                    {
                        runFinishHandler(success: success, message: message, step_number: step_number)
                    }
                
            }
            
        }
    }
    
    
    //progress updated according to upload manager
    func onProgressUpdated(withNotification notification : NSNotification){
        
        if let info = notification.userInfo as? Dictionary<String, Any>
        {
            if let step_number = info["step_number"] as? String
            {
                
                    let uploadManager = UploadsManager.sharedInstance
                    if let step:Dictionary<String, Any> = uploadManager.onboardingSteps[step_number] as? Dictionary<String, Any>
                    {
                        if let started = step["started"] as? Bool, let finished = step["finished"] as? Bool, let progress = step["progress"] as? Float
                        {
                            if started && !finished
                            {
                                if let _ = self.uploadStepsBars[step_number]
                                {
                                    DispatchQueue.main.async(execute: {
                                        self.uploadStepsBars[step_number]?.isHidden = false
                                        self.uploadStepsBars[step_number]?.set(progress: Double(progress), duration: 0.0)
                                        if progress >= 1.0
                                        {
                                            self.uploadStepsBars[step_number]?.isHidden = true
                                        }
                                    })
                                }
                            }
                        }
                        
                    }
                
            }
        }
        
    }
    
    private func configureCircularProgress(progress: Double, progressBar: KYCircularProgress) {
       
        if(progress >= 1.0)
        {
          progressBar.isHidden = true
          return
        }
        
        progressBar.showGuide = true
        //progressBar.colors = [UIColor(rgba: 0xA6E39DAA), UIColor(rgba: 0xAEC1E3AA), UIColor(rgba: 0xAEC1E3AA), UIColor(rgba: 0xF3C0ABAA)]
        progressBar.colors = [UIColor(rgba: 0x000000FF), UIColor(rgba: 0xFFFFFFFF)]
        
//        let labelWidth = CGFloat(80.0)
//        let textLabel = UILabel(frame: CGRect(x: (view.frame.width - labelWidth) / 2, y: (view.frame.height - labelWidth) / 4, width: labelWidth, height: 32.0))
//        textLabel.font = UIFont(name: "HelveticaNeue", size: 24)
//        textLabel.textAlignment = .center
//        textLabel.textColor = .green
//        textLabel.alpha = 0.3
        progressBar.set(progress: progress, duration: 0.0)
//        progressBar.addSubview(textLabel)
        
        progressBar.progressChanged {
            (progress: Double, circularProgress: KYCircularProgress) in
//            DispatchQueue.main.async(execute: {
//                print("progress: \(progress)")
//                textLabel.text = String.init(format: "%.2f", progress * 100.0) + "%"
//            })
        }
    }
    
    private func configureAllProgressBars()
    {
        let steps_array = ["1", "2", "3", "4", "6"]
        
        let uploadsManager = UploadsManager.sharedInstance
        for (_, step_number) in  steps_array.enumerated()
        {
            if let step:Dictionary = uploadsManager.onboardingSteps[step_number] as? Dictionary<String, Any>
            {
                if let progress = step["progress"] as? Float
                 {
                    if let progressBar = self.uploadStepsBars[step_number]
                    {
                        DispatchQueue.main.async(execute: {
                            self.configureCircularProgress(progress: Double(progress), progressBar: progressBar)
                        })
                    }
                    
                 }
            }
        }

    
    }
    
    
    //step been finished (upon message from upload manager)
    func runFinishHandler(success:Bool, message: String, step_number: String ){
        
        print("Step had finished: \(step_number)")
        
        DispatchQueue.main.async(execute: {
            self.uploadStepsBars[step_number]?.isHidden = true
        })
            
        let dataManager = DataManager.sharedInstance
        if(success)
        {
            
            if let _ =  dataManager.onboarding_info[step_number]{
                dataManager.onboarding_info[step_number] = ["step_status":"PASSED"]
                registration_info[step_number] = ["step_status":"PASSED"]
                DispatchQueue.main.async(execute: {
                
                    if OnboardingSummary.numberOfStepsFinished() >= 8 {
                        self.nextButton.setTitle("REFRESH", for: .normal)
                        self.nextButton.setTitle("REFRESH", for: .highlighted)
                    }

                    self.showSteps() //update steps
                })
                
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
        
    }

    //restart all uploading sessions
    func restartUploads()
    {
        let steps_array = ["1", "2", "3", "4", "6"]
        
        let uploadsManager = UploadsManager.sharedInstance
        for (_, step_number) in  steps_array.enumerated()
        {
            if let step:Dictionary = uploadsManager.onboardingSteps[step_number] as? Dictionary<String, Any>
            {
                var step_session = step
                print("Onboarding step: \(step_number) had staus started (on restart): \(String(describing: step["started"])), finished: \(String(describing: step["finished"])), progress: \(String(describing: step["progress"])), active: \(String(describing: step["active"]))")
                if let started = step["started"] as? Bool, let finished = step["finished"] as? Bool, let active = step["active"] as? Bool
                {
                    //step been started but not finished - so we need to restart it
                    if started && !finished  && !active
                    {
                        //parameters
                        if let image = ImageCache.default.retrieveImageInDiskCache(forKey: "onboarding_step_\(step_number)", options: nil)
                        {
                            print("Retrieved image for step: \(step_number)")
                            let parameters = [
                                "session_id": dataManager.user.SIDunaccepted as Any,
                                "image": image as Any
                            ]
                            
                            //start uploading(
                            let pathFile = ImageCache.default.cachePath(forComputedKey: "onboarding_step_\(step_number)")
                            uploadsManager.postFormData(parameters: parameters, urlstring: "/users/registerDriver/\(step_number)", step_number: step_number, pathFile: pathFile)
                        }
                        else
                        {
                          print("Hadn't retrieved cached image: onboarding_image_\(step_number)")
                           step_session["started"] = false
                          step_session["progress"] = 0.0
                          uploadsManager.onboardingSteps[step_number] = step_session
                          uploadsManager.storeOnboardingStep(step_number: step_number)
                            DispatchQueue.main.async(execute: {
                            self.uploadStepsBars[step_number]?.isHidden = true
                            })
                        }
                    }
                    else if !active
                    {
                        DispatchQueue.main.async(execute: {
                            self.uploadStepsBars[step_number]?.isHidden = true
                        })
                    }
                }
            }
        }

    }
    
}


extension Dictionary {
    
    mutating func merge(with dictionary: Dictionary) {
        dictionary.forEach { updateValue($1, forKey: $0) }
    }
    
    func merged(with dictionary: Dictionary) -> Dictionary {
        var dict = self
        dict.merge(with: dictionary)
        return dict
    }
}

