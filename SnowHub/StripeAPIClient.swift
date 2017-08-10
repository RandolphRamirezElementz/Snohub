//
//  StripeAPIClient.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/23/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//
import Foundation
import Stripe

class StripeAPIClient: NSObject, STPBackendAPIAdapter {
    
    static let sharedClient = StripeAPIClient()
    let session: URLSession
    var baseURLString: String? = nil
    var defaultSource: STPCard? = nil
    var sources: [STPCard] = []
    var dataManager = DataManager.sharedInstance
    
    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        self.session = URLSession(configuration: configuration)
        super.init()
    }
    
    func decodeResponse(_ response: URLResponse?, error: NSError?) -> NSError? {
        if let httpResponse = response as? HTTPURLResponse
            , httpResponse.statusCode != 200 {
            return error ?? NSError.networkingError(httpResponse.statusCode)
        }
        return error
    }
    
    func completeCharge(_ result: STPPaymentResult?, amount: Int, completion: @escaping STPErrorBlock) {
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            let error = NSError(domain: StripeDomain, code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Incorrect server base URL"
                ])
            completion(error)
            return
        }
        let path = "/customer/charge"
        let url = baseURL.appendingPathComponent(path)
        let params: [String: AnyObject] = [
            "source": result?.source.stripeID as AnyObject,
            "session_id": dataManager.user.SID as AnyObject,
            "lat" : String(dataManager.order.coordinates.latitude) as AnyObject,//.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!,
            "lng" : String(dataManager.order.coordinates.longitude) as AnyObject,//.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!,
            "address" : dataManager.order.address as AnyObject, //.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            "driveway_marker"  : "\(dataManager.order.markersThere)" as AnyObject,
            "driveway_type"  : (dataManager.order.gravelDriveway ? "g":"a") as AnyObject,
            "road_length" : String(dataManager.order.driveWayLength) as AnyObject,
            "deicing" : "\(dataManager.order.deicing)"  as AnyObject,
            "area"    : (dataManager.order.county_area == "Fairfield" ? 1 : 2) as AnyObject,
            "other_consideration"   : dataManager.order.issuesThere as AnyObject,
            "services_now" : "\(dataManager.order.serviceNow)"  as AnyObject,
            "services_next" : "\(dataManager.order.serviceNext)"  as AnyObject,
            "services_every" : "\(dataManager.order.serviceEvery)"  as AnyObject,
            "promo_code": dataManager.order.promo_code as AnyObject,
            "walkways_number" : "\(dataManager.order.walkways_number)"  as AnyObject,
            "clean_front_walkway": "\(dataManager.order.clean_front_walkway)" as AnyObject,
            "clean_back_walkway" : "\(dataManager.order.clean_back_walkway)" as AnyObject,
            "clean_side_walkway" : "\(dataManager.order.clean_side_walkway)" as AnyObject
        ]
        let request = URLRequest.request(url, method: .POST, params: params)
        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
            do
            {
                //if network error
                DispatchQueue.main.async {
                    print("Charge response: \(String(describing: urlResponse))")
                    if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
                        completion(error)
                        return
                    }
                }

               if(data == nil)
               {
                DispatchQueue.main.async {
                    let err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "Order hadn't been created. No valid response came"])
                    completion(err)
                }
                return
               }
                
               let parsedDataDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
               print("response data: \(parsedDataDict)")
                
               if parsedDataDict["data"] as? NSDictionary != nil, parsedDataDict["success"] as? Int == 0
                {
                    if let data = parsedDataDict["data"] as? NSDictionary
                    {
                        if let insert_id = data["id"] as? Int
                            {
                                self.dataManager.order.orderStatus = .NEW
                                self.dataManager.order.id = insert_id
                                self.dataManager.setUserPreferences()
                                completion(nil)
                                return
                            }
                        else
                        {
                            let err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "Order hadn't been created"])
                            completion(err)
                            return
                        }
                    }
                    else
                    {
                        var err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "Order hadn't been created"])
                        if let e = parsedDataDict["error"] as? String
                        {
                                err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: e])
                        }
                        completion(err)
                        return
                    }
                }
               else
               {
                var err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "Order hadn't been created"])
                if let e = parsedDataDict["error"] as? String
                {
                    err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: e])
                }
                completion(err)
                return
               }
               
            }
            catch let error
            {
                print("Error converting to json", error);
                let err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "Error converting json"])
                completion(err)
            }
            
            
        }
        task.resume()
    }
    
    @objc func retrieveCustomer(_ completion: @escaping STPCustomerCompletionBlock) {
        guard let key = Stripe.defaultPublishableKey() , !key.contains("#") else {
            let error = NSError(domain: StripeDomain, code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Please set stripePublishableKey to your account's test publishable key in CheckoutViewController.swift"
                ])
            completion(nil, error)
            return
        }
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            // This code is just for demo purposes - in this case, if the example app isn't properly configured, we'll return a fake customer just so the app works.
            let customer = STPCustomer(stripeID: "cus_test", defaultSource: self.defaultSource, sources: self.sources)
            completion(customer, nil)
            return
        }
        let path = "/customer"
        let url = baseURL.appendingPathComponent(path)
        let request = URLRequest.request(url, method: .GET, params: ["id":String(dataManager.user.user_id) as AnyObject, "session_id": dataManager.user.SID as AnyObject])
        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
            DispatchQueue.main.async {
                let deserializer = STPCustomerDeserializer(data: data, urlResponse: urlResponse, error: error)
                
                if let error = deserializer.error {
                    completion(nil, error)
                    return
                } else if let customer = deserializer.customer {
                    print("\(deserializer)")
                    print("customer returned: \(customer)")
                    completion(customer, nil)
                }
            }
        }
        task.resume()
    }
    
    @objc func selectDefaultCustomerSource(_ source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
        
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            if let token = source as? STPToken {
                self.defaultSource = token.card
            }
            completion(nil)
            return
        }
        let path = "/customer/default_source"
        let url = baseURL.appendingPathComponent(path)
        let params = [
            "source": source.stripeID as Any,
            "session_id": dataManager.user.SID as AnyObject
            ]
        let request = URLRequest.request(url, method: .POST, params: params as [String : AnyObject])
        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
            DispatchQueue.main.async {
                if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
        task.resume()
    }
    
    @objc func attachSource(toCustomer source: STPSourceProtocol, completion: @escaping STPErrorBlock) {
      
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            if let token = source as? STPToken, let card = token.card {
                self.sources.append(card)
                self.defaultSource = card
            }
            completion(nil)
            return
        }
        let path = "/customer/sources"
        let url = baseURL.appendingPathComponent(path)
        let params = [
            "source": source.stripeID as Any,
            "session_id": dataManager.user.SID as AnyObject
            ]
        let request = URLRequest.request(url, method: .POST, params: params as [String : AnyObject])
        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
            DispatchQueue.main.async {
                if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
        task.resume()
    }
    
    @objc func captureFunds(completion: @escaping STPErrorBlock) {
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            completion(nil)
            return
        }
        
        dataManager.takenOrder.price -= (dataManager.takenOrder.price * 0.029 - 0.30)
        dataManager.takenOrder.price -= dataManager.takenOrder.tax
        
        let path = "/customer/capture"
        let url = baseURL.appendingPathComponent(path)
        let params = [

            "id"        : "\(dataManager.takenOrder.id)" as AnyObject,
            "session_id": dataManager.user.SID as AnyObject
            
        ]
        print("Capture money with parameters: \(params)")
        let request = URLRequest.request(url, method: .POST, params: params as [String : AnyObject])
        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
            
          do
          {
            //if network error
            DispatchQueue.main.async {
                print("Resp: \(String(describing: urlResponse))")
                if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
                    print("Capturing error: \(error)")
                    completion(error)
                    return
                }
                //completion(nil)
            }
            
            if(data == nil)
            {
                let err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "Order capturing error! No response came from server"])
                completion(err)
                return
            }
            
            let parsedDataDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
            print("Capture response data: \(parsedDataDict)")
            
            if parsedDataDict["success"] as? Int == 0
            {
               completion(nil)
               return
              
            }
            else
            {
                
                var err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "Order hadn't been captured"])
                if let e = parsedDataDict["error"] as? String
                {
                    err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: e])
                }
                completion(err)
                throw(err)
                //return
            }
            
          }
          catch let error
          {
            print("Error converting to json", error);
            let err = NSError(domain: StripeDomain, code: 50, userInfo: [NSLocalizedDescriptionKey: "Error converting json"])
            completion(err)
            }
            
            
            
        }
        task.resume()
    }

    
}
