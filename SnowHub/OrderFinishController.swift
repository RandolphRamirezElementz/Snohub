//
//  OrderFinishController.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/4/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit
import Stripe

class OrderFinishController: UIViewController {

    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var minFareView: UIView!
    @IBOutlet weak var warningView: UIView!
    
    
    @IBOutlet weak var fourLabel: UILabel!
    @IBOutlet weak var fourLabelmark: UIImageView!
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    //constraints for order details form
    @IBOutlet weak var viewHeightConstraint: NSLayoutConstraint!
    
    //agree checkbox
    @IBOutlet weak var agreeCheck: CheckBoxButton!
    @IBOutlet weak var agreeLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    
    
    //prices numbers
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var showelingPriceLabel: UILabel!
    @IBOutlet weak var saltPriceLabel: UILabel!
    @IBOutlet weak var markingPriceLabel: UILabel!
    @IBOutlet weak var taxLabel: UILabel!
    @IBOutlet weak var subTotal: UILabel!
    
    @IBOutlet weak var debtLabel: UILabel!
    @IBOutlet weak var bonusLabel: UILabel!
    
    @IBOutlet weak var totalLabel: UILabel!
    
    //labels for prices
    @IBOutlet weak var snowDepthLabel: UILabel!
    @IBOutlet weak var showelingLabel: UILabel!
    @IBOutlet weak var taxPercentsLabel: UILabel!
    
    let dataManager:DataManager = DataManager.sharedInstance
    var settingsVC = SettingsViewController()
    
    let grayishColor = UIColor.init(red: 127.0/255.0, green: 169.0/255.0, blue: 203.0/255.0, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        orderButton.setTitleColor(UIColor.white, for: .highlighted)
        orderButton.setTitleColor(UIColor.white, for: .normal)
        
        locationView.layer.borderWidth = 1.0
        locationView.layer.cornerRadius = 7.0
        locationView.clipsToBounds = true
        locationView.layer.borderColor = UIColor.init(red: 146.0/255.0, green: 187.0/255.0, blue: 213.0/255.0, alpha: 1.0).cgColor
       
        detailsView.layer.borderWidth = 1.0
        detailsView.layer.cornerRadius = 7.0
        detailsView.clipsToBounds = true
        detailsView.layer.borderColor = UIColor.init(red: 146.0/255.0, green: 187.0/255.0, blue: 213.0/255.0, alpha: 1.0).cgColor

        minFareView.layer.borderWidth = 1.0
        minFareView.layer.cornerRadius = 7.0
        minFareView.clipsToBounds = true
        minFareView.layer.borderColor = UIColor.init(red: 146.0/255.0, green: 187.0/255.0, blue: 213.0/255.0, alpha: 1.0).cgColor

        warningView.layer.borderWidth = 1.0
        warningView.layer.cornerRadius = 7.0
        warningView.clipsToBounds = true
        warningView.layer.borderColor = UIColor.init(red: 146.0/255.0, green: 187.0/255.0, blue: 213.0/255.0, alpha: 1.0).cgColor

        
        addressLabel.text = dataManager.order.address
        
        
//        if !dataManager.order.otherIssues {
//            fourLabel.isHidden = true
//            fourLabelmark.isHidden = true
//            detailsView.isHidden = true
//        }
//        else
//        {
//          fourLabel.text = dataManager.order.issuesThere
//        }

         let pickList = dataManager.roadLengths
        
        //prices
        priceLabel.text = "$" + String.localizedStringWithFormat("%.2f", dataManager.order.plowing_price)
        showelingPriceLabel.text = "$" + String.localizedStringWithFormat("%.2f", dataManager.order.showeling_price)
        saltPriceLabel.text = "$" + String.localizedStringWithFormat("%.2f", dataManager.order.salt_price)
        markingPriceLabel.text = "$" + String.localizedStringWithFormat("%.2f", dataManager.order.marking_driveway_price)
        taxLabel.text = "$" + String.localizedStringWithFormat("%.2f", dataManager.order.tax)
        subTotal.text = "$" + String.localizedStringWithFormat("%.2f", (dataManager.order.price + dataManager.order.bonus))
        
        debtLabel.text = "$" + String.localizedStringWithFormat("%.2f", dataManager.order.debt)
        bonusLabel.text = "$" + String.localizedStringWithFormat("%.2f", dataManager.order.bonus)
        totalLabel.text = "$" + String.localizedStringWithFormat("%.2f", (dataManager.order.debt + dataManager.order.price))
        
        snowDepthLabel.text = "Based on \(dataManager.order.snow_depth) inches of snow and driveway length of \(pickList[dataManager.order.driveWayLength])"
        showelingLabel.text = "Shoveling \(dataManager.order.walkways_number) walkways"
        taxPercentsLabel.text = "TAX at " +  String.localizedStringWithFormat("%.2f", (dataManager.order.tax_percents*100.0)) + "%"
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
    
        //form warning link
        //let url = URL(string: dataManager.urlBase + "/orders/prices?session_id=\(dataManager.user.SID)")!
        let attributedString = NSMutableAttributedString(string: "Additional charges will be incurred if your snow is above 3 inches and your driveway is in excess of \(dataManager.roadLengths[dataManager.order.driveWayLength]).  For more information please click here to review our pricing policy")
    
        attributedString.setAsLink(textToFind: "click here", linkURL: dataManager.urlBase + "/orders/prices?session_id=\(dataManager.user.SID)")
        warningLabel.attributedText = attributedString
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
         orderButton.isEnabled = true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    //deprecated
    @IBAction func showSettings() {
        let navController = UINavigationController(rootViewController: settingsVC)
        self.present(navController, animated: true, completion: nil)
    }
    
    //switch agree
    @IBAction func agreeSwitch(){
        agreeCheck.switchButton()
        agreeLabel.textColor = agreeCheck.checked ? UIColor.white : grayishColor
    }

    
    
    @IBAction func goCharge(){
        
        if !agreeCheck.checked
        {
            let alert = UIAlertController(title: "Info", message: "You have to agree to pricing terms first", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil) )
           self.present(alert, animated: true, completion: nil)
           return
        }
        
        let alert = UIAlertController(title: "Info", message: "Please note, additional charges will be incurred if your snow is above 3 inches and your driveway is in excess of \(dataManager.roadLengths[dataManager.order.driveWayLength]).", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Proceed", style: UIAlertActionStyle.default, handler: {
            UIAlertAction in
            self.goCheckout() //go checkout your order
        }) )
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.default, handler: {
            UIAlertAction in
            //do nothing for now
        }) )
        alert.addAction(UIAlertAction(title: "Prices", style: UIAlertActionStyle.default, handler: {
            UIAlertAction in
            //go to prices
              self.performSegue(withIdentifier: "showPricesBeforeOrder", sender: self)
            
        }) )

        
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
        })
    }
    
    
  
   func goCheckout(){
        orderButton.isEnabled = false;
        let dataManager:DataManager = DataManager.sharedInstance
     
        if(dataManager.order.serviceNow && (dataManager.order.debt + dataManager.order.price) > 0) //we charge if service now and price is bigger than 0 (that can happen if there's enough promo discounts)
        {
            let product = "Snowplowing at " + dataManager.order.address
            let price = dataManager.order.price + dataManager.order.debt
            print("Settings: \(self.settingsVC.settings)")
            let checkoutViewController = CheckoutViewController(product: product,
                                                                price: price,
                                                                settings: self.settingsVC.settings)
            print("checkoutViewController created")
            let navController = UINavigationController(rootViewController: checkoutViewController)
            self.present(navController, animated: true, completion: nil)
        }
       
        else //we don't charge if service not now
        {
          let stripeAPIClient = StripeAPIClient.sharedClient
          stripeAPIClient.baseURLString = dataManager.urlBase
          stripeAPIClient.completeCharge(nil, amount: 0, completion: { (error) in
            
               if(error != nil)
               {
                
                let message = error?.localizedDescription ?? ""
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                 DispatchQueue.main.async(execute: {
                    self.orderButton.isEnabled = true
                    self.present(alert, animated: true, completion: nil)
                  })
               }
               else{ //charge successful
                DispatchQueue.main.async(execute: {
                    self.performSegue(withIdentifier: "goToOrderFinish", sender:self) //go to next stage
                })
               }
            
          })
        }
    }
    
    @IBAction func goToOrder(){
        
        
    }

}

extension NSMutableAttributedString {
    
    public func setAsLink(textToFind:String, linkURL:String) {
        
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(NSLinkAttributeName, value: linkURL, range: foundRange)
        }
    }
}
