//
//  OrderAcceptedController.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/16/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit
import AVFoundation

class OrderAcceptedController: UIViewController {

    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var carNameLabel: UILabel!
    @IBOutlet weak var ETALabel: UILabel!
    @IBOutlet weak var ETADateLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var depthLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var waitingWheel: UIActivityIndicatorView!
    @IBOutlet weak var driver_icon: UIImageView!
    @IBOutlet weak var vehicle_icon: UIImageView!
    
    @IBOutlet weak var order_before_icon: UIImageView!
    @IBOutlet weak var order_after_icon: UIImageView!

    
    var previousOrderState:Status = .NEW
    var dataManager:DataManager = DataManager.sharedInstance
    var pictures_came = [false,false,false,false]
    var eta_set = false;
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        
        self.priceLabel.text = "$" + String.localizedStringWithFormat("%.2f", dataManager.order.price) //"\(dataManager.order.price)"
        // Do any additional setup after loading the view.
        if(dataManager.order.driver_Name != "" && dataManager.order.driver_id != 0)
        {
          nameLabel.text = dataManager.order.driver_Name
          carNameLabel.text = dataManager.order.car_Name
        }
        
        self.waitingWheel.startAnimating()
        
        if(vehicle_icon != nil){
            vehicle_icon.layer.borderWidth = 0.0
            vehicle_icon.layer.cornerRadius = 49.0
            vehicle_icon.clipsToBounds = true
            vehicle_icon.layer.masksToBounds = true
        }
        
        if(driver_icon != nil){
            driver_icon.layer.borderWidth = 0.0
            driver_icon.layer.cornerRadius = 49.0
            driver_icon.clipsToBounds = true
            driver_icon.layer.masksToBounds = true
        }
        
        //check order status every 3 seconds
        setEta()
        checkOrderStatus()
       
    }

    override func viewWillAppear(_ animated: Bool) {
        
        //add observer for orderStatusChanged
        NotificationCenter.default.removeObserver(self, name: .onOrderStatusChnaged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrderStatusCnahged(withNotification:)), name: .onOrderStatusChnaged, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .onOrderStatusChnaged, object: nil)
    }

    
    func setEta()
    {
        if(eta_set)
        {
            return
        }
        
        let dataManager:DataManager = DataManager.sharedInstance
        if(dataManager.order.eta != nil)
        {
            print(dataManager.order.eta ?? "")
            if let _ = dataManager.order.eta as Date?
            {
                let calendar = Calendar.current
                let comp = calendar.dateComponents([.hour, .minute, .year, .day], from: dataManager.order.eta!)
                if(comp.year == 0 && comp.day == 0)
                {
                    //keep waiting
                }
                else
                {
                    DispatchQueue.main.async(execute: {
                        let dateFormatter = DateFormatter()
                        
                        dateFormatter.dateFormat = "HH:mm"
                        self.ETALabel.text = dateFormatter.string(from: dataManager.order.eta!)
                        
                        dateFormatter.dateFormat = "MM/dd/yyyy"
                        self.ETADateLabel.text = dateFormatter.string(from: dataManager.order.eta!)
                        
                        self.waitingWheel.stopAnimating()
                        self.waitingWheel.isHidden = true
                        self.eta_set = true
                        dataManager.setUserPreferences() //save an updated order
                        
                    })
                }
            }
        }

    
    }
    
    func checkOrderStatus()
    {
        let dataManager:DataManager = DataManager.sharedInstance
        
        
        if(!(dataManager.wsclient?.socketConnected)!)
        {
          dataManager.openSocketConnection()
        }

        if(dataManager.orderStatusChanged)
        {
           dataManager.orderStatusChanged = false
            if dataManager.soundsOn
            {
              self.playSound(type: "thecalling")
            }
        }
        
        if(dataManager.order.actual_snow_depth > 0)
        {
            self.depthLabel.text = "Based on \(dataManager.order.actual_snow_depth)\" snow"
        }
        
        if(dataManager.etaChanged)
        {
          dataManager.etaChanged = false
          if dataManager.soundsOn
          {
           self.playSound(type: "thecalling")
          }
        }
        
        self.priceLabel.text = "$" + String.localizedStringWithFormat("%.2f", (dataManager.order.price + dataManager.order.debt))
        //var previousOrderState = 0
        //dataManager.getOrderStatus(id: dataManager.order.id, completionCallback: { (success, message) in
        
            print("Order: \(dataManager.order)")
            if(dataManager.order.orderStatus == .ACCEPTED)
            {
               //check what ETA is in order 
               self.setEta()
                
            }
            if(dataManager.order.orderStatus == .IN_PROGRESS)
            {
               self.statusLabel.text = "Driver has started working"
               nameLabel.text = dataManager.order.driver_Name
               carNameLabel.text = dataManager.order.car_Name

            }
            if(dataManager.order.orderStatus == .FINISHED)
            {
                
                let alert = UIAlertController(title: "Order has been completed!", message: "Would you like to rate the service provider?", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "YES", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                    DispatchQueue.main.async(execute: {
                        self.performSegue(withIdentifier: "orderCompletedGoRate", sender: self)
                    })
                }))
                alert.addAction(UIAlertAction(title: "NO", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                    DispatchQueue.main.async(execute: {
                        self.dataManager.order = Order()
                        self.dataManager.setUserPreferences()
                        self.performSegue(withIdentifier: "orderCompletedGoToMap", sender: self)
                    })
                }))
               
                DispatchQueue.main.async(execute: {
                   self.present(alert, animated: true, completion: nil)
                })

             }
        
            if(dataManager.order.orderStatus == .CANCELLED)
            {
            
            let alert = UIAlertController(title: "Order has been cancelled!", message: "Your order had been cancelled by driver or admin", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                DispatchQueue.main.async(execute: {
                    self.dataManager.order = Order()
                    self.dataManager.setUserPreferences()
                    self.performSegue(withIdentifier: "orderCompletedGoToMap", sender: self)
                })
            }))
            
            DispatchQueue.main.async(execute: {
                
                self.present(alert, animated: true, completion: nil)
            })
            
           }
        
        if (dataManager.order.driver_image != "" && dataManager.order.driver_image != "null" && !pictures_came[0])
        {
            self.load_image(urlString: dataManager.urlBase + "/" + dataManager.order.driver_image, type: 1)
        }
        if (dataManager.order.car_image != "" && dataManager.order.car_image != "null" && !pictures_came[1])
        {
            self.load_image(urlString: dataManager.urlBase + "/" + dataManager.order.car_image, type: 2)
        }
        if (dataManager.order.order_image_before != "" && dataManager.order.order_image_before != "null" && !pictures_came[2])
        {
            self.load_image(urlString: dataManager.urlBase + "/" + dataManager.order.order_image_before, type: 3)
        }
        if (dataManager.order.order_image_after != "" && dataManager.order.order_image_after != "null" && !pictures_came[3])
        {
            self.load_image(urlString: dataManager.urlBase + "/" + dataManager.order.order_image_after, type: 4)
        }
        
        previousOrderState = dataManager.order.orderStatus
        //})
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func makeCall()
    {
     print("driver_phone: \(dataManager.order.driver_phone)")
     if(dataManager.order.driver_phone != "")
     {
        if let phoneCallURL:NSURL = NSURL(string: "tel://\(dataManager.order.driver_phone)") {
            print("making call \(phoneCallURL)")
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL as URL)) {
                application.openURL(phoneCallURL as URL);
            }
        }
     }
    
    }
    
        
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    
    }
    
    
    func onOrderStatusCnahged(withNotification notification : NSNotification)
    {
        print("ORDER STATUS CHANGED : NOTIFICATION CAME")
        checkOrderStatus()
    }
    
    //play sound
    func playSound(type: String)
    {
        if let soundURL = Bundle.main.url(forResource: type, withExtension: "m4r") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            // Play
            AudioServicesPlaySystemSound(mySound);
        }
    }

    
    func load_image(urlString:String, type: Int)
    {
        print("getting image from URL: \(urlString)")
        let imgURL: NSURL = NSURL(string: urlString)!
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            if let imageData = NSData(contentsOf: imgURL as URL) as NSData?
            {
                let imageView = UIImageView(frame: CGRect(x:0, y:0, width:200, height:200))
                imageView.center = self.view.center
                
                // When from background thread, UI needs to be updated on main_queue
                DispatchQueue.main.async {
                    let image = UIImage(data: imageData as Data)
                    if (image != nil)
                    {
                        switch type {
                        case 1:
                            self.driver_icon.image = image
                            self.pictures_came[0] = true
                            break
                        case 2:
                            self.vehicle_icon.image = image
                             self.pictures_came[1] = true
                            break
                        case 3:
                            self.order_before_icon.image = image
                             self.pictures_came[2] = true
                            break
                        case 4:
                            self.order_after_icon.image = image
                             self.pictures_came[3] = true
                            break
                        default: break
                            
                        }
                    }
                    
                }
            }
        }
        
    }

}
