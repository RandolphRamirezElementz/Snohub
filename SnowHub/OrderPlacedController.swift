//
//  OrderPlacedController.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/11/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class OrderPlacedController: UIViewController {

    @IBOutlet weak var orderButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationBar!
    //@IBOutlet weak var waitingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true

        //set up cancel order button
       
    }

    override func viewWillAppear(_ animated: Bool) {

        //add observer for orderStatusChanged
        NotificationCenter.default.removeObserver(self, name: .onOrderStatusChnaged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrderStatusCnahged(withNotification:)), name: .onOrderStatusChnaged, object: nil)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .onOrderStatusChnaged, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func checkOrderStatus()
    {
        let dataManager:DataManager = DataManager.sharedInstance
        if(!(dataManager.wsclient?.socketConnected)!)
        {
            dataManager.openSocketConnection()
        }
        //dataManager.getOrderStatus(id: dataManager.order.id, completionCallback: { (success, message) in
           //do nothing for now
           //print("Order: \(dataManager.order)")
           if(dataManager.order.orderStatus == .ACCEPTED)
           {
             //then it was accepted 
             dataManager.setUserPreferences() //save order details with driver info
             DispatchQueue.main.async(execute: {
                self.performSegue(withIdentifier: "goToAcceptedOrder", sender:self) //go to next stage
             })
           }
        
          if(dataManager.order.orderStatus == .CANCELLED)
          {
            let alert = UIAlertController(title: "Order has been cancelled!", message: "Your order had been cancelled by driver or admin", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                DispatchQueue.main.async(execute: {
                    dataManager.order = Order()
                    dataManager.setUserPreferences()
                    self.performSegue(withIdentifier: "goBackToMap", sender: self)
                })
             }))
            
            DispatchQueue.main.async(execute: {
                   self.present(alert, animated: true, completion: nil)
            })
            
          }

        
        //})
        
    }
    
    @IBAction func cancelOrder(){
        
        let dataManager:DataManager = DataManager.sharedInstance
        
        if( dataManager.order.address != "" && dataManager.user.SID != ""){
            
            dataManager.canselOrder(id: dataManager.order.id, completionCallback: {(success, message) in
                if(success)
                {
                    dataManager.order = Order()
                    dataManager.setUserPreferences() //save cleared order
                        
                    DispatchQueue.main.async(execute: {
                        self.performSegue(withIdentifier: "goBackToMap", sender:self) //go to next stage
                    })
                }
                else
                {
                    let alert = UIAlertController(title: "Error", message: message == "" ? "Some error happened while cancelling your order. Check your order details and Internet connection" : message , preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    
                    DispatchQueue.main.async(execute: {
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                
            })
        }
        else
        {
            let alert = UIAlertController(title: "Error", message: "Your login or order info is incorrect.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func goBackToMap(){
      self.performSegue(withIdentifier: "goBackToMap", sender:self) //go to next stage
        
    }

    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
    }
    
    func onOrderStatusCnahged(withNotification notification : NSNotification)
    {
        print("ORDER STATUS CHANGED : NOTIFICATION CAME")
        checkOrderStatus()
    }


}
