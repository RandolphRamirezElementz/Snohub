//
//  RoleSignUpController.swift
//  SnowHub
//
//  Created by Liubov Perova on 4/21/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit

class RoleSignUpController: UIViewController {

    @IBOutlet weak var signUpDriver:UIButton!
    @IBOutlet weak var signUPCustomer:UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.signUpDriver.layer.borderColor = UIColor(red:(1.0), green:(1.0), blue:(1.0), alpha:1.0).cgColor
        self.signUpDriver.layer.cornerRadius = 52.0
        self.signUpDriver.layer.borderWidth = 1.0
        
        self.signUPCustomer.layer.borderColor = UIColor(red:(1.0), green:(1.0), blue:(1.0), alpha:1.0).cgColor
        self.signUPCustomer.layer.cornerRadius = 52.0
        self.signUPCustomer.layer.borderWidth = 1.0
        
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
