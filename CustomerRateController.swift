//
//  CustomerRateController.swift
//  SnowHub
//
//  Created by Liubov Perova on 12/12/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class CustomerRateController: UIViewController {

    @IBOutlet weak var rateButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var customerNameLabel : UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    //star buttons
    @IBOutlet weak var star1Button: UIButton!
    @IBOutlet weak var star2Button: UIButton!
    @IBOutlet weak var star3Button: UIButton!
    @IBOutlet weak var star4Button: UIButton!
    @IBOutlet weak var star5Button: UIButton!
    
    //gesture recognizers
    @IBOutlet weak var rateDownTap: UITapGestureRecognizer!
    @IBOutlet weak var rateUpTap: UITapGestureRecognizer!
    
    //button views
    @IBOutlet weak var upRateView: UIView!
    @IBOutlet weak var downRateView: UIView!
    
    var rateButtons: [UIButton] = []
    var dataManager = DataManager.sharedInstance
    var rating = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        rateButtons = [star1Button, star2Button, star3Button, star4Button, star5Button]
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        
    
        let fullName    = dataManager.takenOrder.client_name
        let fullNameArr = fullName.components(separatedBy: " ")
        
        let name = fullNameArr[0]
        self.customerNameLabel.text = "Rate \(name)"
        
        let driver_profit = dataManager.takenOrder.driver_fee + dataManager.takenOrder.debt
        self.priceLabel.text = "$" + String.localizedStringWithFormat("%.2f", driver_profit )
        
        self.upRateView.layer.borderColor = UIColor(red:(68.0/255.0), green:(68.0/255.0), blue:(68.0/255.0), alpha:0.18).cgColor
        self.downRateView.layer.borderColor = UIColor(red:(68.0/255.0), green:(68.0/255.0), blue:(68.0/255.0), alpha:0.18).cgColor

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //deprecated
    @IBAction func drawRate(withSender sender: UIButton)
    {
        for (_, button) in rateButtons.enumerated() {
            button.setImage(UIImage(named: "star_grey"), for: .normal)
            button.setImage(UIImage(named: "star_grey"), for: .highlighted)
        }
        
        switch sender {
        case star1Button:
            rating = 1
            showRate(rate: 1)
            break
        case star2Button:
            rating = 2
            showRate(rate: 2)
            break
        case star3Button:
            rating = 3
            showRate(rate: 3)
            break
        case star4Button:
            rating = 4
            showRate(rate: 4)
            break
        case star5Button:
            rating = 5
            showRate(rate: 5)
            break
        default: break
            
        }
        
    }
    
    //deprecated
    func showRate(rate: Int)
    {
        for (index, button) in rateButtons.enumerated() {
            if(index < rate)
            {
                button.setImage(UIImage(named: "star_orange"), for: .normal)
                button.setImage(UIImage(named: "star_orange"), for: .highlighted)
            }
        }
        
    }
    
    @IBAction func goBackToMap(){
        
        self.dataManager.takenOrder = Order()
        self.dataManager.setUserPreferences()
        
        self.performSegue(withIdentifier: "customerRatedGoBackToMap", sender:self) //go to next stage
    }
    
    
    @IBAction func rateCompletedOrder(sender: UITapGestureRecognizer)
    {
        if sender == rateUpTap
        {
            rating = 1
        }
        else if sender == rateDownTap
        {
            rating = -1
        }
        
        dataManager.rateOrder(rate: rating, is_driver: "true", order_id: 0) { (success, error) in
            
            self.dataManager.takenOrder = Order()
            self.dataManager.setUserPreferences()
            if(success)
            {
                print("ORDER HAD BEEEN RATED SUCCESSFULLY")
            }
            else
            {
                print("ERROR RATING ORDER: \(error)")
            }
            
            DispatchQueue.main.async(execute: {
                self.performSegue(withIdentifier: "customerRatedGoBackToMap", sender: self)
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

}
