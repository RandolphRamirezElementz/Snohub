//
//  MyEarningsController.swift
//  SnowHub
//
//  Created by Liubov on 12/21/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class MyEarningsController: UIViewController {

    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var headerLabel: UILabel!
 
    //earnings text labels
    @IBOutlet weak var totalChargeAmount: UILabel!
    @IBOutlet weak var totalService: UILabel!
    @IBOutlet weak var currentService: UILabel!
    @IBOutlet weak var dislikesNumber: UILabel!
    @IBOutlet weak var likesNumber: UILabel!
    
    
    var dataManager = DataManager.sharedInstance

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        
        dataManager.getOwnOrders(is_driver: (self.dataManager.user.isDriver ? "true" : "false"), completionCallback: { (allOrders) in
            print("All orders count: \(allOrders.count)")
            
            var totalService = 0.0
            var totalSnohubFee = 0.0
            var totalChargeAmount = 0.0
            
            var currentService = 0.0
            var currentSnohubFee = 0.0
            var currentChargeAmount = 0.0
            
            var dislikes = 0
            var likes = 0
            
            if(allOrders.count > 0)
            {
                for(_, order)in allOrders.enumerated()
                {
                    if(order["status"] as? Int == 3)
                    {
                        if let _ = order["driver_fee"] as? Double
                        {
                           totalService += order["driver_fee"] as! Double
                        }
                     
                        if let _ = order["credit_driver_fee"] as? Double
                        {
                            totalService += order["credit_driver_fee"] as! Double
                        }
                        
                        if let _ = order["profit_fee"] as? Double
                        {
                            totalSnohubFee += order["profit_fee"] as! Double
                        }
                        
                        if let _ = order["order_price"] as? Double,  let _ = order["tax"] as? Double
                        {
                            let total_price = order["order_price"] as! Double
                            let tax = order["tax"] as! Double
                            totalChargeAmount += total_price - tax
                        }
                    }
                    else
                    {
                        if let _ = order["driver_fee"] as? Double
                        {
                            currentService += order["driver_fee"] as! Double
                        }
                        
                        if let _ = order["profit_fee"] as? Double
                        {
                            currentSnohubFee += order["profit_fee"] as! Double
                        }
                        
                        if let _ = order["order_price"] as? Double,  let _ = order["tax"] as? Double
                        {
                            let total_price = order["order_price"] as! Double
                            let tax = order["tax"] as! Double
                            currentChargeAmount += total_price - tax
                        }

                    }
                    
                   if let rate = order["driver_rate_by_user"] as? Int
                   {
                     if rate < 0
                     {
                       dislikes += 1
                     }
                     else if rate > 0
                     {
                       likes += 1
                     }
                   }
                }
                  DispatchQueue.main.async(execute: {
                   
                    self.currentService.text = String.localizedStringWithFormat("$%.2f", currentService)
                    self.totalChargeAmount.text = String.localizedStringWithFormat("$%.2f", totalService )
                    self.totalService.text = String.localizedStringWithFormat("$%.2f", totalService)
                    self.dislikesNumber.text = String(dislikes)
                    self.likesNumber.text = String(likes)
    
                  })

            }
            
           
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
