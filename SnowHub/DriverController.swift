//
//  DriverController.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/7/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit
import MobileCoreServices

class DriverController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var viewMap: GMSMapView!
    @IBOutlet weak var subviewTop: TopView!
    @IBOutlet weak var subviewBottom: UIView!
    @IBOutlet weak var subviewGradient: GradientView!
    @IBOutlet weak var subViewOrder: UIView!
    @IBOutlet weak var orderState: UILabel!
    @IBOutlet weak var orderAddress: UILabel!
    
    @IBOutlet weak var ordersTable: UITableView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint! //constraint to control orders table height
    @IBOutlet weak var topConstraint: NSLayoutConstraint! //constraint to control table distance to top border
    @IBOutlet weak var leftBorderConstraint: NSLayoutConstraint! //constraints
    @IBOutlet weak var rightBorderConstraint: NSLayoutConstraint! //constraint to control orders table distance from borders
    @IBOutlet weak var modeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    
    //menu view
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuConstraint: NSLayoutConstraint!
    @IBOutlet weak var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var onlineSwitch: UISwitch!
    @IBOutlet weak var userPic: UIImageView!
    @IBOutlet weak var carPic: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userCar: UILabel!
    @IBOutlet weak var labelVersion: UILabel!
    @IBOutlet weak var labelOnline: UILabel!
    
    var menuShown: Bool = false;
    var targetImageView: UIImageView? //target image view for pic change
    
    //@IBOutlet weak var subviewInfo: InfoView!
    
    var isMapMode = true //map mode or orders review mode
    var isSwipedDown = false //if orders table had been pulled down
    var heightOff = 0 //the shown height of the table
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    var gmsApiKey: String! = "AIzaSyAkuYvAco7GALUTx1T-EG9CAgvgbug5U6U"
    var activeMarker: GMSMarker? = GMSMarker()
    var currentOrderMarkers: Array<GMSMarker> = []
    var dataManager:DataManager = DataManager.sharedInstance
    var pathRectangle = GMSPolyline()
    
    var previousOrders: Dictionary<Int,CLLocationCoordinate2D> = [:]
    var currentOrders:  Dictionary<Int,CLLocationCoordinate2D> = [:]
    
    var lookupAddressResults: Dictionary<String, Any>!
    var fetchedFormattedAddress: String!
    var fetchedAddressLongitude: Double!
    var fetchedAddressLatitude: Double!
    var selectedOrder: Int = 0
    var currentOrder: Dictionary? = Dictionary<String, Any?>()
    var previousLocation: CLLocation = CLLocation()
    var currentLocation: CLLocation = CLLocation()
    
    var positionTimer: Timer? = nil     //timer to update driver's position
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //get your current location
        didFindMyLocation = false;
        locationManager.delegate = self;
        locationManager.requestAlwaysAuthorization();
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()
        
        
        //additional setup of google camera
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 48.857165, longitude: 2.354613, zoom: 14.0)
        viewMap.camera = camera
        viewMap.delegate = self
        do {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                viewMap.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
         } catch {
            NSLog("The style definition could not be loaded: \(error)")
        }
        
        //map padding and other settings when we'd taken an order
        subviewBottom.isUserInteractionEnabled = false
        
        //set order if taken
        setOrderIfTaken()
        
        viewMap.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
        viewMap.settings.consumesGesturesInView = false
        //viewMap.addSubview(ordersTable)
        //subviewGradient.isHidden = true
        viewMap.addSubview(subviewGradient)
        viewMap.addSubview(subviewBottom)
        
        self.view.insertSubview(subviewTop, aboveSubview: ordersTable)
        
        //data table setup
        //dataManager.nearbyOrders = []
        ordersTable.dataSource = self
        ordersTable.delegate = self
        ordersTable.separatorColor = UIColor.clear;
        ordersTable.alwaysBounceVertical = false
        ordersTable.isScrollEnabled = false
        //ordersTable.register(OrderCell.self, forCellReuseIdentifier: "cell")
        ordersTable.reloadData()
        setupTableView()
        
        //add recognizers to datatable
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        self.ordersTable.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.ordersTable.addGestureRecognizer(swipeDown)
    
        stateCheck() //check session and orders
        setupMenu()
     }

    
    override func viewWillAppear(_ animated: Bool) {
        //sessionCheck() //check session
        //setupMenu()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //add observers for orders list and logout
        
        NotificationCenter.default.removeObserver(self, name: .onOrdersUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onSocketLogOut, object: nil)
        
        checkOrders() //checkOrders every time we get to this view
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrdersUpdated(withNotification:)), name: .onOrdersUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onGotLoggedOut(withNotification:)), name: .onSocketLogOut, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
       
        //remove observers 
        NotificationCenter.default.removeObserver(self, name: .onOrdersUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onSocketLogOut, object: nil)

    }
    
    
    //check version
    func versionCheck(){
        dataManager.checkVersion { (success, message) in
            if(success)
            {
//                let alert = UIAlertController(title: "Application update!", message: message, preferredStyle: UIAlertControllerStyle.alert)
//                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
//                    UIAlertAction in
//                    UIApplication.shared.openURL(URL(string: "https://itunes.apple.com/app/snohub-residential-snow-clearing/id1180694078?mt=8")!)
//                }) )
//                
//                DispatchQueue.main.async(execute: {
//                    self.present(alert, animated: true, completion: nil)
//                })
                
            }
            
            //check session and set uo current order
            //self.sessionCheck()
        }
    }
    
    //setup menu
    func setupMenu() {
      onlineSwitch.isOn = true
      onlineSwitch.onTintColor =  UIColor(red:1.0, green:(87.0/255.0), blue:0.0, alpha:1.00)
      userName.text = dataManager.user.name
      userCar.text = dataManager.user.car_name
        
        userPic.layer.borderWidth = 0.0
        userPic.layer.cornerRadius = 27.0
        userPic.clipsToBounds = true
        userPic.layer.masksToBounds = true
        
        carPic.layer.borderWidth = 0.0
        carPic.layer.cornerRadius = 27.0
        carPic.clipsToBounds = true
        carPic.layer.masksToBounds = true
        
        if dataManager.user.user_image != nil
        {
            userPic.image = dataManager.user.user_image
        }
        else
        {
            if(dataManager.user.user_pic != "")
            {
                dataManager.load_image(urlString: dataManager.user.user_pic,  handler: { (image) in
                    if(image != nil)
                    {
                        self.userPic.image = image
                    }
                })
            }
        }
       
        if dataManager.user.car_image != nil
        {
            carPic.image = dataManager.user.car_image
        }
        else
        {
            if(dataManager.user.car_pic != "")
            {
                dataManager.load_image(urlString: dataManager.user.car_pic,  handler: { (image) in
                    if(image != nil)
                    {
                        self.carPic.image = image
                    }
                })
            }
        }
        
    
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.labelVersion.text = "v. \(version)"
        }
    }
    
    //change the view according to order taken or no-order state 
    func setOrderIfTaken()
    {
        if(dataManager.takenOrder.id != 0) //some order was taken
        {
            viewMap.isMyLocationEnabled = true
            subviewGradient.frame = viewMap.bounds
            subviewGradient.setupView()
            subviewGradient.isHidden = false
            ordersTable.isHidden = true
            subViewOrder.isHidden = false
            orderState.text = "Heading to location"
            orderAddress.text = dataManager.takenOrder.address
            locationManager.startUpdatingLocation()
         
            subviewBottom.isUserInteractionEnabled = true
            let mapInsets = UIEdgeInsetsMake(0.0, 0.0, 80.0, 0.0)
            viewMap.padding = mapInsets
            nextButton.isHidden = false
            
            print("Order that been taken before: \(dataManager.takenOrder)")
            
            //work has begun
            if(dataManager.takenOrder.orderStatus == .IN_PROGRESS)
            {
                orderState.text = "Job in progress"
                nextButton.setTitle("WORK IS DONE", for: .highlighted)
                nextButton.setTitle("WORK IS DONE", for: .normal)
            }
            else if(dataManager.takenOrder.orderStatus == .ACCEPTED)
            {
                let alert = UIAlertController(title: "Take a Snow Depth photo", message: "Take a photo with ruler before starting your work" , preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            else if(dataManager.takenOrder.orderStatus == .FINISHED)
            {
                 orderState.text = "Job is done"
                nextButton.setTitle("CHARGE", for: .highlighted)
                nextButton.setTitle("CHARGE", for: .normal)
            }
            
            self.setuplocationMarker(coordinate: dataManager.takenOrder.coordinates, title:"", userData: [:])
            
        }
    }
    
    
    //session check
    func stateCheck()
    {
        //check if previously saved session is valid
        print("state check from driver!")
        self.dataManager.gotLoggedOut = false
                //start updating socket timer
        
                    self.checkOrders()
                    self.dataManager.gotLoggedOut = false
                    if let _ = self.dataManager.wsclient
                    {
                        if(!(self.dataManager.wsclient?.socketConnected)! && self.dataManager.user.SID != "")
                        {
                            self.dataManager.openSocketConnection()
                        }
                    }
                    else if(self.dataManager.user.SID != "")
                    {
                        self.dataManager.openSocketConnection()
                    }

                    self.dataManager.startSocketTimer()
        
                    self.dataManager.getUnfinishedOrder(id: 0, completionCallback: { (success, message) in
                       if(success)
                       {
                        if(self.dataManager.takenOrder.id != 0 && self.dataManager.takenOrder.orderStatus != .NEW )
                        {
                            print("HAVE ORDER TO PROCESS")
                              DispatchQueue.main.async(execute: {
                                self.setOrderIfTaken()
                              })
                        }
                        else
                        {
                            print("HAVE NO ORDER TO PROCESS")
                            DispatchQueue.main.async(execute: {
                            self.startTimer()
                            })
                        }
                       }
                        else //could not get taken orders
                       {
                        print("COULD NOT GET PREV. ORDER: \(message)")
                          DispatchQueue.main.async(execute: {
                             self.startTimer()
                          })
                       }
                    })
                //}
             self.versionCheck()
        
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

    
    //table swipes
    func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            switch swipeGesture.direction {
            case UISwipeGestureRecognizerDirection.right:
                print("Swiped right")
            case UISwipeGestureRecognizerDirection.down:
               
                if(self.isMapMode && !self.isSwipedDown)
                {
                    print("Swiped down")
                    self.isSwipedDown = true
                    UIView.animate(withDuration: 0.5, animations: {
                        let numRowsCustomized = (self.heightOff > 0) ? self.heightOff - 1 : 0
                        self.topConstraint.constant = CGFloat(32 + numRowsCustomized*44 + 9)//numRowsCustomized*44 + 11)
                        self.view.layoutIfNeeded()
                        self.view.layoutSubviews()
                    })
                }
            case UISwipeGestureRecognizerDirection.left:
                print("Swiped left")
            case UISwipeGestureRecognizerDirection.up:
                if(self.isMapMode && self.isSwipedDown)
                {
                    print("Swiped up")
                    self.isSwipedDown = false
                    UIView.animate(withDuration: 0.5, animations: {
                        self.topConstraint.constant = CGFloat(32 - self.heightOff*44)
                        self.view.layoutIfNeeded()
                        self.view.layoutSubviews()

                    })
                }
            default:
                break
            }
        }
    }
    
    
    //location manager delegate methods
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse ||  status == CLAuthorizationStatus.authorizedAlways {
            viewMap.isMyLocationEnabled = true
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        
        previousLocation = currentLocation
        currentLocation = locationArray.lastObject as! CLLocation
        
        print("Location updated. Did find location: \(didFindMyLocation)")
        if(!didFindMyLocation ) //set location for first time
        {
            let zoom = viewMap.camera.zoom
            viewMap.camera = GMSCameraPosition.camera(withTarget: locationObj.coordinate, zoom: zoom)
            viewMap.settings.myLocationButton = true
            viewMap.settings.indoorPicker = true
            didFindMyLocation = true
            previousLocation = currentLocation
        }
       
        if(dataManager.takenOrder.id != 0 && dataManager.takenOrder.orderStatus.rawValue > 0 ) //some order was taken
        {
            if let _ = self.pathRectangle.path
                {
                    if(!GMSGeometryIsLocationOnPathTolerance(locationObj.coordinate, self.pathRectangle.path!, true, 25.0))
                    {
                        self.getDirections(location: locationObj.coordinate, destination: dataManager.takenOrder.coordinates, withCompletionHandler: { (result, success) in
                            print("RETURNED FROM DRIECTIONS: \(success)")
                        })
                    }
                    else
                    {
                      print("LOCATION IS ALREADY ON CURRENT PATH")
                    }
                }
            else
            {
                self.getDirections(location: locationObj.coordinate, destination: dataManager.takenOrder.coordinates, withCompletionHandler: { (result, success) in
                    print("DRAW NEW DIRECTION")
                })
            }
        }
        
    }
    
       
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            viewMap.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 14.0)
            viewMap.settings.myLocationButton = true
            
            //didFindMyLocation = true
        }
    }
    
    
    func startTimer(){
       locationManager.startUpdatingLocation() //locationManager to start updating location again
        
       positionTimer?.invalidate()
       positionTimer = nil
       self.setLocation()
       self.positionTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.setLocation), userInfo: nil, repeats: true)
    }
    
    func putOrderMarkers()
    {
       
        //let dataManager:DataManager = DataManager.sharedInstance
        //print(dataManager.nearbyOrders)
        DispatchQueue.main.async(execute: {
            self.ordersTable.reloadData()
            
            //1.copy current markers to previous
            self.copyOldDrivers()
            
            //2.get new orders locations 
            if(!self.dataManager.nearbyOrders.isEmpty){
            
                            for (_, order) in self.dataManager.nearbyOrders.enumerated() {
                                let lat = order["gps_lat"]
                                let lng = order["gps_lng"]
                                let title = order["address"]
                                let coordinate = CLLocationCoordinate2D(latitude: lat as! CLLocationDegrees, longitude: lng as! CLLocationDegrees)
                                if let order_id = order["id"] as? Int
                                {
                                    self.currentOrders[order_id] = coordinate
                                    if(self.previousOrders[order_id] == nil)
                                    {
                                        self.setuplocationMarker(coordinate: coordinate, title: title as! String, userData: order)
                                        print("put new order marker")
                                    }
                                }
                            }
                        }
                        else{
                            print("Orders list is empty!!!!")
                 }

            //3. update markers
            for (index, marker) in self.currentOrderMarkers.enumerated().reversed()
            {
                if let order = marker.userData as? Dictionary<String, AnyObject>
                {
                    if let order_id = order["id"] as? Int
                    {
                        if let current_position = self.currentOrders[ order_id]  //this order marker is still in curent orders
                        {
                            if let prev_position = self.previousOrders[ order_id]  //this driver marker is not new
                            {
                                
                                let locationCurrent = CLLocation(latitude: current_position.latitude, longitude: current_position.longitude)
                                let locationPrev = CLLocation(latitude: prev_position.latitude, longitude: prev_position.longitude)
                                
                                if(locationCurrent.distance(from: locationPrev) >= 15.0)
                                {
                                    marker.position = self.currentOrders[ order_id]!
                                }
                        
                            }
                            
                        }
                        else //remove this marker from orders
                        {
                            marker.map = nil
                            self.currentOrderMarkers.remove(at: index)
                        }
                        
                    }
                    
                }
                
            }
            
            
            //marker for taken order
            if(self.dataManager.takenOrder.id != 0) //some order was taken
            {
                self.setuplocationMarker(coordinate: self.dataManager.takenOrder.coordinates, title:"", userData: [:])
            }

            
        })
        
    }
    
    func mapView(_: GMSMapView, didTap: GMSMarker) -> Bool {
        print("marker tapped")
        activeMarker = didTap;
    
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        
        print("map tap")
        if(menuShown)
        {
            menuShown = false
            UIView.animate(withDuration: 1.0, animations: {
                self.menuConstraint.constant = -260 // heightCon is the IBOutlet to the constraint
            })
            
        }
    }

    func setuplocationMarker(coordinate: CLLocationCoordinate2D, title:String, userData: NSDictionary) {
        let locationMarker = GMSMarker(position: coordinate)
        locationMarker.map = viewMap
        locationMarker.userData = userData
        //locationMarker.title = title
        locationMarker.appearAnimation = GMSMarkerAnimation.pop
        locationMarker.icon = UIImage(named: "order_marker_orange")
        locationMarker.opacity = 0.75
        self.currentOrderMarkers.append(locationMarker)
    }
    
    //timer function on checking orders
    func checkOrders(){
        
        print("CHECK ORDERS")
        //self.dataManager.getOnlineOrders(location: currentLocation, completionCallback: self.putOrderMarkers)
        self.putOrderMarkers()
    }
    
    func setLocation(){
       print("Socket connected: \(dataManager.wsclient?.socketConnected ?? false)")
       print("SETTING MY LOCATION: \(currentLocation.coordinate)")
      
       if(dataManager.wsclient?.socketConnected)!
       {
        self.dataManager.wsclient?.sendLocation(location: currentLocation, previous: previousLocation)
        self.menuButton.setImage(UIImage(named: "user_icon_green"), for: .normal)
        self.menuButton.setImage(UIImage(named: "user_icon_green"), for: .highlighted)
       }
       else
       {
        self.menuButton.setImage(UIImage(named: "user_icon"), for: .normal)
        self.menuButton.setImage(UIImage(named: "user_icon"), for: .highlighted)
       }
    }
    
    //table delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        //let dataManager:DataManager = DataManager.sharedInstance
        print(" \(dataManager.nearbyOrders.count) " )
        var numRowsCustomized = dataManager.nearbyOrders.count
        
        if(isMapMode)
        {
           if( numRowsCustomized > 3)
           {
             numRowsCustomized = 3
           }
            
           if(!self.isSwipedDown)
           {
            heightOff = numRowsCustomized-2 >= 0 ? numRowsCustomized-2 : 0
            heightConstraint.constant = CGFloat(numRowsCustomized*44 + 11)
            topConstraint.constant = CGFloat(32 - heightOff*44)
           }
        }
        
        return numRowsCustomized
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    
        //print("did get height...\n")
        return 44
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        //print("did get number of sections...\n")
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("getting cell at \(indexPath.row)")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath) as! OrderCell
       
        var index = indexPath.row
        if(isMapMode && dataManager.nearbyOrders.count > 3 && index < 3)
        {
          index = dataManager.nearbyOrders.count - 3 + indexPath.row
        }
        
        if(index <= (dataManager.nearbyOrders.count - 1) )
        {
            let cellElement = dataManager.nearbyOrders[index]
            cell.ordersArrayIndex = index
            cell.cellOrder = cellElement as? Dictionary<String, Any?>
            cell.nameLabel.text = cellElement["name"] as? String
            cell.addressLabel.text = cellElement["address"] as? String
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell:OrderCell = tableView.cellForRow(at: indexPath) as! OrderCell
        
        selectedOrder = cell.ordersArrayIndex
        currentOrder = cell.cellOrder
        
        self.performSegue(withIdentifier: "goToOrderDetails", sender: self)
        
    }
    
    
    private func setupTableView()
    {
        ordersTable.layer.borderWidth = 0.0
        ordersTable.layer.cornerRadius = 7.0
        ordersTable.clipsToBounds = true
        ordersTable.layer.masksToBounds = false
        ordersTable.layer.shadowColor = UIColor.black.cgColor;
        ordersTable.layer.shadowOffset = CGSize(width:3.0, height:3.0);
        ordersTable.layer.shadowOpacity = 0.5;
        ordersTable.layer.shadowRadius = 4.0;
        
        //add view for clipping mask
        let borderView = UIView()
        borderView.frame = ordersTable.bounds
        borderView.clipsToBounds = true
        borderView.layer.cornerRadius = 7
        borderView.layer.borderColor = UIColor.black.cgColor
        borderView.layer.borderWidth = 0.0
        borderView.isUserInteractionEnabled = false
        borderView.layer.masksToBounds = true
        
        ordersTable.addSubview(borderView)
    }
    
    private func goToOrdersMode(){
        self.isMapMode = false
        ordersTable.alwaysBounceVertical = false
        ordersTable.isScrollEnabled = true
        
        UIView.animate(withDuration: 0.5, animations: {
            self.heightConstraint.constant = 600 // heightCon is the IBOutlet to the constraint
            self.leftBorderConstraint.constant = CGFloat(16.0)
            self.rightBorderConstraint.constant = CGFloat(-16.0)
            self.topConstraint.constant = CGFloat(40.0)
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()
        })
        DispatchQueue.main.async(execute: {
            self.ordersTable.reloadData()
            self.modeButton.setImage(UIImage(named: "map_button"), for: .normal)
            self.modeButton.setImage(UIImage(named: "map_button"), for: .highlighted)
        });
    }
    
    private func goToMapMode(){
        self.isMapMode = true
        ordersTable.alwaysBounceVertical = false
        ordersTable.isScrollEnabled = false

        UIView.animate(withDuration: 0.5, animations: {
            self.leftBorderConstraint.constant = CGFloat(0.0)
            self.rightBorderConstraint.constant = CGFloat(0.0)
            self.heightConstraint.constant = CGFloat(144.0)
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()

        })
        DispatchQueue.main.async(execute: {
            self.ordersTable.reloadData()
            self.modeButton.setImage(UIImage(named: "listing"), for: .normal)
            self.modeButton.setImage(UIImage(named: "listing"), for: .highlighted)
        });
    }
    
    @IBAction func switchMode()
    {
      print("button tapped")
      if(!isMapMode)
      {
        print("go to map mode")
        self.goToMapMode()
      }
        else
      {
        print("go to listing mode")
        self.goToOrdersMode()
      }
    
    }
    
    //go take pictures
    @IBAction func goStartWorking()
    {
        
      if(dataManager.takenOrder.orderStatus == .ACCEPTED)
      {
        self.performSegue(withIdentifier: "goStartWorking", sender: self)
      }
      else if(dataManager.takenOrder.orderStatus == .IN_PROGRESS)
      {
        let alert = UIAlertController(title: "Take a Photo of your Work", message: "This provides the highest quality proof of ready work" , preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
            DispatchQueue.main.async(execute: {
                 self.performSegue(withIdentifier: "goStartWorking", sender: self)
            })
        }))
        
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
        })
      }
      else if(dataManager.takenOrder.orderStatus == .FINISHED)
      {
         self.performSegue(withIdentifier: "goCloseOrder", sender: self)
      }
        
    
    }
    
    //go take pictures
    @IBAction func goSeeOrderDetails()
    {
        self.performSegue(withIdentifier: "goToOrderDetails", sender: self)
    }

    
    //
    @IBAction func logOut()
    {
      positionTimer?.invalidate()
      positionTimer = nil
        
      dataManager.LogOut()
      print("LOGGING OUT. CLEARED USER: \(dataManager.user)")
      self.stopSocketTimer()
       
      self.performSegue(withIdentifier: "goToLoginFromDriver", sender: self)
      
    }
    
    
    func goToLogin(){
        //stop all updating timers before performing any segue
        
       self.performSegue(withIdentifier: "goToLoginFromDriver", sender: self)
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
      override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       
        positionTimer?.invalidate()
        positionTimer = nil
        
        if segue.identifier == "goToOrderDetails" {
            if let destination = segue.destination as? OrderController {
                destination.currentOrder_index = selectedOrder
                destination.currentOrder = dataManager.convertToUserOrder(dict: currentOrder!) //currentOrder
                if(dataManager.takenOrder.id != 0) //some order was taken
                {
                  destination.currentOrder = dataManager.takenOrder
                }

            }
        }
    
      }
    
    
    //get directions to our location
    func getDirections(location: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, withCompletionHandler completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        let baseURLGeocode = "https://maps.googleapis.com/maps/api/directions/json?"
        if let lookupLocation = location as CLLocationCoordinate2D? {
            var geocodeURLString = "origin=" + String(lookupLocation.latitude) + "," + String(lookupLocation.longitude) + "&destination=" + String(destination.latitude) + "," +
                String(destination.longitude) + "&key=" + gmsApiKey
            geocodeURLString = baseURLGeocode + geocodeURLString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let geocodeURL = NSURL(string: geocodeURLString)
            
            DispatchQueue.main.async(execute: { () -> Void in
                
                let geocodingResultsData = NSData(contentsOf: geocodeURL! as URL)
                if let _ = geocodingResultsData as Data? {
                    do {
                        let dictionary: Dictionary<String, Any?>! = try JSONSerialization.jsonObject(with: geocodingResultsData! as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, Any?>
                        // Get the response status.
                        let status: String! = dictionary["status"] as! String
                        
                        if status == "OK" {
                            let results = dictionary["routes"] as? [Dictionary<String, AnyObject>]
                            if let routeResult = results?[0] as NSDictionary?
                            {
                                if let points_polyline: NSDictionary = routeResult["overview_polyline"] as! NSDictionary?
                                {
                                    if let points:String = points_polyline["points"] as? String {
                                        self.pathRectangle.map = nil
                                        let path = GMSPath.init(fromEncodedPath: points)
                                
                                        self.pathRectangle = GMSPolyline.init(path: path)
                                        self.pathRectangle.strokeColor = UIColor.init(red: 31.0/255.0, green: 117.0/255.0, blue: 254.0/255.0, alpha: 1.0)
                                        self.pathRectangle.strokeWidth = 2.0
                                        self.pathRectangle.map = self.viewMap
                                        
                                        completionHandler("Success", true)
                                    }
                                }
                            }
                            
                        }
                        else {
                            completionHandler(status, false)
                        }
                        
                    }
                    catch let error{
                        print(error)
                        completionHandler("No valid data received. Could not geocode address", false)
                    }
                }
                } as @convention(block) () -> Void)
            
        }
        else {
            completionHandler("No valid data received. Could not geocode address", false)
        }
        
    }


    //menu actions
    @IBAction func switchMewnu(){
        if(!menuShown)
        {
            menuShown = true
            UIView.animate(withDuration: 0.5, animations: {
                self.menuConstraint.constant = -20 // heightCon is the IBOutlet to the constraint
                self.view.layoutIfNeeded()
                self.view.layoutSubviews()
            })
        }
        else
        {
            menuShown = false
            UIView.animate(withDuration: 0.5, animations: {
                self.menuConstraint.constant = -260 // heightCon is the IBOutlet to the constraint
                self.view.layoutIfNeeded()
                self.view.layoutSubviews()
            })
        }
        
    }
    
    @IBAction func panMenuSwitch(){
        print("panmenu")
        let velocity:CGPoint = panGestureRecognizer.velocity(in: self.viewMap)
        if(velocity.x > 0 && !menuShown)
        {
            menuShown = true
            UIView.animate(withDuration: 0.5, animations: {
                self.menuConstraint.constant = -20 // heightCon is the IBOutlet to the constraint
                self.view.layoutIfNeeded()
                self.view.layoutSubviews()
            })
        }
        else if(velocity.x < 0 && menuShown)
        {
            menuShown = false
            UIView.animate(withDuration: 0.5, animations: {
                self.menuConstraint.constant = -260 // heightCon is the IBOutlet to the constraint
                self.view.layoutIfNeeded()
                self.view.layoutSubviews()
            })
        }
        
    }
    
    @IBAction func closeMenu()
    {
        if(menuShown)
        {
            menuShown = false
            UIView.animate(withDuration: 0.5, animations: {
                self.menuConstraint.constant = -256 // heightCon is the IBOutlet to the constraint
                self.view.layoutIfNeeded()
                self.view.layoutSubviews()
            })
            
        }
        
    }
    
    //1.go to support
   // @available(iOS 10.0, *)
    @IBAction func goToSurropt(){
        if let url = URL(string: "https://snohub.com") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    //2.go offline/online
    @IBAction func goOffline(){
      if(onlineSwitch.isOn == false)
      {
        self.dataManager.goOffline { (success, message) in
            DispatchQueue.main.async(execute: {
             self.positionTimer?.invalidate()
             self.positionTimer = nil
             self.locationManager.stopUpdatingLocation()
             self.dataManager.closeSocketConnection()
             self.stopSocketTimer()
             self.menuButton.setImage(UIImage(named: "user_icon"), for: .normal)
             self.menuButton.setImage(UIImage(named: "user_icon"), for: .highlighted)
            })
        }
      }
      else{
        if(dataManager.user.SID != ""){
        self.locationManager.startUpdatingLocation()
        self.dataManager.openSocketConnection()
        self.dataManager.startSocketTimer()
        }
        
        startTimer()
        self.menuButton.setImage(UIImage(named: "user_icon_green"), for: .normal)
        self.menuButton.setImage(UIImage(named: "user_icon_green"), for: .highlighted)
        }
    }
    
    //3.go to earnings
    @IBAction func goSeeMyEarnings()
    {
      self.performSegue(withIdentifier: "goSeeMyEarnings", sender: self)
    }
    
    //4. go to settings
    @IBAction func openSettings()
    {
        self.performSegue(withIdentifier: "ShowSettingsDriver", sender: self)
    }

    //5.go see prices
    @IBAction func goSeePrices()
    {
        self.performSegue(withIdentifier: "showPricesDriver", sender: self)
    }

    
    
    
    //SOCKET HANDLERS
    //drivers list been updated from socket
    func onOrdersUpdated(withNotification notification : NSNotification)
    {
        print("ORDERS LIST BEEN UPDATED")
        self.checkOrders()
    }
    
    //socket message on being logged out
    func onGotLoggedOut(withNotification notification : NSNotification)
    {
        if(dataManager.gotLoggedOut)
        {
            self.stopSocketTimer()
            
            self.menuButton.setImage(UIImage(named: "user_icon"), for: .normal)
            self.menuButton.setImage(UIImage(named: "user_icon"), for: .highlighted)
            
            let alert = UIAlertController(title: "Login error!", message: "You were logged out from server. Someone may have logged you in from other device. Please try to login again." , preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
                UIAlertAction in
                self.goToLogin()
            }) )
            
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
                self.stopSocketTimer()
            })
            
        }
    }

    func stopSocketTimer()
    {
       self.dataManager.socketCheckTimer?.invalidate()
       self.dataManager.socketCheckTimer = nil
    }
    
    
    //camera functions
    
    @IBAction func useCamera(sender: UITapGestureRecognizer) {
        
        targetImageView = sender.view as? UIImageView
        
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.camera) {
            
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = true
            imagePicker.showsCameraControls = true
            imagePicker.isModalInPopover = true
            imagePicker.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
            
            imagePicker.preferredContentSize = CGSize(width: 450, height: 450);
            
            imagePicker.delegate = self
            imagePicker.sourceType =
                UIImagePickerControllerSourceType.camera
            imagePicker.mediaTypes = [(kUTTypeImage as NSString) as String]
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true,
                         completion: nil)
            
        }
    }
    
    @IBAction func useCameraRoll(sender: UILongPressGestureRecognizer) {
        
        
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.savedPhotosAlbum) {
            
            let imagePicker = UIImagePickerController()
            imagePicker.allowsEditing = true
            //imagePicker.showsCameraControls = true
            imagePicker.preferredContentSize = CGSize(width: 450, height: 450)
            
            imagePicker.delegate = self
            imagePicker.sourceType =
                UIImagePickerControllerSourceType.photoLibrary
            imagePicker.mediaTypes = [(kUTTypeImage as NSString) as String]
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true,
                         completion: nil)
            
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        self.dismiss(animated: true, completion: nil)
        
        if mediaType == (kUTTypeImage as String) {
            let image = info[UIImagePickerControllerOriginalImage]
                as! UIImage
            let resizedImage = resizeImage(image: image, newWidth: 400)
            
            self.targetImageView?.image = resizedImage
            dataManager.user.user_image = resizedImage
            
            var type = 0
            if targetImageView != self.userPic{
                type = 1
            }
            
            dataManager.uploadPicture(imageToLoad: resizedImage, type: type, completionCallback: { (success, message) in
                print(message)
            })
            
        }
        
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafeRawPointer) {
        
        if error != nil {
            let alert = UIAlertController(title: "Save Failed",
                                          message: "Failed to save image",
                                          preferredStyle: UIAlertControllerStyle.alert)
            
            let cancelAction = UIAlertAction(title: "OK",
                                             style: .cancel, handler: nil)
            
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height:newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let size = CGSize(width: newWidth, height: newWidth)
        let image = newImage?.crop(to: size)
        return image!
    }
 //------------- end camera functions

    //makrsers info array copy
    func copyOldDrivers()
    {
        previousOrders = [:]
        for(_, element) in currentOrders.enumerated()
        {
            previousOrders[element.key] = element.value
        }
        currentOrders = [:]
    }

    
    
    
    //shareButton (non-fb)
    @IBAction func shareAction()
    {
        
        dataManager.getPromo { (success, error, promoData) in
            
            if(!success)
            {
                DispatchQueue.main.async( execute: {
                    let alert = UIAlertController(title: "Could not get promo info",
                                                  message: "Failed to get promo info from backend",
                                                  preferredStyle: UIAlertControllerStyle.alert)
                    
                    let cancelAction = UIAlertAction(title: "OK",
                                                     style: .cancel, handler: nil)
                    
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                })
                return
            }
            
            guard let shareText = promoData?["text"] as? String else {
                print("No promo text!")
                return
            }
            
            guard let urlString = promoData?["link"] as? String else {
                print("No promo link!")
                return
            }
            
            guard let url = URL(string: urlString) else
            {
                print("No valid promo url")
                return
            }
            
            if let image = UIImage(named: "background_car")
            {
                DispatchQueue.main.async(execute: {
                    let vc = UIActivityViewController(activityItems: [shareText, image, url], applicationActivities: [])
                    self.present(vc, animated: true, completion: nil)
                    
                    vc.popoverPresentationController?.delegate = self
                    vc.preferredContentSize = CGSize(width: self.view.bounds.width, height:self.view.bounds.height)
                    
                    vc.completionWithItemsHandler = {(activityType, completed, items, error) in
                        print("Activity controller status: \(completed)")
                    }
                })
                
            }
            
            
        }

    }

    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        
        popoverPresentationController.sourceView = self.view
        popoverPresentationController.sourceRect = self.view.bounds
        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection(rawValue:0)
        
    }
    
}
