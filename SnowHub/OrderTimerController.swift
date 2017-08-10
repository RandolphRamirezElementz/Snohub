//
//  OrderTimerController.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/15/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//
// FOR DRIVER. SETS ETA FOR CURRENT TAKEN ORDER
//
//

import UIKit

class OrderTimerController: UIViewController {

    
    @IBOutlet weak var setTimeButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var timeLabel: UILabel!
    

    var currentOrder_index: Int = 0
    var currentOrder: Order = Order()
    var dataManager:DataManager = DataManager.sharedInstance

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.timePicker.minimumDate = Date()
        
        setTimeButton.setTitleColor(UIColor.white, for: .highlighted)
        setTimeButton.setTitleColor(UIColor.white, for: .normal)
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        
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
    
    @IBAction func setTime()
    {
        timePicker.datePickerMode = UIDatePickerMode.time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        timeLabel.text = dateFormatter.string(from: timePicker.date)
     
        if timePicker.date.timeIntervalSince1970 != 0 {
       
            let timestamp: Double = timePicker.date.timeIntervalSince1970
            print("Set timestamp:  \(timestamp) ")
            if dataManager.takenOrder.id != 0           {
                dataManager.setETA(id: dataManager.takenOrder.id, timestamp: timestamp,  completionCallback: {(success, message) in
                if(success)
                {
                    DispatchQueue.main.async(execute: {
                        self.dataManager.takenOrder.eta = self.timePicker.date
                        self.dataManager.setUserPreferences()
                        self.performSegue(withIdentifier: "goToDriverMap", sender:self) //go to next stage
                    })
                }
                else
                {
                    let alert = UIAlertController(title: "Error", message: message == "" ? "Error setting ETA!" : message , preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    
                    DispatchQueue.main.async(execute: {
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                
            })


            }


       }
        //set ETA for this order
        
    }

}
