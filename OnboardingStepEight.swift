//
//  OnboardingStepEight.swift
//  SnowHub
//
//  Created by Liubov Perova on 4/26/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit

class OnboardingStepEight: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet weak var waitingWheel: UIActivityIndicatorView!
    @IBOutlet var agreementPage: UIWebView!
    
    var dataManager:DataManager = DataManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        
        
        //load webpage to webview
        agreementPage.delegate = self
        let url = URL(string: dataManager.urlBase + "/users/getAgreement?session_id=\(dataManager.user.SID)")!
        agreementPage.loadRequest(URLRequest(url: url))
        waitingWheel.startAnimating()
        nextButton.isEnabled = false
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       
        self.navigationController?.isNavigationBarHidden = true
        
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
         nextButton.isEnabled = true
         waitingWheel.stopAnimating()
         waitingWheel.isHidden = true
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func goBack(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func goNext(){
        
        let dataManager:DataManager = DataManager.sharedInstance
        
            nextButton.isEnabled = false
            waitingWheel.isHidden = false
            waitingWheel.startAnimating()
            nextButton.isEnabled = false
            
            dataManager.registerSendAgreementDriver(agreed: true, completionCallback: { (success, message) in
                
                DispatchQueue.main.async(execute: {
                    self.nextButton.isEnabled = true
                    self.waitingWheel.stopAnimating()
                    self.waitingWheel.isHidden = true
                })
                
                if(success)
                {
                    DispatchQueue.main.async(execute: {
                        dataManager.onboarding_info["8"] = ["step_status":"PASSED","agreed":true]
                        self.performSegue(withIdentifier: "goToSummary", sender:self) //go to next stage
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


    
}
