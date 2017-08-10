//
//  SnohubSocket.swift
//  SnowHub
//
//  Created by Liubov Perova on 12/28/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class SnohubSocket: WebSocket, WebSocketDelegate  {
  
    var urlBase = ""
    var socketConnected = false
    var socketConnecting = false
    var currentNotificationId = 0
    var previousLoactionSent = false
    var dataManager:DataManager = DataManager.sharedInstance
    
    init(url_base: String, session_id: String) {
        urlBase = url_base;
        
        let request = NSMutableURLRequest(url: URL(string:urlBase)!)
        request.addValue(session_id, forHTTPHeaderField: "websession")
        super.init(request: request as URLRequest)
        
        setupSocket()
    }
    
    
    public func openSocketConnection()
    {
        self.socketConnecting = true
        self.open()
    }
    
    public func closeSocketConnection()
    {
        self.close()
        self.socketConnected = false
        self.socketConnecting = false
    }
    
    public func setupSocket()
    {
        self.event.open = {
            self.socketConnected = true
            self.socketConnecting = false
            self.previousLoactionSent = false
            self.dataManager.isOnline = true
            
            NotificationCenter.default.post( Notification(name: .onOrdersUpdated, object: nil, userInfo: nil) )
            
            print("socket opened")
            if(self.currentNotificationId != 0)
            {
              self.sendApplyNotification(notification_id: self.currentNotificationId)
            }
    }
       
       self.event.close = {_,_,_ in
            print("socket closed!")
            self.socketConnected = false
            self.socketConnecting = false
            self.previousLoactionSent = false
        }
        
        self.event.message = { message in
            if let text = message as? String {
                print("recv: \(text)")
                do {
                    let objReceived = try text.parseJSONString()
                    
                            print("Object received from socket: \(objReceived ?? defaultValue as AnyObject) )")
                            self.handleMessageObject(object: objReceived as Any?)
                    
                   }
                catch
                {
                    
                }
                
            }
        }
        
    }
    
    //handle socket messages as objects v
    func handleMessageObject(object: Any?)
    {
        
       //in case we didn't get the ERROR as String
      
        
       if let objDict = object as? Dictionary<String, Any>
       {

        if let message: String = objDict["message"] as! String?
          {
            switch message {
            case "ERROR" :
                if let errorCode = objDict["data"] as? String{
                    print("ERROR CODE: \(errorCode)")
                    if errorCode == "403"
                    {
                      //session is invalid
                      print("GOT ERROR. SESSION IS INVALID.")
                      dataManager.gotLoggedOut = true
                    }
                }
                break
                
            case "ORDERS_NEW" :
                if let ordersArray:[NSDictionary] = objDict["data"] as? [NSDictionary]{
                  addNewOrders(newOrders: ordersArray)
                    
                    //send app-wide notification about logging out
                    NotificationCenter.default.post( Notification(name: .onOrdersUpdated, object: nil, userInfo: nil) )
                }
            break
                
            case "ORDER_HIDDEN":
                print("ORDER HIDDEN")
                if let deprecatedOrdersArray = objDict["data"] as? [Int]{
                    removeDeprecatedOrders(deprecatedOrders: deprecatedOrdersArray)
                    
                    //send app-wide notification about logging out
                    NotificationCenter.default.post( Notification(name: .onOrdersUpdated, object: nil, userInfo: nil) )
                }
            break
                
            case "DRIVER_LOCATIONS":
                if let driversArray:[NSDictionary] = objDict["data"] as? [NSDictionary]{
                    dataManager.nearbyDrivers = driversArray
                    dataManager.gotDriversUpdate = true
                    print("Got drivers: \(dataManager.nearbyDrivers)")
                    
                    //send app-wide notification about logging out
                    NotificationCenter.default.post( Notification(name: .onDriversUpdated, object: nil, userInfo: nil) )
                }
            break
            
            case "ETA_SET":
                if let eta = objDict["data"] as? String{
                   setEtaToCurrentOrder(eta: eta)
                }
            break
    
            case "ORDER_STATUS_CHANGE":
                if let orderState:NSDictionary = objDict["data"] as? NSDictionary{
                    print("ORDER_STATUS_CHANGE DATA: \(orderState)")
                    dataManager.onOrderStatusChange(parsedDict: orderState)
                }
            break
                
            case "SETTING_CHANGE":
                if let changedValue:NSDictionary = objDict["data"] as? NSDictionary{
                    changeSettingValue(valueDict: changedValue)
                }
            break
                
            default: break
            }
            
          }

       }
    }
    
    //set ETA to current order
    func setEtaToCurrentOrder(eta: String){
        print("eta: \( eta)")
        if eta != ""
        {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            
            if let datePublished = dateFormatter.date(from: eta){
                print(datePublished)
                dataManager.order.eta = datePublished
                dataManager.etaChanged = true
            }
        }
    }
    
    //change setting value
    func changeSettingValue(valueDict:NSDictionary)
    {
      if let type = valueDict["type"] as? String
      {
        if let value = valueDict["value"] as? String
        {
            switch type
            {
            case "email":
                dataManager.user.email = value
                break
            case  "login":
                dataManager.user.number = value
                break
            default: break
            }
         dataManager.setUserPreferences()
        }
      }
    }
    
    //remove hidden orders from dataManager.nearbyOrders
    func removeDeprecatedOrders(deprecatedOrders:[Int])
    {
        print("Deprecated orders: \(deprecatedOrders)")
        if(!dataManager.nearbyOrders.isEmpty){
            for (index, order) in dataManager.nearbyOrders.enumerated().reversed() {
               if order["id"] as! Int != 0
                {
                   if(deprecatedOrders.contains(order["id"] as! Int))
                   {
                     dataManager.nearbyOrders.remove(at: index)
                   }
                }
            }
        }
    }
    
    //add new orders to dataManager.nearbyOrders
    func addNewOrders(newOrders:[NSDictionary])
    {
        var order_ids = [Int]()
        for (_, order) in dataManager.nearbyOrders.enumerated(){
            order_ids.append((order["id"] as? Int)!)
        }
        
            for (_, order) in newOrders.enumerated() {
                
                if let order_id = order["id"] as? Int
                {
                    if order_id != 0 && !order_ids.contains(order_id)
                    {
                        order_ids.append(order_id)
                        dataManager.nearbyOrders.append(order)
                    }
                }
           }
    }

    
    //SEND: send location with current order ids to update them
    public func sendLocation(location: CLLocation, previous: CLLocation){
        
        let distance = location.distance(from: previous)
        print("Distance from prev. location: \(distance)")
        
        if(distance < 18.0 && previousLoactionSent)
        {
          print("current location: \(location.coordinate). prev. location: \(previous.coordinate)")
          print("difference between prev. location and current is less than 15 m. Do not update to server")
          return
        }
        
        var order_ids = [Int]()
        for (_, order) in dataManager.nearbyOrders.enumerated(){
            order_ids.append((order["id"] as? Int)!)
        }
        
        let message = ["message": "SET_LOCATION",
                       "data": ["coordinates" : ["gps_lat": "\(location.coordinate.latitude)", "gps_lng": "\(location.coordinate.longitude)"],
                                "displayed_orders": order_ids
            ]
            ] as [String : Any]
        
        let messageData = jsonStringify(jsonObject: message as AnyObject)
        print("Set location data: \(messageData)")
        self.send(messageData)
        self.previousLoactionSent = true
    }
    
    
    //SEND: send confirmation message of received notification
    public func sendApplyNotification(notification_id: Int){
        if(self.socketConnected)
        {
            let message = ["message": "APPLY_NOTIFICATION",
                           "data": ["notification_id" : "\(notification_id)"]
                ] as [String : Any]
            
            let messageData = jsonStringify(jsonObject: message as AnyObject)
            print("Notification confirmation data: \(messageData)")
            self.send(messageData)
            self.currentNotificationId = 0
        }
        else
        {
          currentNotificationId = notification_id
          self.open()
        }
    
    }

    
    //SEND: send initial request to get orders around
    public func sendToGetOrdersAround(location: CLLocation){
        
        var order_ids = [Int]()
        for (_, order) in dataManager.nearbyOrders.enumerated(){
            order_ids.append((order["id"] as? Int)!)
        }
        
        let message = ["message": "GET_ORDERS_AROUND",
                       "data": ["gps_lat": "\(location.coordinate.latitude)", "gps_lng": "\(location.coordinate.longitude)"]
                      ] as [String : Any]
        
        let messageData = jsonStringify(jsonObject: message as AnyObject)
        print("Set location data: \(messageData)")
        self.send(messageData)
    }
    
    
    
    
    /// A function to be called when the WebSocket connection's readyState changes to .Open; this indicates that the connection is ready to send and receive data.
    func webSocketOpen()
    {
        print("WebSocket had been opened")
    }
    
    /// A function to be called when the WebSocket connection's readyState changes to .Closed.
    func webSocketClose(_ code: Int, reason: String, wasClean: Bool){
        
        print("Websocket had been closed")
        
    }
    
    /// A function to be called when an error occurs.
    func webSocketError(_ error: NSError){
        print("Socket error: \(error)")
    }

    
    //json stringify object
    func jsonStringify(jsonObject: AnyObject) -> String {
        
        var jsonString: String = ""
        
        switch jsonObject {
            
        case _ as [String: AnyObject] :
            
            let tempObject: [String: AnyObject] = jsonObject as! [String: AnyObject]
            jsonString += "{"
            for (key , value) in tempObject {
                if jsonString.characters.count > 1 {
                    jsonString += ","
                }
                jsonString += "\"" + String(key) + "\":"
                jsonString += jsonStringify(jsonObject: value)
            }
            jsonString += "}"
            
        case _ as [AnyObject] :
            
            jsonString += "["
            for i in 0..<jsonObject.count {
                if i > 0 {
                    jsonString += ","
                }
                jsonString += jsonStringify(jsonObject: jsonObject.object(at: i) as AnyObject)
            }
            jsonString += "]"
            
            
        case _ as String :
            
            jsonString += ("\"" + String(describing: jsonObject) + "\"")
            
        case _ as NSNumber :
            
            if jsonObject.isEqual(NSNumber(value: true)) {
                jsonString += "true"
            } else if jsonObject.isEqual(NSNumber(value: false)) {
                jsonString += "false"
            } else {
                return "\(jsonObject)"
            }
            
        case _ as NSNull :
            
            jsonString += "null"
            
        default :
            
            jsonString += ""
        }
        return jsonString
    }
    
}

//string to object
extension String {
    
    func parseJSONString() throws -> AnyObject? {
        
        let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        if let jsonData = data {
            // Will return an object or nil if JSON decoding fails
            do
            {
                let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers)
                return jsonObject as AnyObject?
            }
            catch {
             return nil
            }
        } else {
            // Lossless conversion of the string was not possible
            return nil
        }
    }
}



