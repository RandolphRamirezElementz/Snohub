//
//  OrderCloseController.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/21/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class OrderCloseController: UIViewController {

    @IBOutlet weak var closeOrderButton: BorderedButton!
    @IBOutlet weak var nextItem: UIBarButtonItem!
    
    @IBOutlet weak var driversEstimate: UITextField!
    @IBOutlet weak var pendingLabel: UILabel!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var captureProcessing: UIActivityIndicatorView!
    
    var dataManager:DataManager = DataManager.sharedInstance
    var currentOrder:Order!
    
    let backendBaseURL: String? = DataManager.sharedInstance.urlBase
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let driver_profit = dataManager.takenOrder.driver_fee + dataManager.takenOrder.debt
        print("Driver pending debt - \(dataManager.takenOrder.debt)")
        print("Debt: \(currentOrder.debt)")
        self.pendingLabel.text = "Pending: $" + String.localizedStringWithFormat("%.2f", currentOrder.debt )
        self.driversEstimate.text = String.localizedStringWithFormat("%.2f", driver_profit)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func closeOrder(){
        
        self.captureProcessing.startAnimating()
        self.closeOrderButton.isEnabled = false
                //capture funds
                print("Going capture charge for some money")
                StripeAPIClient.sharedClient.baseURLString = self.backendBaseURL
        
                StripeAPIClient.sharedClient.captureFunds(completion: { (error) in
                  if(error == nil)
                  {
                    self.dataManager.takenOrder.orderStatus = .FINISHED
                    self.dataManager.setUserPreferences()
                    
                    DispatchQueue.main.async(execute: {
                        self.captureProcessing.stopAnimating()
                        self.performSegue(withIdentifier: "goRateCustomer", sender:self) //go to next stage
                    })
                  }
                  else
                  {
                    //nullify order
                    self.dataManager.takenOrder = Order()
                    self.dataManager.setUserPreferences()
                    
                    let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                        DispatchQueue.main.async(execute: {
                            self.performSegue(withIdentifier: "orderClosedGoToMap", sender: self)
                        })
                    }))
                    
                    DispatchQueue.main.async(execute: {
                        self.captureProcessing.stopAnimating()
                        self.present(alert, animated: true, completion: nil)
                    })
                  }

                })


    
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

}
