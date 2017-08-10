//
//  UploadsManager.swift
//  SnowHub
//
//  Created by Liubov Perova on 5/23/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import Foundation
import Kingfisher

class UploadsManager: NSObject, URLSessionDataDelegate, URLSessionTaskDelegate {

    var onboardingSteps:Dictionary! = [:]
    let steps_array = ["1", "2", "3", "4", "6"]
    
    //shared singleton instance
    static let sharedInstance : UploadsManager = {
        let instance = UploadsManager()
        return instance
    }()
    
    override init()
    {
        //self.init()
    }
    
    
    
    //get onboarding steps
    func getOnboardingSteps(){
      
      for (_, number) in  steps_array.enumerated()
      {
        let step_number = number
        let img_name = "onboarding_step_\(step_number)"
        var step = ["image_name": img_name, "progress": 0.0, "finished": false, "started" : false, "active": false] as [String : Any]
       
        if let finished = UserDefaults.standard.bool(forKey: "step_\(step_number)_upload_finished") as Bool? {
            step["finished"] = finished
        }
        
        if let started = UserDefaults.standard.bool(forKey: "step_\(step_number)_upload_started") as Bool? {
            step["started"] = started
        }

        if let progress = UserDefaults.standard.float(forKey: "step_\(step_number)_upload_progress") as Float? {
           step["progress"] = progress
        }
       
        onboardingSteps[step_number] = step
        print()
      }
    }
    
    func storeOnboardingStep(step_number: String){
       
        if let step:Dictionary = self.onboardingSteps[step_number] as? Dictionary<String, Any>
        {
            UserDefaults.standard.set(step["progress"], forKey: "step_\(step_number)_upload_progress")
            UserDefaults.standard.set(step["finished"], forKey: "step_\(step_number)_upload_finished")
            UserDefaults.standard.set(step["started"], forKey: "step_\(step_number)_upload_started")
            //sync, i. e. save on drive
            UserDefaults.standard.synchronize()
        }
    }
    
    func storeAllOnboardingSteps(){
        for (_, step_number) in  steps_array.enumerated()
        {
           self.storeOnboardingStep(step_number: step_number)
        }
    }
    
    func clearAllOnboardingUploads()
    {
        for (_, step_number) in  steps_array.enumerated()
        {
            let img_name = "onboarding_step_\(step_number)"
            let step = ["image_name": img_name, "progress": 0.0, "finished": false, "started" : false, "active": false] as [String : Any]
            
            if let _:Dictionary = self.onboardingSteps[step_number] as? Dictionary<String, Any>
            {
                self.onboardingSteps[step_number] = step
                UserDefaults.standard.set(0.0, forKey: "step_\(step_number)_upload_progress")
                UserDefaults.standard.set(false, forKey: "step_\(step_number)_upload_finished")
                UserDefaults.standard.set(false, forKey: "step_\(step_number)_upload_started")
                //sync, i. e. save on drive
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    
    func startUpload(step_number: String, image: UIImage)
    {
        let dataManager = DataManager.sharedInstance
        if let step:Dictionary = self.onboardingSteps[step_number] as? Dictionary<String, Any>
        {
            print("Onboarding step: \(step_number) had staus started: \(String(describing: step["started"])), finished: \(String(describing: step["finished"])), progress: \(String(describing: step["progress"]))")
            if let started = step["started"] as! Bool?, let _ = step["finished"] as! Bool?
            {
                //step been started but not finished - so we need to restart it
                if !started //&& !finished
                {
                    //parameters
                    let parameters = [
                        "session_id": dataManager.user.SIDunaccepted as Any,
                        "image": image as Any
                    ]
    
                    //start uploading(
                    let pathFile = ImageCache.default.cachePath(forComputedKey: "onboarding_step_\(step_number)")
                    self.postFormData(parameters: parameters, urlstring: "/users/registerDriver/\(step_number)", step_number: step_number, pathFile: pathFile)
        
                }
            }
        }
    }
    
    //Post request with multipart form data - background session
    func postFormData(parameters:Dictionary<String,Any>, urlstring:String, step_number: String, pathFile: String){
        
        let dataManager = DataManager.sharedInstance
        
        let fullString = dataManager.urlBase + urlstring
        guard let url = URL(string: fullString) else {
            print("Error: cannot create URL")
            return
        }
        
        //step
        if var step:Dictionary = self.onboardingSteps[step_number] as? Dictionary<String, Any>
        {
            step["started"] = true
            step["finished"] = false
            step["active"] = true
            step["progress"] = 0.0
            
            //session
            print("starting background session with identifier : \(step_number)")
            let config = URLSessionConfiguration.background(withIdentifier: step_number)
            
            //new session with step identifier
            let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            let boundary = dataManager.generateBoundaryString()
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            let body = NSMutableData()
            
            let mimetype = "image/png"
            let fname = "onboarding_step_\(step_number).jpg"
            
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
            
            step["data_length"] = urlRequest.httpBody?.count
            self.onboardingSteps[step_number] = step
            self.storeOnboardingStep(step_number: step_number)
            
            let task = session.uploadTask(withStreamedRequest: urlRequest)//   (with: urlRequest, fromFile:  URL(fileURLWithPath: pathFile))
            task.resume()
        }
        
    }
    
    //background session delegate methods
    
    //upload progress changed
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        
        if let identifier = session.configuration.identifier as String?
        {
            if var step:Dictionary = self.onboardingSteps[identifier] as? Dictionary<String, Any>
            {
                let progress = Float(totalBytesSent)/Float(totalBytesExpectedToSend)
                let userInfo  = ["step_number": identifier, "progress":  (progress)] as [String : Any]
                
                step["progress"] = progress
                self.onboardingSteps[identifier] = step
                
                NotificationCenter.default.post( Notification(name: .bytesSendForStep, object: nil, userInfo: userInfo) )
            
                print("Progress for uploading: \(progress)")
            
            }
        }
        
    }
    
    //session did complete (successfully or not)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let identifier = session.configuration.identifier
        {
           
            if let err = error
            {
                let errorcode =  (err as NSError).code
                print("Error happened while uploading: \(errorcode)")
                
                if(errorcode != -999 && errorcode != 999)
                {
                    self.markStepFinished(identifier: identifier)
                    let userInfo = ["step_number": identifier, "success": false, "error": "Upload session error: \(err.localizedDescription)"] as [String : Any]
                    NotificationCenter.default.post( Notification(name: .onBoardingStepFinished, object: nil, userInfo: userInfo) )
                }
            }
            else
            {
              self.markStepFinished(identifier: identifier)
            }
            
        }
    }
    
    func markStepFinished(identifier: String){
        if var step: Dictionary = self.onboardingSteps[identifier] as? Dictionary<String, Any>
        {
            step["finished"] = true
            step["started"] = false
            step["active"] = false
            self.onboardingSteps[identifier] = step
            self.storeOnboardingStep(step_number: identifier)
            
            let dataManager = DataManager.sharedInstance
            if let _ =  dataManager.onboarding_info[identifier]{
                dataManager.onboarding_info[identifier] = ["step_status":"PASSED"]
            }
        }
    }
    
    
    //session had received some response data
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
       
        
        if let identifier = session.configuration.identifier
        {
            if let _: Dictionary = self.onboardingSteps[identifier] as? Dictionary<String, Any>
            {
                self.markStepFinished(identifier: identifier)
                do
                {
                    if let parsedDataDict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary
                    {
                        print("Upload response returned: \(parsedDataDict)")
                        if let dataDict = parsedDataDict["data"], parsedDataDict["success"] as? Int == 0
                        {
                            print("Upload data returned: \(dataDict)")
                            let userInfo = ["step_number": identifier, "success": true, "error": ""] as [String : Any]
                            NotificationCenter.default.post( Notification(name: .onBoardingStepFinished, object: nil, userInfo: userInfo) )
                        }
                        else
                        {
                            var error = "Could not change the order state"
                            if let err = parsedDataDict["error"] as? String
                            {
                                error = err
                            }
                            let userInfo = ["step_number":identifier, "success": false, "error": error] as [String : Any]
                            NotificationCenter.default.post( Notification(name: .onBoardingStepFinished, object: nil, userInfo: userInfo) )
                        }
                    }
                    else
                    {
                        let userInfo = ["step_number": identifier, "success": false, "error": "Could not decode new url data"] as [String : Any]
                        NotificationCenter.default.post( Notification(name: .onBoardingStepFinished, object: nil, userInfo: userInfo) )
                        print( "Could not decode new url data")
                    }
                }
                catch let error
                {
                    let userInfo = ["step_number": identifier, "success": false, "error": "Error converting to json"] as [String : Any]
                    NotificationCenter.default.post( Notification(name: .onBoardingStepFinished, object: nil, userInfo: userInfo) )
                    print("Error converting to json", error);
                    return
                }
            }
        }
        
    }
    
    
}
