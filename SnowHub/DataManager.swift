//
//  DataManager.swift
//  SnowHub
//
//  Created by Liubov Perova on 10/25/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import Foundation
import CryptoSwift
import Kingfisher
//import AVFoundation

public enum Status: Int {
    case NEW = 0
    case ACCEPTED = 1
    case IN_PROGRESS = 2
    case FINISHED = 3
    case CANCELLED = 4
    case SCHEDULED = 5
}

//status of onboarding steps
public enum StepStatus: String {
   
    case PASSED = "PASSED"
    case NOT_PASSED = "NOT_PASSED"
    case APPROVED = "APPROVED"
    case REJECTED = "REJECTED"
}



public var defaultValue:String = "none"

struct Order {
    
    var address: String
    var gravelDriveway: Bool
    var markersThere: Bool
    var asphaltDriveway: Bool
    var otherIssues: Bool
    var issuesThere: String
    var coordinates: CLLocationCoordinate2D
    var orderStatus: Status = .NEW;
    var driveWayLength = 0;
    var id = 0
    var charge_id = ""
    var county_area:String = "Westchester"
    var deicing = 0
    var serviceNow = false
    var serviceNext = false
    var serviceEvery = false
    var clean_front_walkway = false
    var clean_back_walkway = false
    var clean_side_walkway = false
    var snow_depth = 0
    var walkways_number = 0
    var actual_snow_depth = 0
    var actual_driveway_length = 0
    
    var price = 0.0
    var tax = 0.0
    var driver_fee = 0.0
    var debt = 0.0
    var showeling_price = 0.0
    var salt_price = 0.0
    var marking_driveway_price = 0.0
    var plowing_price = 0.0
    var tax_percents = 0.0
    var bonus = 0.0
    
    var promo_code = ""
    
    var driver_id: Int = 0
    var driver_Name: String = "" //name of driver
    var car_Name: String = "" //name of driver's car
    var car_image: String = ""//image url of car
    var driver_image: String = "" //image url of driver (user in driver's case)
    var order_image_before: String = ""
    var order_image_after : String = ""
    var driver_phone: String = "" //for client to know the driver's phone
    var eta: Date? = nil  //estimated time of arrival
    var time_stamp: Date? = nil //date when created

    
    var client_phone = "" //for driver to know the client's phone
    var client_name = ""  //name of client
    
    init(){
        self.address = ""
        self.gravelDriveway = false
        self.markersThere = false
        self.asphaltDriveway = false
        self.otherIssues = false
        self.issuesThere = ""
        self.coordinates = CLLocationCoordinate2D()
    }
    

}

struct User {
    
    var user_id: Int
    var number: String
    var name: String
    var SID: String
    var SIDunaccepted = ""
    var webTokenID = ""
    var isDriver: Bool
    var approved = false
    var email: String
    var car_name = ""
    var car_pic = ""
    var user_pic = ""
    var user_image: UIImage? = nil
    var car_image: UIImage? = nil
    
    var bankAccountNumber: String = ""
    var bankRoutingNumber: String = ""
    var bankAccountHolder: String = ""
    
    var homeAddress = ""
    var homeAddressCoordinates:CLLocationCoordinate2D?
    
    init(u_id: Int, u_number: String, u_name: String, u_sid: String, u_isDriver: Bool, u_email: String){
        self.isDriver = u_isDriver
        self.SID = u_sid
        self.name = u_name
        self.user_id = u_id
        self.number = u_number
        self.email = u_email
    }
}

class DataManager: NSObject {
   
    static let sharedInstance : DataManager = {
        let instance = DataManager()
        return instance
       }()
    
    //config
    var urlBase: String
    var socketBase: String = ""
    var stripePublicKey = ""
    var snowDepthArray:Array<String> = []
    var roadLengths:Array<String> = []
    
    var session_connection:URLSession = URLSession.shared
    var nearbyDrivers:[NSDictionary] = []
    var nearbyOrders:[NSDictionary] = []
    var order: Order = Order()
    var user: User = User(u_id: 0, u_number: "", u_name: "", u_sid: "", u_isDriver: false, u_email: "")
    var takenOrder = Order()
    var checkCode = ""
    var wsclient: SnohubSocket? = nil
    var darkskyClientString = "https://api.darksky.net/forecast/026288ce90e7055851de5427347c71b8/" //darksky forecasts
    
    //socketBased statuses
    var orderStatusChanged = false
    var etaChanged = false
    var gotDriversUpdate = false
    var isOnline = true
    var gotLoggedOut = false
    var socketCheckTimer: Timer? = nil     //timer to update driver's position
    
    //for pricing
    var inches_rate_increase = 0;
    var inches_rate_increase_price = 0;
    
    //settings
    var soundsOn = true
    
    convenience override init()
    {
        self.init(url_base: "")
    }
    
    init(url_base: String) {
        urlBase = url_base;
    }

    //driver onboarding info 
    var onboarding_info: Dictionary<String, Any> = [:]
    
    //--------------------------- Manage all requests to server
    
    //1. General uniform request
    func infoRequest(method: Method, urlString: String, params: [String: AnyObject], completionCallback: @escaping (NSDictionary)->() ) {
        
        let fullString = urlBase + urlString
        guard let url = URL(string: fullString) else {
            print("Error: cannot create URL")
            return
        }
        //let urlRequest = URLRequest(url: url)
        let urlRequest = URLRequest.request(url, method: method, params: params)
        
        print("GOING TO URL: \(String(describing: urlRequest.url))")
        
        let task = session_connection.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            //print(data as Any)
            print(error ?? "no error")
            print(response as Any)
            if(data != nil)
            {
                do
                {
                  let parsedDataDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                  completionCallback(parsedDataDict)
                }
                catch
                {
                    completionCallback([:])
                }
            }
            else{
                //completionCallback([:])
                print("Request was declined or connection does not work")
                var error = "No connection to server. Please check the internet connection"
                if let httpResponse = response as? HTTPURLResponse {
                    print("error \(httpResponse.statusCode)")
                    if httpResponse.statusCode != 0
                    {
                       if(httpResponse.statusCode >= 400 && httpResponse.statusCode < 500)
                       {
                         error = "Methods are unavailable on server."
                         if(httpResponse.statusCode == 403)
                         {
                           error = "Your authorization is not valid anymore. Please try to log in again."
                         }
                       }
                       else if(httpResponse.statusCode >= 500)
                       {
                         error = "Server is unavailable. Please check your Internet connection!"
                       }
                    }
                }
                
                let response_dict:NSDictionary = [
                                 "data" : "",
                                 "error" : error,
                                 "success": 1
                               ]
                completionCallback(response_dict)
                
               }
                
         })
       
         task.resume()
       
    }
    
    //2. General post request for loading picture
    func uploadPicture(imageToLoad: UIImage, type: Int, completionCallback: @escaping (Bool, String) ->()){
        
        let fullString = urlBase + "/users/upload"
        guard let url = URL(string: fullString) else {
            print("Error: cannot create URL")
            return
        }
        var urlRequest = URLRequest(url: url)
        let boundary = generateBoundaryString()
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        urlRequest.httpMethod = "POST"
        
        let image_data = UIImageJPEGRepresentation(imageToLoad, 1.0)
        if(image_data == nil)
        {
          completionCallback(false, "Image is empty")
          return
        }
        
        let body = NSMutableData()
        let fname = "\(self.takenOrder.id)_\(type).png"
        let mimetype = "image/png"
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"order_id\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("\(self.takenOrder.id)\r\n".data(using: String.Encoding.utf8)!)
      
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"session_id\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("\(self.user.SID)\r\n".data(using: String.Encoding.utf8)!)

        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"type\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("\(type)\r\n".data(using: String.Encoding.utf8)!)

        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"file\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append(image_data!)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        
        urlRequest.httpBody = body as Data
        
        let task = session_connection.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            print(data as Any)
            print(error ?? "no error")
            print(response as Any)
            if(data != nil)
            {
                completionCallback(true, "Uploaded successfully")
                
                do
                {
                    if let parsedDataDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
                    {
                       if let _ = parsedDataDict["data"] as? String
                       {
                         let dataUrl = parsedDataDict["data"] as! String
                        
                        if(type == 0)
                        {
                         self.user.user_pic =  dataUrl
                         self.setUserPreferences()
                         print("New userPic: \(dataUrl)")
                        }
                        
                        if(type == 1)
                        {
                            self.user.car_pic =  dataUrl
                            self.setUserPreferences()
                            print("New carPic: \(dataUrl)")
                        }
                        
                       }
                    }
                    else
                    {
                        print( "Could not decode new url data data")
                    }
                }
                catch let error
                {
                    print("Error converting to json", error);
                    return
                }

            }
            else{
                completionCallback(false, "Could not upload picture. Request was declined or connection does not work" )
                print("Request was declined or connection does not work")
            }
            
        })
        
        task.resume()
        
    }

    
    //3. Post request for uploading picture and setting order state to InProgress ( state 2 )
    func setInProgress(imageToLoad: UIImage, inches: Int, road_length: Int, completionCallback: @escaping (Bool, String) ->()){
        
        let fullString = urlBase + "/orders/setInProgress"
        guard let url = URL(string: fullString) else {
            print("Error: cannot create URL")
            return
        }
        var urlRequest = URLRequest(url: url)
        let boundary = generateBoundaryString()
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        urlRequest.httpMethod = "POST"
        
        let image_data = UIImageJPEGRepresentation(imageToLoad, 1.0)
        if(image_data == nil)
        {
            completionCallback(false, "Image is empty")
            return
        }
        
        let body = NSMutableData()
        let fname = "\(self.takenOrder.id)_inprogress.png"
        let mimetype = "image/png"
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"order_id\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("\(self.takenOrder.id)\r\n".data(using: String.Encoding.utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"session_id\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("\(self.user.SID)\r\n".data(using: String.Encoding.utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"inches\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("\(inches)\r\n".data(using: String.Encoding.utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"road_length\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("\(road_length)\r\n".data(using: String.Encoding.utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition:form-data; name=\"picture\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append(image_data!)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        
        urlRequest.httpBody = body as Data
        
        let task = session_connection.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            print(data as Any)
            print(error ?? "no error")
            print(response as Any)
            if(data != nil)
            {
                //completionCallback(true, "Uploaded successfully")
                
                do
                {
                    if let parsedDataDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
                    {
                        print("Upload response returned: \(parsedDataDict)")
                        if let dataDict = parsedDataDict["data"] as? NSDictionary, parsedDataDict["success"] as? Int == 0
                        {
                           print("Upload data returned: \(dataDict)")
                           if let debtDict = dataDict["debt"] as? NSDictionary
                           {
                            print("Debt: \(debtDict)")
                            if let driverFee = debtDict["driver_fee"] as? Double
                            {
                               self.takenOrder.debt = driverFee
                               print("Driver debt pending: \(self.takenOrder.debt)")
                            }
                           }
                            completionCallback(true, "Order status changed successfully")
                        }
                        else
                        {
                          var error = "Could not change the order state"
                            if let err = parsedDataDict["error"] as? String
                            {
                               error = err
                            }
                            completionCallback(false, error)
                        }
                    }
                    else
                    {
                        completionCallback(false, "Could not decode new url data")
                        print( "Could not decode new url data")
                    }
                }
                catch let error
                {
                    print("Error converting to json", error);
                    return
                }
                
            }
            else{
                completionCallback(false, "Could not upload picture. Request was declined or connection does not work" )
                print("Request was declined or connection does not work")
            }
            
        })
        
        task.resume()
        
    }

    //4. Post request with multipart form data
    func postFormData(parameters:Dictionary<String,Any>, urlstring:String, completionCallback: @escaping (Bool, String) ->()){
        
        let fullString = urlBase + urlstring
        guard let url = URL(string: fullString) else {
            print("Error: cannot create URL")
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        let boundary = generateBoundaryString()
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = NSMutableData()
       
        let mimetype = "image/png"
        let fname = "registration_step_inprogress.png"
        
        for(key, parameter) in parameters
        {
            body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
            if key == "image"{
                let image_data = UIImageJPEGRepresentation(parameter as! UIImage, 1.0)
                body.append("Content-Disposition:form-data; name=\"picture\"; filename=\"\(fname)\"\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
                body.append(image_data!)
                body.append("\r\n".data(using: String.Encoding.utf8)!)
            }
            else
            {
                body.append("Content-Disposition:form-data; name=\"\(key)\"\r\n\r\n".data(using: String.Encoding.utf8)!)
                body.append("\(parameter)\r\n".data(using: String.Encoding.utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        urlRequest.httpBody = body as Data
       
            let task = session_connection.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                print(data as Any)
                print(error ?? "no error")
                print(response as Any)
                if(data != nil)
                {
                    //completionCallback(true, "Uploaded successfully")
                    
                    do
                    {
                        if let parsedDataDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSDictionary
                        {
                            print("Upload response returned: \(parsedDataDict)")
                            if let dataDict = parsedDataDict["data"], parsedDataDict["success"] as? Int == 0
                            {
                                print("Upload data returned: \(dataDict)")
                                completionCallback(true, "Request done successfully")
                            }
                            else
                            {
                                var error = "Could not change the order state"
                                if let err = parsedDataDict["error"] as? String
                                {
                                    error = err
                                }
                                completionCallback(false, error)
                            }
                        }
                        else
                        {
                            completionCallback(false, "Could not decode new url data")
                            print( "Could not decode new url data")
                        }
                    }
                    catch let error
                    {
                        print("Error converting to json", error);
                        completionCallback(false, "Error converting to json")
                        return
                    }
                    
                }
                else{
                    completionCallback(false, "Could not upload data. Request was declined or connection does not work" )
                    print("Request was declined or connection does not work")
                }
                
            })
            
            task.resume()
    }
    
    //get own orders
    func getOwnOrders(is_driver: String, completionCallback: @escaping ([Dictionary<String,Any?>]) -> ()){
        
        let url_path = self.user.isDriver ? "/orders/getDriverOrders" : "/orders/getCustomerOrders"
        let params =
            [
                "is_driver"  : is_driver as AnyObject,
                "session_id" : self.user.SID as AnyObject,
            ]
        infoRequest(method: .GET, urlString: url_path, params: params) {(parsedDataDict) in
                if parsedDataDict["success"] as? Int == 0
                {
                    if let parsedData = parsedDataDict["data"] as? [Dictionary<String,Any?>] {
                    if(!parsedData.isEmpty && parsedData.count > 0){
                        print(parsedData[0])
                        
                        print("calling callback")
                        completionCallback(parsedData)
                       }
                    }
                }
                else
                {
                    completionCallback([Dictionary<String,Any?>]())
                }
                
            }
        
    }

    
    //send email for login
    func sendLoginNumber(completionCallback: @escaping (_: Bool, String) -> ()){
        
        //log out properly in case the prev. logout was not clean
        UserDefaults.standard.set("", forKey: "SID")
        UserDefaults.standard.synchronize()
        
        let params =
            [
                "login": self.user.number as AnyObject,
            ]
        
//        if let device_id = UserDefaults.standard.string(forKey: "APToken")  {
//            params["device_id"] = device_id as AnyObject
//        }
        
        infoRequest(method: .GET, urlString: "/users/loginSendEmail", params: params) {(parsedDataDict) in
           
                print("response data: \(parsedDataDict)")
                if let _ = parsedDataDict["success"] as? Int
                {
                    //let parsedString = parsedDataDict["data"] as! String
                    if( parsedDataDict["success"] as! Int == 0 ){
                        print("calling callback")
                        completionCallback(true, "")
                    }
                    else
                    {
                        let error = parsedDataDict["error"] as? String
                        completionCallback(false, error == nil ? " " : error!)
                    }
                }
                else
                {
                    completionCallback(false, "Error sending login SMS")
                }
        }
        
    }
    
    //send number for login verify
    func sendVerifyNumber(completionCallback: @escaping (_: Bool, String) -> ()){
        
        let params =
            [
                "login": self.user.number as AnyObject,
                ]
        infoRequest(method: .GET, urlString: "/users/loginSendSms", params: params) {(parsedDataDict) in
           
                print("response data: \(parsedDataDict)")
                if let _ = parsedDataDict["success"] as? Int
                {
                    //let parsedString = parsedDataDict["data"] as! String
                    if( parsedDataDict["success"] as! Int == 0 ){
                        print("calling callback")
                        completionCallback(true, "")
                    }
                    else
                    {
                        let error = parsedDataDict["error"] as? String
                        completionCallback(false, error == nil ? " " : error!)
                    }
                }
                else
                {
                    completionCallback(false, "Error sending login SMS")
                }
        }
        
    }

    //send number for signUp
    func sendSignUpNumber(completionCallback: @escaping (_: Bool, String) -> ()){
        
        var params =
            [
                "login"    : self.user.number as AnyObject,
                "name"     : self.user.name as AnyObject,
                "is_driver": (self.user.isDriver ? "true":"false") as AnyObject,
                "email"    : self.user.email as AnyObject
            ]
        
        if let device_id = UserDefaults.standard.string(forKey: "APToken")  {
            params["device_id"] = device_id as AnyObject
        }
        
        infoRequest(method: .GET, urlString: "/users/registerSendSms", params: params) {(parsedDataDict) in
            
               print("response data: \(parsedDataDict)")
                if let _ = parsedDataDict["success"] as? Int
                {
                    //let parsedString = parsedDataDict["data"] as! String
                    if( parsedDataDict["success"] as! Int == 0 ){
                        print("calling callback")
                        completionCallback(true, "")
                    }
                    else
                    {
                        let error = parsedDataDict["error"] as? String
                        completionCallback(false, error!)
                    }
                }
                else
                {
                   completionCallback(false, "No response came from server")
                }
            
        }
        
    }

    //send login to receive SMS for driver registration
    //users/registerSendSmsDriver
    func registerSendSmsDriver(completionCallback: @escaping (_: Bool, String) -> ()){
        
        let params =
            [
                "login"    : self.user.number as AnyObject,
            ]
        
        infoRequest(method: .POST, urlString: "/users/registerSendSmsDriver", params: params) {(parsedDataDict) in
            
            print("response data: \(parsedDataDict)")
            if let _ = parsedDataDict["success"] as? Int
            {
                if( parsedDataDict["success"] as! Int == 0 ){
                    print("calling callback")
                    completionCallback(true, "")
                }
                else
                {
                    let error = parsedDataDict["error"] as? String
                    completionCallback(false, error!)
                }
            }
            else
            {
                completionCallback(false, "No response came from server")
            }

        }
        
    }

    //send registration confirm number for driver
    //users/registerCheckCodeDriver
    func registerCheckCodeDriver(code: String, completionCallback: @escaping (_: Bool, String) -> ()){
        
        var params =
            [
                "login" : self.user.number as AnyObject,
                "code"  : code as AnyObject
            ]
        
        if let device_id = UserDefaults.standard.string(forKey: "APToken")  {
            params["device_id"] = device_id as AnyObject
        }
        
        infoRequest(method: .GET, urlString: "/users/registerCheckCodeDriver", params: params) {(parsedDataDict) in
            
            print("response data: \(parsedDataDict)")
            if let _ = parsedDataDict["success"] as? Int
            {
                if( parsedDataDict["success"] as! Int == 0 ){
                    
                   if let data = parsedDataDict ["data"] as? NSDictionary
                   {
                    
                      if let session_id_reg = data["session_id_reg"] as? String
                      {
                         self.user.SIDunaccepted = session_id_reg
                         self.setUserPreferences()
                      }
                    
                      if let session_id = data["session_id"] as? String
                      {
                        self.user.SID = session_id
                        self.setUserPreferences()
                      }
                    
                      if let login = data["login"] as? String {
                        
                        self.user.number = login
                      }
                    
                      if let stepsInfo =  data["steps_info"] as? Dictionary<String, Any>
                      {
                        self.onboarding_info = stepsInfo
                      }
                    
                     if self.user.SIDunaccepted != ""
                      {
                       completionCallback(true, "success")
                      }
                      else
                      {
                        completionCallback(false, "Session ID had not come")
                      }
                  }
                   else
                  {
                     completionCallback(false, "Session ID had not come")
                  }
                    
                   
                }
                else
                {
                    let error = parsedDataDict["error"] as? String
                    completionCallback(false, error!)
                }
            }
            else
            {
                completionCallback(false, "No response came from server")
            }
            
        }
        
    }

    //send account number while registering driver
    //users/registerDriver/5
    func registerSendAccountDriver(accNumber: String, accType: String, completionCallback: @escaping (_: Bool, String) -> ()){
        
        let params =
            [
                "session_id" : self.user.SIDunaccepted as AnyObject,
                "account_type" : accType as AnyObject,
                "number": accNumber as AnyObject
            ]
        
        infoRequest(method: .POST, urlString: "/users/registerDriver/5", params: params) {(parsedDataDict) in
            
            print("response data: \(parsedDataDict)")
            if let _ = parsedDataDict["success"] as? Int
            {
                if( parsedDataDict["success"] as! Int == 0 ){
                    completionCallback(true, "")
                }
                else
                {
                    let error = parsedDataDict["error"] as? String
                    completionCallback(false, error!)
                }
            }
            else
            {
                completionCallback(false, "No valid response came from server")
            }
            
        }
        
    }

    //send email while registering driver
    //users/registerDriver/7
    func registerSendEmailDriver(email: String, completionCallback: @escaping (_: Bool, String) -> ()){
        
        let params =
            [
                "session_id" : self.user.SIDunaccepted as AnyObject,
                "email": email as AnyObject
        ]
        
        infoRequest(method: .POST, urlString: "/users/registerDriver/7", params: params) {(parsedDataDict) in
            
            print("response data: \(parsedDataDict)")
            if let _ = parsedDataDict["success"] as? Int
            {
                if( parsedDataDict["success"] as! Int == 0 ){
                    completionCallback(true, "")
                }
                else
                {
                    let error = parsedDataDict["error"] as? String
                    completionCallback(false, error!)
                }
            }
            else
            {
                completionCallback(false, "No valid response came from server")
            }
            
        }
        
    }

    //send email while registering driver
    //users/registerDriver/8
    func registerSendAgreementDriver(agreed: Bool, completionCallback: @escaping (_: Bool, String) -> ()){
        
        let params =
            [
                "session_id" : self.user.SIDunaccepted as AnyObject,
                "agreed": agreed as AnyObject
            ]
        
        infoRequest(method: .POST, urlString: "/users/registerDriver/8", params: params) {(parsedDataDict) in
            
            print("response data: \(parsedDataDict)")
            if let _ = parsedDataDict["success"] as? Int
            {
                if( parsedDataDict["success"] as! Int == 0 ){
                    completionCallback(true, "")
                }
                else
                {
                    let error = parsedDataDict["error"] as? String
                    completionCallback(false, error!)
                }
            }
            else
            {
                completionCallback(false, "No valid response came from server")
            }
            
        }
        
    }
    
    
    //send number for signUp
    func sendLoginCode(completionCallback: @escaping (_: Bool, String) -> ()){
        
       let checkCode = self.checkCode.md5()
       var params =
            [
                "login": self.user.number as AnyObject,
                "code" : checkCode as AnyObject,
            ]
        
        if let device_id = UserDefaults.standard.string(forKey: "APToken")  {
            params["device_id"] = device_id as AnyObject
        }

        infoRequest(method: .GET, urlString: "/users/loginCheckCode", params: params) {(parsedDataDict) in
                print("response data: \(parsedDataDict)")
                if let _ = parsedDataDict["data"] as? NSDictionary
                {
                    print("data received: \(parsedDataDict["data"] as! NSDictionary)")
                    
                    let parsedDict = parsedDataDict ["data"] as! NSDictionary
                    if let _ = parsedDict["session_id"] as? String {
                        self.user.SID = parsedDict["session_id"] as! String
                        self.user.SIDunaccepted = self.user.SID
                        if let _ = parsedDict["id"] as? Int {
                            self.user.user_id = parsedDict["id"] as! Int
                            
                            if let name = parsedDict["name"] as? String
                            {self.user.name = name}
                            
                            if let _ = parsedDict["profile_pic_url"] as? String
                            {self.user.user_pic = (parsedDict["profile_pic_url"] as? String)!}
                            
                            if let is_driver = parsedDict["is_driver"] as? Bool
                            {self.user.isDriver = is_driver}
                            
                            if let _ = parsedDict["vehicle_model"] as? String
                            {self.user.car_name = (parsedDict["vehicle_model"] as? String)!}
                            
                            if let _ = parsedDict["vehicle_pic_url"] as? String
                            {self.user.car_pic = (parsedDict["vehicle_pic_url"] as? String)!}
                            
                            completionCallback(true, "")
                        }
                        else
                        {
                            let error = parsedDataDict["error"] as? String
                            completionCallback(false, error != nil ? error! : "Error sending code!")
                        }
                    }
                    else
                    {
                        let error = parsedDataDict["error"] as? String
                        completionCallback(false, error != nil ? error! : "Error sending code!")
                    }
                }
                else
                {
                    let error = parsedDataDict["error"] as? String
                    completionCallback(false, error != nil ? error! : "Error sending code!")
                }
                
           }
        
    }

   
    //accept Order
    func acceptOrder(id: Int, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
       let params =
            [
                "session_id" : self.user.SID as AnyObject,
                "id"         : String(id) as AnyObject
            ]
       
       infoRequest(method: .GET, urlString: "/orders/acceptOrder", params: params) {(parsedDataDict) in
                print("response data: \(parsedDataDict)")
                
                if let _ = parsedDataDict["data"], parsedDataDict["success"] as? Int == 0
                {
                    print("data received: \(parsedDataDict["data"] as Any)")
                    completionCallback(true, "")
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "You cannot accept the order")
                }
        
        }
        
    }
    
    //rate Order
    func rateOrder(rate: Int, is_driver: String, order_id: Int, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        var id = (is_driver == "true" ? self.takenOrder.id : self.order.id)
        if order_id != 0
        {
          id = order_id
        }
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
                "id"         : String(id) as AnyObject,
                "rate"       : "\(rate)" as AnyObject
            ]
        
        infoRequest(method: .GET, urlString: "/orders/rateOrder", params: params) {(parsedDataDict) in
            print("response data: \(parsedDataDict)")
                
                if let _ = parsedDataDict["data"], parsedDataDict["success"] as? Int == 0
                {
                    print("data received: \(parsedDataDict["data"] as Any)")
                    completionCallback(true, "")
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "You cannot rate this order")
                }
            
        }
        
    }

    //get promo
    
    func getPromo(completionCallback: @escaping (_: Bool, _ : String, _ : Dictionary<String, Any>?) -> ()){
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
            ]
        
        infoRequest(method: .GET, urlString: "/users/getSharePromo", params: params) {(parsedDataDict) in
            print("response data: \(parsedDataDict)")
            
            if let shareData = parsedDataDict["data"] as? NSDictionary, parsedDataDict["success"] as? Int == 0
            {
                print("data received: \(parsedDataDict["data"] as Any)")
                completionCallback(true, "", shareData as? Dictionary<String, Any> )
            }
            else
            {
                let error_message = parsedDataDict["error"] as? String
                completionCallback(false, error_message ?? "You have not received the data", nil)
            }
            
        }
        
    }

    //get call token
    func getCallToken(completionCallback: @escaping (_: Bool, _ : String, _ : String?) -> ()){
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
            ]
        
        infoRequest(method: .GET, urlString: "/users/token", params: params) {(parsedDataDict) in
            print("response data: \(parsedDataDict)")
            
            if let shareData = parsedDataDict["data"] as? String, parsedDataDict["success"] as? Int == 0
            {
                print("data received: \(parsedDataDict["data"] as Any)")
                completionCallback(true, "", shareData)
            }
            else
            {
                let error_message = parsedDataDict["error"] as? String
                completionCallback(false, error_message ?? "You have not received the data", nil)
            }
            
        }
        
    }
    
    //get call token
    func twilioCall(to: String, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
                "to": to as AnyObject
            ]
        
        infoRequest(method: .GET, urlString: "/call", params: params) {(parsedDataDict) in
            print("response data: \(parsedDataDict)")
            
            if let _ = parsedDataDict["data"] as? String, parsedDataDict["success"] as? Int == 0
            {
                print("data received: \(parsedDataDict["data"] as Any)")
                completionCallback(true, "")
            }
            else
            {
                let error_message = parsedDataDict["error"] as? String
                completionCallback(false, error_message ?? "You have not received the data")
            }
            
        }
        
    }

    
    
    //set defaultAddress
    func setDefaultAddress(address: String, lat: Double, lng: Double, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
                "address"         : address as AnyObject,
                "lat"       : "\(lat)" as AnyObject,
                "lng"       : "\(lng)" as AnyObject
            ]
        
        infoRequest(method: .POST, urlString: "/users/setAddress", params: params) {(parsedDataDict) in
            print("response data: \(parsedDataDict)")
            
            if parsedDataDict["success"] as? Int == 0
            {
                print("data received: \(parsedDataDict["data"] as Any)")
                completionCallback(true, "")
            }
            else
            {
                let error_message = parsedDataDict["error"] as? String
                completionCallback(false, error_message ?? "You failed to set default address")
            }
            
        }
        
    }

    
    
    //driver sets his/her location
    func setLocation(location: CLLocationCoordinate2D, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
                "gps_lat"    : String(location.latitude) as AnyObject,
                "gps_lng"    : String(location.longitude) as AnyObject
            ]
        
        infoRequest(method: .GET, urlString: "/users/setLocation", params: params) {(parsedDataDict) in
           
                print("response data: \(parsedDataDict)")
                
                if let _ = parsedDataDict["data"], parsedDataDict["success"] as? Int == 0
                {
                    print("data received: \(parsedDataDict["data"] as Any)")
                    completionCallback(true, "")
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "You cannot accept the order")
                }
                
           
        }
        
    }

    
    //setETA
    func setETA(id: Int, timestamp: Double, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        let params =
            [
                "id"         : "\(id)" as AnyObject,
                "session_id" : self.user.SID as AnyObject,
                "time_stamp" : String(timestamp) as AnyObject,
            ]
        
        infoRequest(method: .GET, urlString: "/orders/setETA", params: params) {(parsedDataDict) in
              if let _ = parsedDataDict["data"], parsedDataDict["success"] as? Int == 0
                {
                    print("data received: \(parsedDataDict["data"] as Any)")
                    completionCallback(true, "")
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "Error happened. You cannot set this ETA")
                }
                
            }
        
    }

    //getPrice
    func getOrderPrice(completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        let params =
            [
                "promo_code": self.order.promo_code as AnyObject,
                "session_id" : self.user.SID as AnyObject,
                "driveway_length" : String(self.order.driveWayLength) as AnyObject,
                "deicing" : "\(self.order.deicing)"  as AnyObject,
                "driveway_marker"  : "\(self.order.markersThere)" as AnyObject,
                "walkways_number" : "\(self.order.walkways_number)"  as AnyObject,
                "area"    : (self.order.county_area == "Fairfield" ? 1 : 2) as AnyObject,
                "lat" : String(self.order.coordinates.latitude) as AnyObject,
                "lng" : String(self.order.coordinates.longitude) as AnyObject,
                "clean_front_walkway" : "\(self.order.clean_front_walkway)" as AnyObject,
                "clean_back_walkway" : "\(self.order.clean_back_walkway)" as AnyObject,
                "clean_side_walkway" : "\(self.order.clean_side_walkway)" as AnyObject,
            ]
        
        infoRequest(method: .GET, urlString: "/orders/calculateOrderPrice", params: params) {(parsedDataDict) in
             if parsedDataDict["success"] as? Int == 0
                {
                    if let priceDict:Dictionary = parsedDataDict["data"] as? Dictionary<String,Any>
                    {
                        
                            print("price received: \(String(describing: parsedDataDict["data"]))")
                        
                            self.order.showeling_price = 0
                        
                            if let price = priceDict["price"] as? Double{
                                self.order.price = price
                            }
                            if let tax = priceDict["tax"] as? Double{
                               self.order.tax = tax
                            }
                            if let debt = priceDict["debt"] as? Double{
                               self.order.debt = debt
                            }
                        
                            if let inches = priceDict["inches"] as? Int{
                                self.order.snow_depth = inches
                            }
                        
                            if let inch_amount = priceDict["inches_rate_increase_amount"] as? Int {
                              self.inches_rate_increase = inch_amount
                            }
                        
                            if let inch_amount_price = priceDict["inches_rate_increase_price"] as? Double {
                              self.inches_rate_increase_price = Int(inch_amount_price)
                            }

                            if let b_shoveling = priceDict["clean_back_walkway"] as? Double{
                              self.order.showeling_price += b_shoveling
                            }
                        
                            if let s_shoveling = priceDict["clean_side_walkway"] as? Double{
                               self.order.showeling_price += s_shoveling
                            }
                        
                            if let f_shoveling = priceDict["clean_front_walkway"] as? Double{
                               self.order.showeling_price += f_shoveling
                            }
                        
                            if let salt_price = priceDict["salt_price"] as? Double{
                              self.order.salt_price = salt_price
                            }
                        
                            if let marking_price = priceDict["marking_driveway_price"] as? Double{
                              self.order.marking_driveway_price = marking_price
                            }
                        
                            if let plowing_price = priceDict["plowing_price"] as? Double{
                             self.order.plowing_price = plowing_price
                            }
                        
                            if let tax_percents = priceDict["tax_percents"] as? Double{
                             self.order.tax_percents = tax_percents
                            }
                        
                            if let bonus = priceDict["bonus"] as? Double{
                             self.order.bonus = bonus
                            }
                        
                    }
                    completionCallback(true, "")
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "Error happened. You could not get the order details")
                }
                
              }
        
    }
 
    //changeSettings
    func changeSettings(firstName: String, lastName: String, login: String, email: String, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
                "email" : email as AnyObject,
                "login" : login as AnyObject,
                "first_name": firstName as AnyObject,
                "last_name": lastName as AnyObject
            ]
        
        infoRequest(method: .GET, urlString: "/users/changeSettings", params: params) {(parsedDataDict) in
            if parsedDataDict["success"] as? Int == 0
            {
                completionCallback(true, "")
            }
            else
            {
                let error_message = parsedDataDict["error"] as? String
                completionCallback(false, error_message ?? "Error happened. Server didn't respond properly on your request")
            }
            
        }
        
    }

    
    
    //set order status (not used)
    func setOrderStatus(id: Int, status: Int, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
                "id" : String(id) as AnyObject,
                "status": String(status) as AnyObject
            ]

        
        infoRequest(method: .GET, urlString: "/orders/setOrderInProgress", params: params) {(parsedDataDict) in
            
            if let _ = parsedDataDict["data"], parsedDataDict["success"] as? Int == 0
                {
                    print("data received: \(parsedDataDict["data"] as Any)")
                    completionCallback(true, "")
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "Error happened. You cannot chage status of this order")
                }
            
        }
        
    }
    
    //cancel Order /by user
    func canselOrder(id: Int, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        //let session_id:String = "session_id=" + self.user.SID.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        //let paramString = session_id + "&" + "id=" + String(id)
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
                "id" : String(id) as AnyObject,
            ]
        
        infoRequest(method: .GET, urlString: "/orders/cancelOrder", params: params) {(parsedDataDict) in
                print("response data: \(parsedDataDict)")
                
                if parsedDataDict["success"] as? Int == 0
                {
                    print("data received: \(parsedDataDict["data"] as Any)")
                    completionCallback(true, "")
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "You cannot accept the order")
                }
            
        }
        
    }
    
    //get Order status (not used anymore since socket connections became available)
    func getOrderStatus(id: Int, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        //let session_id:String = "session_id=" + self.user.SID.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        //let paramString = session_id + "&" + "id=" + String(id)
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
                "id" : String(id) as AnyObject,
            ]

        
        infoRequest(method: .GET, urlString: "/orders/getOrderState", params: params) {(parsedDataDict) in
          
                print("response data: \(parsedDataDict)")
                
                if parsedDataDict["success"] as? Int == 0
                {
                    //print("data received: \(parsedDataDict["data"] as Any)")
                    
                    var parsedDict = parsedDataDict["data"] as? NSDictionary
                    
                    if let parsedDictArray = parsedDataDict["data"] as? [NSDictionary]
                    {
                        parsedDict = parsedDictArray[0]
                    }
                    
                    if let _ = parsedDict as NSDictionary?
                    {
                        print("data received: \(parsedDict ?? [:])")
                        
                        if let _ = parsedDict?["status"] as? Int {
                            self.order.orderStatus = parsedDict?["status"] as! Status
                        }
                        
                        if let _ = parsedDict?["name"] as? String
                        {
                            self.order.driver_Name = parsedDict?["name"] as! String
                        }
                        
                        if let _ = parsedDict?["vehicle_model"] as? String
                        {
                            self.order.car_Name = parsedDict?["vehicle_model"] as! String
                            
                        }
                        
                        if let _ = parsedDict?["login"] as? String
                        {
                            self.order.driver_phone = parsedDict?["login"] as! String
                            
                        }
                        
                        if let _ = parsedDict?["login"] as? Double
                        {
                            self.order.driver_phone = String(describing: parsedDict?["login"])
                        }
                        
                        
                        if let _ = parsedDict?["driver_id"] as? Int
                        {
                            print("driver id: \( parsedDict?["driver_id"] as? Int ?? 0)")
                            self.order.driver_id = parsedDict?["driver_id"] as! Int
                            if(self.order.driver_id != 0 && self.order.orderStatus == .NEW)
                            {
                                self.order.orderStatus = .ACCEPTED
                            }
                        }
                        if let _ = parsedDict?["eta"] as? String
                        {
                            print("eta: \( parsedDict?["eta"] as? String ?? defaultValue)")
                            let timestring = parsedDict?["eta"] as! String
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
                            if let datePublished = dateFormatter.date(from: timestring){
                                print(datePublished)
                                self.order.eta = datePublished
                            }
                        }
                        
                        //pics
                        if let _ = parsedDict?["profile_pic_url"] as? String
                        {
                            self.order.driver_image = parsedDict?["profile_pic_url"] as! String
                            
                        }
                        if let _ = parsedDict?["vehicle_pic_url"] as? String
                        {
                            self.order.car_image = parsedDict?["vehicle_pic_url"] as! String
                            
                        }
                        if let _ = parsedDict?["pic_before_url"] as? String
                        {
                            self.order.order_image_before = parsedDict?["pic_before_url"] as! String
                            
                        }
                        if let _ = parsedDict?["pic_after_url"] as? String
                        {
                            self.order.order_image_after = parsedDict?["pic_after_url"] as! String
                            
                        }
                        
                        
                    }
                    self.setUserPreferences() //save current status of order
                    completionCallback(true, "")
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "You cannot accept the order")
                }
                
           }
        
    }

    //RECIEVED: order's new status received from socket
    func onOrderStatusChange(parsedDict: NSDictionary){
        
                        //self.orderStatusChanged = true
        
                        print("---------onOrderStatusChanged----------")
                        print("data received: \(parsedDict)")
        
        
                        //set an id in case order been finished before we'd started the app
                        //or in case it's been created by admin without app knowing it
                        if let id = parsedDict["id"] as? Int {
                                    self.order.id = id
                        }
        
                        if let status = parsedDict["status"] as? Int {

                            if(self.order.orderStatus != Status.init(rawValue: status))
                            {
                              self.orderStatusChanged = true
                              self.order.orderStatus = Status.init(rawValue: status)!
                            }
                            
                        }
        
                        if let _ = parsedDict["order_price"] as? Double {
                           self.order.price = parsedDict["order_price"] as! Double
                        }

                        if let _ = parsedDict["debt"] as? Double {
                           self.order.debt = parsedDict["debt"] as! Double
                        }
        
                        if let _ = parsedDict["name"] as? String
                        {
                            self.order.driver_Name = parsedDict["name"] as! String
                        }
                        
                        if let _ = parsedDict["vehicle_model"] as? String
                        {
                            self.order.car_Name = parsedDict["vehicle_model"] as! String
                            
                        }
                        
                        if let _ = parsedDict["login"] as? String
                        {
                            self.order.driver_phone = parsedDict["login"] as! String
                            
                        }
                        
                        if let _ = parsedDict["login"] as? Double
                        {
                            self.order.driver_phone = String(describing: parsedDict["login"])
                            
                        }
        
                        if let notification_id = parsedDict["notification_id"] as? Int
                            {
                                print("notification id: \(notification_id)")
                                self.wsclient?.sendApplyNotification(notification_id: notification_id)
                            }
        
        
        
                        if let _ = parsedDict["driver_id"] as? Int
                        {
                            print("driver id: \( parsedDict["driver_id"] ?? defaultValue)")
                            self.order.driver_id = parsedDict["driver_id"] as! Int
                            if(self.order.driver_id != 0 && self.order.orderStatus == .NEW)
                            {
                                self.order.orderStatus = .ACCEPTED
                            }
                        }
                        if let _ = parsedDict["eta"] as? String
                        {
                            print("eta: \( parsedDict["eta"] as? String ?? defaultValue)")
                            let timestring = parsedDict["eta"] as! String
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                            
                            if let datePublished = dateFormatter.date(from: timestring){
                                print(datePublished)
                                if(self.order.eta != datePublished && self.order.orderStatus == .ACCEPTED)
                                {
                                   print("Prev date: \(String(describing: self.order.eta ?? nil)), new date: \(datePublished)")
                                   self.etaChanged = true
                                }
                                self.order.eta = datePublished
                            }
                        }
        
                        if let actual_inches = parsedDict["actual_inches"] as? Int
                        {
                           self.order.actual_snow_depth = actual_inches
                        }
        
                        if let actual_road_length = parsedDict["actual_road_length"] as? Int
                        {
                          self.order.actual_driveway_length = actual_road_length
                        }
        
                        //pics
                        if let _ = parsedDict["profile_pic_url"] as? String
                        {
                            self.order.driver_image = parsedDict["profile_pic_url"] as! String
                            
                        }
                        if let _ = parsedDict["vehicle_pic_url"] as? String
                        {
                            self.order.car_image = parsedDict["vehicle_pic_url"] as! String
                            
                        }
                        if let _ = parsedDict["pic_before_url"] as? String
                        {
                            self.order.order_image_before = parsedDict["pic_before_url"] as! String
                            
                        }
                        if let _ = parsedDict["pic_after_url"] as? String
                        {
                            self.order.order_image_after = parsedDict["pic_after_url"] as! String
                            
                        }
        
                    self.setUserPreferences() //save current status of order
        
                    //send app-wide notification
                    NotificationCenter.default.post( Notification(name: .onOrderStatusChnaged, object: nil, userInfo: parsedDict as? [AnyHashable : Any]) )
    }

    //get order for user that is not yet finished
    func getUnfinishedOrder(id: Int, completionCallback: @escaping (_: Bool, _ : String) -> ()) {
        
        //let session_id:String = "session_id=" + self.user.SID.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        //let paramString = session_id + "&" + "id=" + String(id)
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
                "is_driver"  : self.user.isDriver as AnyObject
            ]
        
        var currentOrder = Order()
        infoRequest(method: .GET, urlString: "/orders/getCurrentOrder", params: params) {(parsedDataDict) in
           
                print("response data: \(parsedDataDict)")
                
                
                if parsedDataDict["success"] as? Int == 0
                {
                    print("Got current(unfinished) order: \(parsedDataDict["data"] as Any)")
                    
                    var parsedDict = parsedDataDict["data"] as? Dictionary<String, Any?>
                    
                    if let parsedDictArray = parsedDataDict["data"] as? [Dictionary<String, Any?>]
                    {
                        parsedDict = parsedDictArray[0]
                    }
                    
                    if let _ = parsedDict as Dictionary<String, Any?>?
                    {
                        print("data received for unfinished order: \(String(describing: parsedDict))")
                        
                        if let _ = parsedDict?["id"] as? Int {
                            currentOrder.id = parsedDict?["id"] as! Int
                        }
                        
                        if let lat = parsedDict?["gps_lat"] as? Double
                        {
                           if let lng = parsedDict?["gps_lng"] as? Double
                           {
                             currentOrder.coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                           }
                        }
                        
                        if let _ = parsedDict?["address"] as? String
                        {
                            currentOrder.address = parsedDict?["address"] as! String
                        }
                        
                        if let status = parsedDict?["status"] as? Int {
                            currentOrder.orderStatus = Status(rawValue: status)!
                        }
                        
                        if let _ = parsedDict?["order_price"] as? Double {
                            currentOrder.price = parsedDict?["order_price"] as! Double
                        }
                        
                        if let _ = parsedDict?["driver_fee"] as? Double {
                            currentOrder.driver_fee = parsedDict?["driver_fee"] as! Double
                        }
                        
                        if let _ = parsedDict?["name"] as? String
                        {
                            currentOrder.driver_Name = parsedDict?["name"] as! String
                        }
                        
                        if let _ = parsedDict?["vehicle_model"] as? String
                        {
                           currentOrder.car_Name = parsedDict?["vehicle_model"] as! String
                        }
                        
                        if let _ = parsedDict?["login"] as? String
                        {
                            currentOrder.driver_phone = parsedDict?["login"] as! String
                        }
                        
                        if let _ = parsedDict?["login"] as? Double
                        {
                            currentOrder.driver_phone = String(describing: parsedDict?["login"])
                        }

                        if let actual_inches = parsedDict?["actual_inches"] as? Int
                        {
                            currentOrder.actual_snow_depth = actual_inches
                        }
                        
                        if let actual_road_length = parsedDict?["actual_road_length"] as? Int
                        {
                            currentOrder.actual_driveway_length = actual_road_length
                        }

                        
            
                        if let _ = parsedDict?["credit_driver_fee"] as? Double, self.user.isDriver {
                            currentOrder.debt = parsedDict?["credit_driver_fee"] as! Double
                        }
                        
                        if let _ = parsedDict?["debt"] as? Double, !self.user.isDriver {
                            currentOrder.debt = parsedDict?["debt"] as! Double
                        }
                        
                        if let _ = parsedDict?["driver_id"] as? Int
                        {
                            print("driver id: \(String(describing: parsedDict?["driver_id"]))")
                            currentOrder.driver_id = parsedDict?["driver_id"] as! Int
                        }
                        
                        if let _ = parsedDict?["eta"] as? String
                        {
                            print("eta: \( parsedDict?["eta"] as? String ?? defaultValue)")
                            let timestring = parsedDict?["eta"] as! String
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                            
                            if let datePublished = dateFormatter.date(from: timestring){
                                print(datePublished)
                                currentOrder.eta = datePublished
                            }
                        }
                        
                        if(self.user.isDriver)
                        {
                           currentOrder = self.convertToUserOrder(dict: parsedDict!)
                        }
                        
                        //pics
                        if let _ = parsedDict?["profile_pic_url"] as? String
                        {
                            currentOrder.driver_image = parsedDict?["profile_pic_url"] as! String
                            
                        }
                        if let _ = parsedDict?["vehicle_pic_url"] as? String
                        {
                            currentOrder.car_image = parsedDict?["vehicle_pic_url"] as! String
                            
                        }
                        if let _ = parsedDict?["pic_before_url"] as? String
                        {
                            currentOrder.order_image_before = parsedDict?["pic_before_url"] as! String
                            
                        }
                        if let _ = parsedDict?["pic_after_url"] as? String
                        {
                            currentOrder.order_image_after = parsedDict?["pic_after_url"] as! String
                            
                        }
                        
                    }
                    
                    //if(currentOrder.id != 0)
                    //{
                        if(self.user.isDriver)
                        {
                            //if(currentOrder.id != self.takenOrder.id)
                            //{
                                self.takenOrder = currentOrder
                                self.setUserPreferences() //save current status of taken order
                            //}
                        }
                        else
                        {
                            self.order = currentOrder
                            self.setUserPreferences() //save current status of order
                        }
                        completionCallback(true, "")
                    //}
                    //else
                    //{
                    //    print("NO UNCOMPLETED ORDER")
                    //
                    //   completionCallback(true, "")
                    //}
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "You cannot accept the order")
                }
            
        }
        
    }


    //check session that is stored in our user preferences
    //session should be checked every time we're logging in
    func checkSession(completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        //let session_id:String = "session_id=" + self.user.SID.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        var params =
            [
                "session_id" : self.user.SID as AnyObject,
            ]
        
          if let device_id = UserDefaults.standard.string(forKey: "APToken")  {
                  params["device_id"] = device_id as AnyObject
          }
        
        infoRequest(method: .GET, urlString: "/users/checkSession", params: params) {(parsedDataDict) in
           
                print("response data: \(parsedDataDict)")
                
                if parsedDataDict["data"] as? NSDictionary != nil, parsedDataDict["success"] as? Int == 0
                {
                    print("data received: \(parsedDataDict["data"] as Any)")
                   
                    
                        let parsedDict = parsedDataDict ["data"] as! NSDictionary
                    
                            if let _ = parsedDict["id"] as? Int {
                                self.user.user_id = parsedDict["id"] as! Int
                                
                                if let user_name = parsedDict["name"] as? String
                                {
                                    self.user.name = user_name
                                }
                                
                                if let userpicurl = parsedDict["profile_pic_url"] as? String
                                {self.user.user_pic = userpicurl}
                                
                                if let is_driver = parsedDict["is_driver"] as? Bool
                                {
                                  self.user.isDriver = is_driver
                                }
                                
                                if let approved = parsedDict["approved"] as? Bool
                                {
                                    self.user.approved = approved
                                }
                                
                                if let approved = parsedDict["approved"] as? Int
                                {
                                    self.user.approved = approved > 0 ? true : false
                                }
                                
                                if let vehicle_model = parsedDict["vehicle_model"] as? String
                                {
                                    self.user.car_name = vehicle_model
                                }
                                
                                if let carpicurl = parsedDict["vehicle_pic_url"] as? String
                                {
                                    self.user.car_pic = carpicurl
                                }
                                
                                if let userlogin = parsedDict["login"] as? String
                                {
                                  self.user.number = userlogin
                                }
                                
                                if let usermail = parsedDict["email"] as? String
                                {
                                    self.user.email = usermail
                                }
                                
                                if let webtoken = parsedDict["webtoken_id"] as? String
                                {
                                    self.user.webTokenID = webtoken
                                }
                                
                                if let address = parsedDict["default_address"] as? String
                                {
                                    self.user.homeAddress = address
                                }
                                
                                if let def_lat = parsedDict["default_lat"] as? Double, let def_lng = parsedDict["default_lng"] as? Double
                                {
                                    self.user.homeAddressCoordinates = CLLocationCoordinate2D(latitude: def_lat as CLLocationDegrees, longitude: def_lng as CLLocationDegrees)
                                }
                                
                                completionCallback(true, "")
                            }
                            else
                            {
                                let error = parsedDataDict["error"] as? String
                                completionCallback(false, error != nil ? error! : "Error checking session!")
                            }
                    
                  //completionCallback(true, "")
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "Your login session is not valid on this device or Internet connection is gone. Try to login again")
                    if( parsedDataDict["success"] as? Int == 0) //check successfull but session is still invalid
                    {
                      self.LogOut() //
                    }
                }
            
        }
        
    }
    
    
    //check temporary onboarding session
    //check session that is stored in our user preferences
    //session should be checked every time we're logging in
    func checkSessionOnBoarding(completionCallback: @escaping (_: Bool, _ : String, _: Dictionary<String, Any>) -> ()){
        
        let params =
            [
                "session_id" : self.user.SIDunaccepted as AnyObject,
            ]
        
       infoRequest(method: .GET, urlString: "/users/registerGetDriverStepInfo", params: params) {(parsedDataDict) in
            
            print("response data: \(parsedDataDict)")
        
            if parsedDataDict["data"] as? Dictionary<String, Any?> != nil, parsedDataDict["success"] as? Int == 0
            {
                print("data received: \(parsedDataDict["data"] as! NSDictionary)")
                
                
                let parsedDict = parsedDataDict ["data"] as! NSDictionary
                
                if let sid = parsedDict["session_id"] as? String {
                
                    self.user.SID = sid
                    self.user.SIDunaccepted = sid
                    self.setUserPreferences()
                }
                
                if let login = parsedDict["login"] as? String {
                    
                    self.user.number = login
                }
                
                if let stepsInfo =  parsedDict["steps_info"] as? Dictionary<String, Any>
                {
                    self.onboarding_info = stepsInfo
                    completionCallback(true, "", stepsInfo)
                }
                else
                {
                    completionCallback(false, "No registration data for this driver", [:])
                }

            }
            else
            {
                let error_message = parsedDataDict["error"] as? String
                completionCallback(false, error_message ?? "Your login session is not valid on this device or Internet connection is gone. Try to login again", [:])
            }
            
        }
        
    }

    

    //send request to get session
    //session should be checked every time we're logging in
    func generateSession(token: String, completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        //let session_id:String = "session_id=" + self.user.SID.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let params =
            [
                "token" : token as AnyObject,
                ]
        
        infoRequest(method: .GET, urlString: "/users/generateSessionFromToken", params: params) {(parsedDataDict) in
            
            print("response data: \(parsedDataDict)")
            
            if parsedDataDict["data"] as? String != nil, parsedDataDict["success"] as? Int == 0
            {
                print("data received: \(parsedDataDict["data"] as Any)")
                
                if let sid = parsedDataDict["data"] as? String {
                    self.user.SID = sid
                    self.user.SIDunaccepted = sid
                    self.setUserPreferences()
                    print("session id: ")
                    completionCallback(true, "")
                }
                else
                {
                    let error = parsedDataDict["error"] as? String
                    completionCallback(false, error != nil ? error! : "Error checking session!")
                }
            }
            else
            {
                let error_message = parsedDataDict["error"] as? String
                completionCallback(false, error_message ?? "Your login session is not valid on this device or Internet connection is gone. Try to login again")
                if( parsedDataDict["success"] as? Int == 0) //check successfull but session is still invalid
                {
                    self.LogOut()
                }
            }
            
        }
        
    }
    
    //check version
    //version should be checked every time we're logging in
    func checkVersion(completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        //let session_id:String = "session_id=" + self.user.SID.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let params =
            [
                "app_version" : "1.0.26" as AnyObject,
                "type": "ios" as AnyObject
            ]
        
        infoRequest(method: .GET, urlString: "/users/versionCheck", params: params) {(parsedDataDict) in
            
            print("response data: \(parsedDataDict)")
            
            if parsedDataDict["data"] as? NSDictionary != nil, parsedDataDict["success"] as? Int == 0
            {
                print("data received: \(parsedDataDict["data"] as Any)")
               
                
                let parsedDict = parsedDataDict ["data"] as! NSDictionary
                
                if let server_version = parsedDict["latest_version"] as? String {
                    
                    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                      if(version != server_version)
                      {
                         completionCallback(true, "It is recommended to update your application to version \(server_version)! The old version may not work with changes made on server to make your application more stable")
                      }
                    }
                    else{
                      print("VERSION CHECK COULD NOT RECOGNIZE SERVER VERSION")
                    }
                }
                else
                {
                    let error = parsedDataDict["error"] as? String
                    completionCallback(false, error != nil ? error! : "Error checking version!")
                }
             
            }
            else
            {
                let error_message = parsedDataDict["error"] as? String
                completionCallback(false, error_message ?? "Version check call is invalid")
            }
            
        }
        
    }

    
    
    //put user offline(if user does not want to update his/her locations and receive any messages)
    func goOffline(completionCallback: @escaping (_: Bool, _ : String) -> ()){
        
        self.isOnline = false
        
        let params =
            [
                "session_id" : self.user.SID as AnyObject,
            ]
        
        infoRequest(method: .GET, urlString: "/users/goOffline", params: params) {(parsedDataDict) in
           
                print("response data: \(parsedDataDict)")
                
                if parsedDataDict["success"] as? Int == 0
                {
                    print("data received: \(parsedDataDict["data"] as Any)")
                    completionCallback(true, "")
                }
                else
                {
                    let error_message = parsedDataDict["error"] as? String
                    completionCallback(false, error_message ?? "Session is invalid")
                }
            
        }
        
    }
    

    //--------------------------- Manage all requests to server/
    
    
    //convertion dict to Order for driver
    func convertToUserOrder(dict: Dictionary<String,Any?>) -> Order
    {
     var order = Order()
     
        if let id = dict["id"] as? Int
        {
            order.id = id
        }
        
        if let status = dict["status"] as? Int
        {
            order.orderStatus = Status(rawValue: status)!
        }
        
        if let deicing = dict["deicing"] as? Int
        {
           order.deicing = deicing
        }

        if let length = dict["road_length"] as? Int
        {
            order.driveWayLength = length
        }

        if let driveway_marked = dict["driveway_marker"] as? Int
        {
            order.markersThere = driveway_marked == 0 ? false : true
        }

        if let _ = dict["driveway_type"] as? String
        {
            if(dict["driveway_type"] as? String == "a"){
               order.gravelDriveway = false
               order.asphaltDriveway = true
            }
            
            if(dict["driveway_type"] as? String == "g"){
                order.gravelDriveway = true
                order.asphaltDriveway = false
            }
        }

        if let other = dict["other_consideration"] as? String
        {
            if(other != "" && other != "<null>"){
                order.otherIssues = true
                order.issuesThere = other
            }
        }

        if let timestring = dict["created"] as? String
        {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            if let datePublished = dateFormatter.date(from: timestring){
              order.time_stamp = datePublished
            }
        }

        if let lat = dict["gps_lat"] as? CLLocationDegrees, let lng = dict["gps_lng"] as? CLLocationDegrees
        {
            order.coordinates = CLLocationCoordinate2D(latitude: lat , longitude: lng)
        }
        
        if let addr = dict["address"] as? String
        {
            order.address = addr
        }
        
        if let price = dict["order_price"] as? Double
        {
           order.price = price
        }
        
        if let tax = dict["tax"] as? Double
        {
            order.tax = tax
        }
        
        if let credit_driver_fee = dict["credit_driver_fee"] as? Double
        {
            order.debt = credit_driver_fee
        }
        
        if let driver_fee = dict["driver_fee"] as? Double
        {
           order.driver_fee = driver_fee
        }
        
        if let charge_id = dict["charge_id"] as? String
        {
            order.charge_id = charge_id
        }
        
        if let name = dict["name"] as? String
        {
            order.client_name = name
        }
        
        if let cfw = dict["clean_front_walkway"] as? Int
        {
            order.clean_front_walkway = cfw == 1 ? true : false
        }

        if let cbw = dict["clean_back_walkway"] as? Int
        {
            order.clean_back_walkway = cbw == 1 ? true : false
        }
        
        if let csw = dict["clean_side_walkway"] as? Int
        {
            order.clean_side_walkway = csw == 1 ? true : false
        }
        
        if let login = dict["login"] as? String
        {
            order.client_phone = login
        }
        
        if let _ = dict["login"] as? Double
        {
            order.client_phone = String(describing: dict["login"])
        }

        if let actual_inches = dict["actual_inches"] as? Int
        {
             order.actual_snow_depth = actual_inches
        }
        
        if let actual_road_length = dict["actual_road_length"] as? Int
        {
             order.actual_driveway_length = actual_road_length
        }

        
     return order
    }
    

    func orderIsValidToTake(order: Order?) -> Bool{
     
        if order == nil
        {
          return false
        }

        return(order?.id != 0 && order?.address != "" && !(order?.coordinates.latitude == 0 && order?.coordinates.longitude == 0) && order?.price != 0)
        
    }
    
    
    //storing user preferences
    func getUserPreferences(){
        
        if let savedSIDValue = UserDefaults.standard.string(forKey: "SID") {
            self.user.SID = savedSIDValue
        }
        
        if let SIDunaccepted = UserDefaults.standard.string(forKey: "SIDunaccepted") {
            self.user.SIDunaccepted = SIDunaccepted
        }
        
        if let savedNameValue = UserDefaults.standard.string(forKey: "username") {
            self.user.name = savedNameValue
        }
        
        if let savedUIDValue = UserDefaults.standard.integer(forKey: "UID") as Int?{
             self.user.user_id = savedUIDValue
        }
        
        if let savedDriverValue = UserDefaults.standard.bool(forKey: "isDriver") as Bool? {
            self.user.isDriver = savedDriverValue
        }
        
        if let savedNumberValue = UserDefaults.standard.string(forKey: "userNumber") {
            self.user.number = savedNumberValue
        }
        
        if let savedEmailValue = UserDefaults.standard.string(forKey: "userEmail") {
            self.user.email = savedEmailValue
        }
       
        if let savedUserpic = UserDefaults.standard.string(forKey: "user_pic") {
            self.user.user_pic = savedUserpic
        }

        if let savedCarpic = UserDefaults.standard.string(forKey: "car_pic") {
            self.user.car_pic = savedCarpic
        }
       
        if let savedCarname = UserDefaults.standard.string(forKey: "car_name") {
            self.user.car_name = savedCarname
        }
        
        if let savedWebToken = UserDefaults.standard.string(forKey: "webTokenID") {
            self.user.webTokenID = savedWebToken
        }

        
        
        //takenOrder (the order driver took)
        if let savedOrderId = UserDefaults.standard.integer(forKey: "savedOrder") as Int? {
            self.takenOrder.id = savedOrderId
        }
        
        if let savedOrderLng = UserDefaults.standard.string(forKey: "savedOrderLng") {
            self.takenOrder.coordinates.longitude = CLLocationDegrees(savedOrderLng)!
        }

        if let savedOrderLat = UserDefaults.standard.string(forKey: "savedOrderLat") {
            self.takenOrder.coordinates.latitude = CLLocationDegrees(savedOrderLat)!
        }
        
        if let savedOrderAddr = UserDefaults.standard.string(forKey: "savedOrderAddr") {
            self.takenOrder.address = savedOrderAddr
        }
        
        if let savedOrderUserPhone = UserDefaults.standard.string(forKey: "savedOrderPhone") {
            self.takenOrder.client_phone = savedOrderUserPhone
        }
        
        if let savedOrderUserEta = UserDefaults.standard.string(forKey: "savedOrderETA") {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            self.takenOrder.eta = dateFormatter.date(from: savedOrderUserEta)
        }
        
        if let savedOrderPrice = UserDefaults.standard.string(forKey: "savedOrderPrice") {
            self.takenOrder.price = Double(savedOrderPrice)!
        }
        
        if let savedOrderFee = UserDefaults.standard.string(forKey: "savedOrderFee") {
            self.takenOrder.driver_fee = Double(savedOrderFee)!
        }
        
        if let savedOrderTax = UserDefaults.standard.string(forKey: "savedOrderTax") {
            self.takenOrder.tax = Double(savedOrderTax)!
        }
        
        if let savedOrderRoadLen = UserDefaults.standard.integer(forKey: "savedOrderRoadLen") as Int? {
            self.takenOrder.driveWayLength = savedOrderRoadLen
        }
        
        if let savedOrderStatus = UserDefaults.standard.integer(forKey: "savedOrderStatus") as Int? {
            self.takenOrder.orderStatus = Status(rawValue: savedOrderStatus)!
            
        }
        
        if let savedOrderCharge = UserDefaults.standard.string(forKey: "savedOrderCharge")  {
            self.takenOrder.charge_id = savedOrderCharge
        }
        
        
        
        
        //placedOrder
        if let savedOrderId = UserDefaults.standard.integer(forKey: "savedOrderClient") as Int? {
            self.order.id = savedOrderId
        }
        
        if let savedOrderLng = UserDefaults.standard.string(forKey: "savedOrderLngClient") {
            self.order.coordinates.longitude = CLLocationDegrees(savedOrderLng)!
        }
        
        if let savedOrderLat = UserDefaults.standard.string(forKey: "savedOrderLatClient") {
            self.order.coordinates.latitude = CLLocationDegrees(savedOrderLat)!
        }
        
        if let savedOrderAddr = UserDefaults.standard.string(forKey: "savedOrderAddrClient") {
            self.order.address = savedOrderAddr
        }
        
        if let savedOrderDriverPhone = UserDefaults.standard.string(forKey: "savedOrderPhoneDriver") {
            self.order.driver_phone = savedOrderDriverPhone
        }

        if let savedOrderDriverId = UserDefaults.standard.integer(forKey: "savedOrderDriverId") as Int? {
            self.order.driver_id = savedOrderDriverId
        }

        if let savedOrderEta = UserDefaults.standard.string(forKey: "savedOrderETAClient") {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            self.order.eta = dateFormatter.date(from: savedOrderEta)
        }
        
        if let savedOrderPriceClient = UserDefaults.standard.string(forKey: "savedOrderPriceClient"){
            self.order.price = Double(savedOrderPriceClient)!
        }
        
        if let savedOrderTaxClient = UserDefaults.standard.string(forKey: "savedOrderTaxClient"){
            self.order.tax = Double(savedOrderTaxClient)!
        }
        
        if let savedOrderRoadLenClient = UserDefaults.standard.integer(forKey: "savedOrderRoadLenClient") as Int? {
            self.order.driveWayLength = savedOrderRoadLenClient
            
        }
        
        if let savedOrderStatusClient = UserDefaults.standard.integer(forKey: "savedOrderStatusClient") as Int? {
            self.order.orderStatus = Status(rawValue: savedOrderStatusClient)!
            
        }

        if let savedOrderChargeClient = UserDefaults.standard.string(forKey: "savedOrderChargeClient")  {
            self.order.charge_id = savedOrderChargeClient
            
        }
        
    }
    
    func setUserPreferences(){
       UserDefaults.standard.set(self.user.SID, forKey: "SID")
       UserDefaults.standard.set(self.user.SIDunaccepted, forKey: "SIDunaccepted")
       UserDefaults.standard.set(self.user.number, forKey: "userNumber")
       UserDefaults.standard.set(self.user.user_id, forKey: "UID")
       UserDefaults.standard.set(self.user.isDriver, forKey: "isDriver")
       UserDefaults.standard.set(self.user.name, forKey: "username")
       UserDefaults.standard.set(self.user.car_name, forKey: "car_name")
       UserDefaults.standard.set(self.user.car_pic, forKey: "car_pic")
       UserDefaults.standard.set(self.user.user_pic, forKey: "user_pic")
       UserDefaults.standard.set(self.user.webTokenID, forKey: "webTokenID")
    
        
       //save order taken by driver
       UserDefaults.standard.set(self.takenOrder.id, forKey: "savedOrder")
       UserDefaults.standard.set(self.takenOrder.coordinates.latitude, forKey: "savedOrderLat")
       UserDefaults.standard.set(self.takenOrder.coordinates.longitude, forKey: "savedOrderLng")
       UserDefaults.standard.set(self.takenOrder.address, forKey: "savedOrderAddr")
       UserDefaults.standard.set(self.takenOrder.client_phone, forKey: "savedOrderPhone")
       
       let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let _ = self.takenOrder.eta as Date?
        {
        let date_str = dateFormatter.string(from: self.takenOrder.eta!)
        UserDefaults.standard.set(date_str, forKey: "savedOrderETA")
        }
       UserDefaults.standard.set("\(self.takenOrder.price)", forKey: "savedOrderPrice")
       UserDefaults.standard.set("\(self.takenOrder.driver_fee)", forKey: "savedOrderFee")
       UserDefaults.standard.set("\(self.takenOrder.tax)", forKey: "savedOrderTax")
       UserDefaults.standard.set(self.takenOrder.driveWayLength, forKey: "savedOrderRoadLen")
       UserDefaults.standard.set(self.takenOrder.orderStatus.rawValue, forKey: "savedOrderStatus")
       UserDefaults.standard.set(self.takenOrder.charge_id, forKey: "savedOrderCharge")
        
       //save order placed b y client
        UserDefaults.standard.set(self.order.id, forKey: "savedOrderClient")
        UserDefaults.standard.set(self.order.coordinates.latitude, forKey: "savedOrderLatClient")
        UserDefaults.standard.set(self.order.coordinates.longitude, forKey: "savedOrderLngClient")
        UserDefaults.standard.set(self.order.address, forKey: "savedOrderAddrClient")
        UserDefaults.standard.set(self.order.driver_phone, forKey: "savedOrderPhoneDriver")
        UserDefaults.standard.set(self.order.driver_id, forKey: "savedOrderDriverId")
         if let _ = self.order.eta as Date?
         {
          let date_str_order = dateFormatter.string(from: self.order.eta!)
          UserDefaults.standard.set(date_str_order, forKey: "savedOrderETAClient")
         }
        UserDefaults.standard.set("\(self.order.price)", forKey: "savedOrderPriceClient")
        UserDefaults.standard.set("\(self.order.tax)", forKey: "savedOrderTaxClient")
        UserDefaults.standard.set(self.order.driveWayLength, forKey: "savedOrderRoadLenClient")
        UserDefaults.standard.set(self.order.orderStatus.rawValue, forKey: "savedOrderStatusClient")
        UserDefaults.standard.set(self.order.charge_id, forKey: "savedOrderChargeClient")
        
       //sync, i. e. save on drive
       UserDefaults.standard.synchronize()
    }
 
    //save app Settings
    func saveAppSettings()
    {
        UserDefaults.standard.set( self.soundsOn, forKey: "soundsOn")
        UserDefaults.standard.synchronize()
    }
    
    
    //log out
    func LogOut()
    {
       self.isOnline = false
       self.user = User(u_id: 0, u_number: "", u_name: "", u_sid: "", u_isDriver: false, u_email: "")
       self.order = Order()
       self.takenOrder = Order()
       self.setUserPreferences()
       self.closeSocketConnection()
        
        // Clear memory cache right away.
        ImageCache.default.clearMemoryCache()
        // Clear disk cache. This is an async operation.
        ImageCache.default.clearDiskCache()

        //clear upload manager steps
        let uploadManager = UploadsManager.sharedInstance
        uploadManager.clearAllOnboardingUploads()
 
        
    }
    
    func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    //load image and return nil if not managed
    func load_image(urlString:String, handler: @escaping (UIImage?)->() )
    {
        print("getting image from URL: \(urlString)")
        let imgURL: NSURL = NSURL(string: self.urlBase+"/"+urlString)!
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            if let imageData:NSData = NSData(contentsOf: imgURL as URL) {
            // When from background thread, UI needs to be updated on main_queue
                DispatchQueue.main.async {
                handler(UIImage(data: imageData as Data))
               
                }
            }
        }
    }
        
 //--------------------------------------------------------------------------------------------------------------
 //web socket functions
    public func openSocketConnection()
    {
        
      print("Socket: \(String(describing: self.wsclient)). LoggedOut: \(self.gotLoggedOut)")
      if(self.gotLoggedOut)
      {
        print("CLIENT GOT LOGGED OUT. SOCKET CONNECTION IS OUT")
        return
      }

      if let _ = self.wsclient
       {
        if(!(self.wsclient?.socketConnecting)!)
        {
            print("CONNECTING TO SOCKET")
            self.wsclient = SnohubSocket(url_base: self.socketBase, session_id: self.user.SID)
            self.wsclient?.openSocketConnection()
        }
        else
        {
          print("WAITING FOR CONNECTION")
        }
      }
      else
      {
        print("SOCKET IS BEING CREATED")
        self.wsclient = SnohubSocket(url_base: self.socketBase, session_id: self.user.SID)
        if let _ = self.wsclient as SnohubSocket?
        {
            self.wsclient?.openSocketConnection()
        }
      }
        
    }
    
    public func closeSocketConnection()
    {
        self.wsclient?.closeSocketConnection()
        //socketCheckTimer?.invalidate()
        //self.socketCheckTimer = nil
        
    }

    //startSocketTimer
    public func startSocketTimer()
    {
      socketCheckTimer?.invalidate()
      self.socketCheckTimer = nil
      
      print("SETTING SOCKET CHECK TIMER")
        self.socketCheckTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(DataManager.checkSocket), userInfo: nil, repeats: true)
        RunLoop.current.add(self.socketCheckTimer!, forMode: RunLoopMode.commonModes)
    }
    
    public func stopSocketTimer()
    {
        socketCheckTimer?.invalidate()
        self.socketCheckTimer = nil
    }
    
    //timer function for socket connection check
    public func checkSocket()
    {
        print("SOCKET CHECK")
        if(self.gotLoggedOut)
        {
            //stop timer
            socketCheckTimer?.invalidate()
            self.socketCheckTimer = nil
            
            //log out
            self.LogOut()
            
            //send app-wide notification about logging out
            NotificationCenter.default.post( Notification(name: .onSocketLogOut, object: nil, userInfo: nil) )
            
            return
        }
        
        if let _ = self.wsclient
        {
            if( self.user.SID != "" && isOnline && !(self.wsclient?.socketConnected)! && !(self.wsclient?.socketConnecting)!)
            {
                self.openSocketConnection()
            }
        }
    }
    
 //--------------------------------------------------------------------------------------------------------------
 //web socket functions

    //useful functions
    func clearNumber(testStr:String?) -> String? {
        let allowedCharacters = "+1234567890"
        let charset = CharacterSet.init(charactersIn: allowedCharacters).inverted
        return (testStr?.trimmingCharacters(in: charset))
    }
    
    func readConfig() //read config from config plist
    {
        
        //get app settings
        if let soundsOn = UserDefaults.standard.bool(forKey: "soundsOn") as Bool? {
            self.soundsOn = soundsOn
        }
        
        var myDict: NSDictionary?
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = myDict {
            print("Config dictionary: \(dict)")
            
            if let host = dict["host"] as? String
            {
              self.urlBase = host
            }
            
            if let socket_addr = dict["socket_addr"] as? String
            {
               self.socketBase = socket_addr
            }
            
            if let stripe_public_key = dict["stripe_public_key"] as? String
            {
                self.stripePublicKey = stripe_public_key
            }
            
            if let roadLengths = dict["roadLengths"] as? Array<String>
            {
                self.roadLengths = roadLengths
            }
            
            if let snowDepthMax = dict["snowDepthMax"] as? Int
            {
                for i in 1...snowDepthMax
                {
                   self.snowDepthArray.append("\(i)\"")
                }
            }
            
        }
    }
    
}

extension Notification.Name {
    static let onOrderStatusChnaged = Notification.Name("ORDER_STATUS_CHANGED")
    static let onSocketDisconnected = Notification.Name("SOCKET_DISCONNECTED")
    static let onSocketLogOut = Notification.Name("SOCKET_LOGGED_OUT")
    static let onOrdersUpdated = Notification.Name("ORDERS_UPDATED")
    static let onDriversUpdated = Notification.Name("DRIVERS_UPDATED")
    static let onBoardingStepFinished = Notification.Name("ONBOARDING_STEP_FINISHED")
    static let bytesSendForStep = Notification.Name("BYTES_SENT_FOR_STEP")
}


