//
//  MyOrderDetailsController.swift
//  SnowHub
//
//  Created by Liubov Perova on 12/20/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class MyOrderDetailsController: UIViewController {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var carNameLabel: UILabel!
    @IBOutlet weak var ETALabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var roadLengthLabel: UILabel!
    @IBOutlet weak var snowDepthLabel: UILabel!
    @IBOutlet weak var timeSpentLabel: UILabel!
    
    //images container views
    @IBOutlet weak var userPicView: RoundImageView!
    @IBOutlet weak var userVehicleView: RoundImageView!
    @IBOutlet weak var uderPicBorder: NSLayoutConstraint!
    
    
    @IBOutlet weak var driver_icon: UIImageView!
    @IBOutlet weak var vehicle_icon: UIImageView!
    
    @IBOutlet weak var order_before_icon: UIImageView!
    @IBOutlet weak var order_after_icon: UIImageView!

    //bordered views 
    @IBOutlet weak var timeChargeView: UIView!
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var roadLengthView: UIView!
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var headerBackLabel: UILabel!

    
    //details view constraints and elements
    @IBOutlet weak var firstConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondConstraint: NSLayoutConstraint!
    @IBOutlet weak var thirdConstraint: NSLayoutConstraint!
    @IBOutlet weak var fourthConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var firstLabelmark: UIImageView!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var secondLabelmark: UIImageView!
    @IBOutlet weak var thirdLabel: UILabel!
    @IBOutlet weak var thirdLabelmark: UIImageView!
    @IBOutlet weak var notesText:UITextView!
    @IBOutlet weak var fourLabelmark: UIImageView!
    @IBOutlet weak var deicingLabel:UILabel!
    @IBOutlet weak var deicingLabelmark: UIImageView!
    @IBOutlet weak var fifthLabel: UILabel!
    @IBOutlet weak var fifthLabelmark: UIImageView!
    @IBOutlet weak var sixthLabel: UILabel!
    @IBOutlet weak var sixthLabelmark: UIImageView!
    @IBOutlet weak var seventhLabel: UILabel!
    @IBOutlet weak var seventhLabelmark: UIImageView!
    @IBOutlet weak var fifthConstraint: NSLayoutConstraint!
    @IBOutlet weak var sixthConstraint: NSLayoutConstraint!
    @IBOutlet weak var seventhConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollHeightConstraint: NSLayoutConstraint!
    
    //gesture recognizers
    @IBOutlet weak var rateDownTap: UITapGestureRecognizer!
    @IBOutlet weak var rateUpTap: UITapGestureRecognizer!
    
    //button views
    @IBOutlet weak var upRateView: UIView!
    @IBOutlet weak var downRateView: UIView!

    
    var dataManager:DataManager = DataManager.sharedInstance
    var currentOrder: Dictionary<String,Any?>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if dataManager.user.isDriver
        {
          headerBackLabel.text = "My Jobs"
        }
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        navigationBar.layer.masksToBounds = false;
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 8);
        navigationBar.layer.shadowRadius = 5;
        navigationBar.layer.shadowOpacity = 0.3;

        self.timeChargeView.makeBorder()
        self.locationView.makeBorder()
        self.roadLengthView.makeBorder()
        self.detailsView.makeBorder()
        
        print("Curent order passed to controller: \(String(describing: currentOrder))")
        
        if let price = self.currentOrder?["order_price"] as? Double
        {
          self.priceLabel.text = "$" + String.localizedStringWithFormat("%.2f", price) //"\(dataManager.order.price)"
            if let credit_price = self.currentOrder?["debt"] as? Double
            {
               self.priceLabel.text = "$" + String.localizedStringWithFormat("%.2f", (price + credit_price))
            }
        }
        
        if(dataManager.user.isDriver)
        {
          if let price = self.currentOrder?["driver_fee"] as? Double
           {
            self.priceLabel.text = "$" + String.localizedStringWithFormat("%.2f", price) //"\(dataManager.order.price)"
            if let credit_price = self.currentOrder?["credit_driver_fee"] as? Double
            {
                self.priceLabel.text = "$" + String.localizedStringWithFormat("%.2f", (price + credit_price))
            }
           }
        }

        
        if(!dataManager.user.isDriver)
        {
            
            if let status = self.currentOrder?["status"] as? Int
            {
                print("STATUS: \(status)")
                if(status == 0 || status == Status.SCHEDULED.rawValue)
                {
                  self.cancelButton.isHidden = false
                  if(Status(rawValue: status) == .SCHEDULED)
                  {
                    self.cancelButton.setTitle("CANCEL SUBSCRIPTION", for: .normal)
                    self.cancelButton.setTitle("CANCEL SUBSCRIPTION", for: .highlighted)
                  }
                    
                }
            }
        }

        
        //driver name
        if let name = self.currentOrder?["name"] as? String
        {
            if let driver_id = self.currentOrder?["driver_id"] as? Int
            {
                if(driver_id != 0)
                {
                   nameLabel.text = name
                }
            }
        }
        
        //vehicle model
        if let _ = self.currentOrder?["vehicle_model"] as? String
        {
         carNameLabel.text = self.currentOrder?["vehicle_model"] as! String?
        }
        
        //eta
        if let timestring = self.currentOrder?["eta"] as? String
        {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            if let datePublished = dateFormatter.date(from: timestring){
                dateFormatter.dateFormat = "HH:mm"
                self.ETALabel.text = "ETA " + dateFormatter.string(from: datePublished)
           }
        }
        
        //time_stamp
        if let timestring = self.currentOrder?["created"] as? String
        {
           
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            if let datePublished = dateFormatter.date(from: timestring){
                dateFormatter.dateFormat = "MM/dd/yyyy"
                self.statusLabel.text = dateFormatter.string(from: datePublished)
            }
        }
        
        //time spent
        if let timestring = self.currentOrder?["in_progress"] as? String
        {
            if let finishstring = self.currentOrder?["done"] as? String
            {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                
                if let dateStart = dateFormatter.date(from: timestring), let dateFinish = dateFormatter.date(from: finishstring)
                {
                    self.timeSpentLabel.text = offsetFrom(from: dateStart, to: dateFinish)
                }
            }
        }
        
        
        
        
        //address
        if let address = self.currentOrder?["address"] as? String
        {
           self.addressLabel.text = address
        }
        
        //road length
        if let road_length = self.currentOrder?["road_length"] as? Int
        {
            let length_array = dataManager.roadLengths
            if(road_length >= 0 && road_length < 4)
            {
                self.roadLengthLabel.text = length_array[road_length]
            }
        }
        
        //actual road length
        if let actual_road_length = self.currentOrder?["actual_road_length"] as? Int
        {
            let length_array = dataManager.roadLengths
            if(actual_road_length >= 0 && actual_road_length < 4)
            {
                self.roadLengthLabel.text = length_array[actual_road_length]
            }
        }
        
        if let snow_depth = self.currentOrder?["actual_inches"] as? Int
        {
        
                self.snowDepthLabel.text = "Snow depth \(snow_depth)\" "
        }
        
        
        //icons
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
        
        if let vPicUrl = self.currentOrder?["vehicle_pic_url"] as? String
        {
            dataManager.load_image(urlString: vPicUrl,  handler: { (image) in
                if(image != nil)
                {
                    self.vehicle_icon.image = image
                }
            })
        }

        if let uPicUrl = self.currentOrder?["profile_pic_url"] as? String
        {
            dataManager.load_image(urlString: uPicUrl,  handler: { (image) in
                if(image != nil)
                {
                    self.driver_icon.image = image
                }
            })
        }
        
        if(self.currentOrder?["pic_before_url"] as? String != nil)
        {
            dataManager.load_image(urlString: (self.currentOrder?["pic_before_url"] as? String)!,  handler: { (image) in
                if(image != nil)
                {
                    self.order_before_icon.image = image
                }
            })
        }
        
        if(self.currentOrder?["pic_after_url"] as? String != nil)
        {
            dataManager.load_image(urlString: (self.currentOrder?["pic_after_url"] as? String)!,  handler: { (image) in
                if(image != nil)
                {
                    self.order_after_icon.image = image
                }
            })
        }
    
         setupDetails()
        
        self.upRateView.layer.borderColor = UIColor(red:(1.0), green:(1.0), blue:(1.0), alpha:0.18).cgColor
        self.downRateView.layer.borderColor = UIColor(red:(1.0), green:(1.0), blue:(1.0), alpha:0.18).cgColor

    }

    
    func setupDetails()
    {
        //initial constraints set
        viewHeightConstraint.constant = 44
        firstConstraint.constant = 8
        secondConstraint.constant = 8
        thirdConstraint.constant = 8
        fourthConstraint.constant = 8
        fifthConstraint.constant = 8
        sixthConstraint.constant = 8
        seventhConstraint.constant = 8
        scrollHeightConstraint.constant = 850

            
        if(currentOrder?["deicing"] as? Int != 0){
            deicingLabelmark.isHidden = false
            deicingLabel.isHidden = false
        }
        
        
        if let deicing = currentOrder?["deicing"] as? Int
        {
          if(deicing != 0)
          {
            deicingLabelmark.isHidden = false
            deicingLabel.isHidden = false

            firstConstraint.constant += 27
            secondConstraint.constant += 27
            thirdConstraint.constant += 27
            fourthConstraint.constant += 27
            viewHeightConstraint.constant += 27
            fifthConstraint.constant += 27
            sixthConstraint.constant += 27
            seventhConstraint.constant += 27
            scrollHeightConstraint.constant += 27

          }
        
        }
        
        if let d_marked = currentOrder?["driveway_marker"] as? Int
        {
            if(d_marked != 0){
                firstLabelmark.isHidden = false
                firstLabel.isHidden = false
                
                secondConstraint.constant += 27
                thirdConstraint.constant += 27
                fourthConstraint.constant += 27
                viewHeightConstraint.constant += 27
                fifthConstraint.constant += 27
                sixthConstraint.constant += 27
                seventhConstraint.constant += 27
                scrollHeightConstraint.constant += 27

                
            }
        }
        
        if let d_type = currentOrder?["driveway_type"] as? String
        {
            if(d_type == "a"){
                secondLabelmark.isHidden = false
                secondLabel.isHidden = false
                
                thirdConstraint.constant += 27
                fourthConstraint.constant += 27
                viewHeightConstraint.constant += 27
                fifthConstraint.constant += 27
                sixthConstraint.constant += 27
                seventhConstraint.constant += 27
                scrollHeightConstraint.constant += 27

            }
            
            if(d_type == "g"){
                thirdLabelmark.isHidden = false
                thirdLabel.isHidden = false
                fourthConstraint.constant += 27
                viewHeightConstraint.constant += 27
                fifthConstraint.constant += 27
                sixthConstraint.constant += 27
                seventhConstraint.constant += 27
                scrollHeightConstraint.constant += 27

            }
            
        }
        
        if let notes = currentOrder?["other_consideration"] as? String
        {
            if(notes != "" && notes != "<null>"){
                fourLabelmark.isHidden = false
                notesText.isHidden = false
                notesText.text = currentOrder?["other_consideration"] as? String
                
                viewHeightConstraint.constant += 27
                fifthConstraint.constant += 27
                sixthConstraint.constant += 27
                seventhConstraint.constant += 27
                scrollHeightConstraint.constant += 27
                
            }
        }
        
        if  let cfw = currentOrder?["clean_front_walkway"] as? Int
        {
            if cfw == 1
            {
                scrollHeightConstraint.constant += 27
                viewHeightConstraint.constant += 27
                sixthConstraint.constant += 27
                seventhConstraint.constant += 27
                fifthLabel.isHidden = false
                fifthLabelmark.isHidden = false
            }
            
        }
        
        if let cbw = currentOrder?["clean_back_walkway"] as? Int
        {
            if cbw == 1
            {
                scrollHeightConstraint.constant += 27
                viewHeightConstraint.constant += 27
                seventhConstraint.constant += 27
                sixthLabel.isHidden = false
                sixthLabelmark.isHidden = false
            }
        }
        
        if let csw = currentOrder?["clean_side_walkway"] as? Int
        {
            if csw == 1
            {
                scrollHeightConstraint.constant += 27
                viewHeightConstraint.constant += 27
                seventhLabel.isHidden = false
                seventhLabelmark.isHidden = false
            }
        }

        
        
        //remove unneeded info for driver (their clients are not drivers)
        if(dataManager.user.isDriver)
        {
           userVehicleView.isHidden = true
           uderPicBorder.constant = 65
            
        }
    
    }
    
    
    func offsetFrom(from:Date, to:Date) -> String {
        
        let dayHourMinuteSecond: Set<Calendar.Component> = Set<Calendar.Component>([.day, .hour, .minute, .second])
        let difference = NSCalendar.current.dateComponents(dayHourMinuteSecond, from: from, to: to)
        let seconds = String(difference.second! as Int) + "s"
        let minutes = String(difference.minute! as Int) + "m " + seconds
        let hours = String(difference.hour! as Int) + "h " + minutes
        let days = String(difference.day! as Int) + "d " + hours
        
        print("Time difference: \(days)")
        
        if difference.day!    > 0 { return days }
        if difference.hour!   > 0 { return hours }
        if difference.minute! > 0 { return minutes }
        if difference.second! > 0 { return seconds }
        return ""
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

    
    @IBAction func cancelOrder(){
        
        self.cancelButton.isEnabled = false
        
        if  let id = self.currentOrder?["id"] as? Int
        {
            
            self.dataManager.canselOrder(id: id, completionCallback: {(success, message) in
                DispatchQueue.main.async(execute: {
                    self.cancelButton.isEnabled = true
                })
                if(success)
                {
                    if(self.dataManager.order.id == id)
                    {
                      self.dataManager.order = Order()
                      self.dataManager.setUserPreferences() //save cleared order
                    }
                    DispatchQueue.main.async(execute: {
                        self.performSegue(withIdentifier: "goToOrderList", sender:self) //go to next stage
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
            let alert = UIAlertController(title: "Error", message: "Order info is incorrect, or you have no enough rights to cancel it", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
            })
        }
        
    }

    //rate
    @IBAction func rateCompletedOrder(sender: UITapGestureRecognizer)
    {
        var rating = 1
        if sender == rateDownTap
        {
            rating = -1
        }
        
        if  let id = self.currentOrder?["id"] as? Int
        {
            dataManager.rateOrder(rate: rating, is_driver: dataManager.user.isDriver ? "true" : "false", order_id: id) { (success, error) in
                
                self.dataManager.order = Order()
                self.dataManager.setUserPreferences()
                
                if(success)
                {
                    print("ORDER HAD BEEEN RATED SUCCESSFULLY")
                    let alert = UIAlertController(title: "You've rated the order successfully", message: "", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    DispatchQueue.main.async(execute: {
                        self.present(alert, animated: true, completion: nil)
                    })

                }
                else
                {
                    print("ERROR RATING ORDER: \(error)")
                    let alert = UIAlertController(title: "Error", message: "Your rate hadn't been accounted: \(error)", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    DispatchQueue.main.async(execute: {
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                
             }
        }
    }
    

    
    
}

extension UIView {
  func makeBorder()
  {
    //setting issues text
    self.layer.borderWidth = 1.0
    self.layer.cornerRadius = 7.0
    self.layer.borderColor = UIColor.init(red: 146.0/255.0, green: 187.0/255.0, blue: 213.0/255.0, alpha: 1.0).cgColor
  }
}


    



