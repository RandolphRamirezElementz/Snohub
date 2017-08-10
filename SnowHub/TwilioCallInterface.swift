//
//  TwilioCallInterface.swift
//  SnowHub
//
//  Created by Liubov Perova on 2/1/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//
 
import UIKit

class TwilioCallInterface: UIViewController, TCDeviceDelegate, TCConnectionDelegate, UITextFieldDelegate {
    
    //let TOKEN_URL = "http://snowhub.transparen.com:5003/token?session_id=\(DataManager.sharedInstance.user.SID)"
    
    var device:TCDevice?
    var connection:TCConnection?
    var dataManager = DataManager.sharedInstance
    
  
    //MARK: IB Outlets
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var hangUpButton: UIButton!
    @IBOutlet weak var dialButton: UIButton!
    @IBOutlet weak var providerName: UILabel!
    @IBOutlet weak var userPic: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        retrieveToken()
        self.providerName.text = dataManager.order.driver_Name
        
        if(dataManager.user.isDriver)
        {
          self.providerName.text = dataManager.takenOrder.client_name
        }
        
    
        var uPicURL = ""
        //load picture 
        if let uPic = dataManager.order.driver_image as String?, dataManager.user.isDriver == false
        {
           uPicURL = uPic
        }
            
        else if let uPic = dataManager.takenOrder.driver_image as String?, dataManager.user.isDriver
        {
          uPicURL = uPic
        }

        if(uPicURL != "")
        {
            dataManager.load_image(urlString: uPicURL,  handler: { (image) in
                if(image != nil)
                {
                    DispatchQueue.main.async(execute: {
                       self.userPic.image = image
                    })
                }
            })
        }

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func initializeTwilioDevice(_ token:String) {
        device = TCDevice.init(capabilityToken: token, delegate: self)
        self.dialButton.isEnabled = true
    }
    
    func retrieveToken() {
        // Create a GET request to the capability token endpoint
//        let session = URLSession.shared
//        
//        let url = URL(string: TOKEN_URL)
//        let request = URLRequest(url: url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
//        
//        
//        let task = session.dataTask(with: request, completionHandler: { (responseData, response, error) in
//            
//            print("\(response)")
//            print("Response data: \(responseData)")
//            
//            if let responseData = responseData {
//                
//            if let token = String(data: responseData, encoding: .utf8) {//responseObject?["token"] as? String {
//                   self.initializeTwilioDevice(token)
//             }
//                
//            } else if let error = error {
//                self.displayError(error.localizedDescription)
//            }
//        })
//        task.resume()
        
        dataManager.getCallToken { (success, error, token) in
            if(success && token != nil)
            {
                print("GOT TOKEN: \(token ?? defaultValue)")
                self.initializeTwilioDevice(token!)
            }
            else
            {
                DispatchQueue.main.async(execute: {
                    self.displayError(error)
                })
            }
        }
    }
    
    //MARK: Utility Methods
    
    func displayError(_ errorMessage:String) {
        let alertController = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    //MARK: TCDeviceDelegate
    
    public func device(_ device: TCDevice, didStopListeningForIncomingConnections error: Error?) {
        print(error?.localizedDescription ?? "Device did stop listening")
        
    }
    
    func deviceDidStartListening(forIncomingConnections device: TCDevice) {
        statusLabel.text = "Started listening for incoming connections"
    }
    
    func device(_ device: TCDevice, didReceiveIncomingConnection connection: TCConnection) {
        if let parameters = connection.parameters {
            let from = parameters["From"]
            let message = "Incoming call from \(from ?? defaultValue)"
            let alertController = UIAlertController(title: "Incoming Call", message: message, preferredStyle: .alert)
            let acceptAction = UIAlertAction(title: "Accept", style: .default, handler: { (action:UIAlertAction) in
                connection.delegate = self
                connection.accept()
                self.connection = connection
            })
            let declineAction = UIAlertAction(title: "Decline", style: .cancel, handler: { (action:UIAlertAction) in
                connection.reject()
            })
            alertController.addAction(acceptAction)
            alertController.addAction(declineAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    
    //MARK: TCConnectionDelegate
    
    public func connection(_ connection: TCConnection, didFailWithError error: Error?) {
        
        print("Twilio dial error: \(error?.localizedDescription ?? "Connection did fail!") with code: \(error ?? defaultValue as! Error)" )
        
    }
    
    func connectionDidStartConnecting(_ connection: TCConnection) {
        statusLabel.text = "Started connecting...."
    }
    
    func connectionDidConnect( _ connection: TCConnection) {
        statusLabel.text = "Connected"
        hangUpButton.isEnabled = true
    }
    
    func connectionDidDisconnect( _ connection: TCConnection) {
        statusLabel.text = "Disconnected"
        dialButton.isEnabled = true
        hangUpButton.isEnabled = false
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn( _ textField: UITextField) -> Bool {
        //dial(dialTextField)
        //dialTextField.resignFirstResponder()
        return true;
    }
    
    //MARK: IB Actions
    @IBAction func hangUp(_ sender: AnyObject) {
        if let connection = connection {
            connection.disconnect()
        }
        if let device = device {
            device.disconnectAll()
        }
        self.dismiss()
    }
    
    //MARK: IB Actions
    @IBAction func dialUp(_ sender: AnyObject) {
        dial(sender)
    }
    
    func dial(_ sender: AnyObject) {
       
        var phone = dataManager.order.driver_phone
        
        if(dataManager.user.isDriver)
        {
            phone = dataManager.takenOrder.client_phone
        }
         print("Calling to: \(phone)")
        
        if(phone != "")
        {
            if let device = device {
                device.connect(["To":phone, "session_id": dataManager.user.SID], delegate: self)
                dialButton.isEnabled = false
            }
        }
    }

    func dismiss() {
        self.dismiss(animated: true, completion: nil)
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
