//
//  ViewController.swift
//  SnowHub
//
//  Created by Liubov Perova on 10/21/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit
import GooglePlaces
import MobileCoreServices
import AVFoundation

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, UIImagePickerControllerDelegate, UISearchBarDelegate, UISearchControllerDelegate, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var viewMap: GMSMapView!
    @IBOutlet weak var subviewBottom: UIView!
    @IBOutlet weak var subviewTop: TopView!
    @IBOutlet weak var subviewActions: UIView!
    @IBOutlet weak var orderButton: BorderedButton!
    @IBOutlet weak var subviewInfo: InfoView!
    @IBOutlet var bottomConstraint: NSLayoutConstraint! //button bottom constraint
    
    //menu view
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var menuConstraint: NSLayoutConstraint!
    @IBOutlet weak var panGestureRecognizer: UIPanGestureRecognizer!
    @IBOutlet weak var labelVersion:UILabel!
    @IBOutlet weak var userPic: UIImageView!
    @IBOutlet weak var userName: UILabel!

    var menuShown: Bool = false;
    var markerScaleFactor:Float = 20.0
    
    //info view
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var closeInfoButton: UIButton!
    @IBOutlet weak var subviewConstraint: NSLayoutConstraint!

    //top view
    @IBOutlet weak var searchAddress: UISearchBar!
    
    //facebook SDK login button
    @IBOutlet var shareView: UIView!
    
    //global variables
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    var currentLocation = CLLocation() //location of order
    var currentGPSLocation = CLLocation() //location of customer
    var locatingAddressFound = false
    var placesClient: GMSPlacesClient? = GMSPlacesClient()
    var dataManager:DataManager = DataManager.sharedInstance
    
    //map
    var activeMarker: GMSMarker? = GMSMarker()
    var currentMarkers: Array<GMSMarker> = []
    var snowPlowLoactionMarker: GMSMarker? = GMSMarker()
    var pathRectangle = GMSPolyline()
    var gmsApiKey: String! = "AIzaSyAkuYvAco7GALUTx1T-EG9CAgvgbug5U6U"
    var currentBearing = 0.0; //camera position bearing
    
    var previousDrivers: Dictionary<Int,CLLocationCoordinate2D> = [:]
    var currentDrivers:  Dictionary<Int,CLLocationCoordinate2D> = [:]
    
    
    var lookupAddressResults: Dictionary<String, Any>!
    var fetchedFormattedAddress: String!
    var fetchedAddressLongitude: Double!
    var fetchedAddressLatitude: Double!
    
    //places autocomlete
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    //alert controller
    var alert: UIAlertController! = UIAlertController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
            //get your current location
            locationManager.delegate = self;
            locationManager.requestAlwaysAuthorization();
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        
            //additional setup of google camera
            self.view.layoutIfNeeded()
            viewMap.delegate = self
            viewMap.isMyLocationEnabled = true
            viewMap.settings.myLocationButton = true
            let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 48.857165, longitude: 2.354613, zoom: 14.0)
            viewMap.camera = camera
            findButtonHome()

            //address search
            resultsViewController = GMSAutocompleteResultsViewController()
            resultsViewController?.delegate = self
            resultsViewController?.tintColor = UIColor(red:(7.0/255.0), green:(66.0/255.0), blue:(129.0/255.0), alpha:1.00)
        
            searchController = UISearchController(searchResultsController: resultsViewController)
            searchController?.searchResultsUpdater = resultsViewController
            searchController?.view.frame = subviewTop.searchPlaceView.frame
            subviewTop.searchPlaceView.addSubview((searchController?.searchBar)!)
            searchController?.searchBar.sizeToFit()
            searchController?.searchBar.showsCancelButton = false
            searchController?.searchBar.searchBarStyle = UISearchBarStyle.minimal
            searchController?.searchBar.barTintColor = UIColor.clear
            searchController?.searchBar.delegate = self
            searchController?.searchBar.showsBookmarkButton = true
            searchController?.searchBar.setImage(UIImage(named: "home"), for: UISearchBarIcon.bookmark , state: .normal)
        
            searchController?.searchBar.barTintColor = UIColor.white//UIColor(red:(7.0/255.0), green:(66.0/255.0), blue:(129.0/255.0), alpha:1.00)
            searchController?.searchBar.tintColor = UIColor.white//UIColor(red:(7.0/255.0), green:(66.0/255.0), blue:(129.0/255.0), alpha:1.00)
            searchController?.searchBar.setSearchTextcolor(color: UIColor(red:(7.0/255.0), green:(66.0/255.0), blue:(129.0/255.0), alpha:1.00))
             if let searchField = searchController?.searchBar.value(forKey: "searchField") as? UITextField
             {
                print("searchfield found")
                searchField.backgroundColor = UIColor.white
                searchField.textColor = UIColor(red:(7.0/255.0), green:(66.0/255.0), blue:(129.0/255.0), alpha:1.00)
             }
            searchController?.searchBar.searchBarStyle = UISearchBarStyle.prominent
            searchController?.searchBar.barTintColor = UIColor.white
            searchController?.searchBar.cleanWhite()

        
        
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
        
            //map padding
            let mapInsets = UIEdgeInsetsMake(0.0, 0.0, 80.0, 0.0)
            viewMap.padding = mapInsets
        
            viewMap.settings.consumesGesturesInView = false
            viewMap.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.new, context: nil)
            viewMap.addSubview(subviewBottom)
            viewMap.addSubview(subviewTop)
            viewMap.addSubview(subviewActions)
            self.subviewActions.isHidden = true
            //search bar settings
            viewMap.addSubview(searchAddress)
            searchAddress.delegate = self
    
            viewMap.addSubview(subviewInfo)
            viewMap.addSubview(menuView)

            self.view = viewMap
            //order button settings
            orderButton.setTitleColor(UIColor.white, for: .highlighted)
            orderButton.setTitleColor(UIColor.white, for: .normal)
        
        
           checkState()
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            print("Bundel: \(Bundle.main.bundleIdentifier ?? defaultValue)")
            self.labelVersion.text = "v. \(version)"
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        setupMenu()
        
        //if order is zero and the location is already there, we put the current location and address into
        if(dataManager.order.id == 0 && didFindMyLocation && !(currentLocation.coordinate.latitude == 0 && currentLocation.coordinate.longitude == 0))
        {
            dataManager.order.coordinates = currentLocation.coordinate
            print("address change #1")
            dataManager.order.address = self.searchAddress.text!
        }
        
      }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //add observer for orderStatusChanged
        NotificationCenter.default.removeObserver(self, name: .onOrderStatusChnaged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onDriversUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onSocketLogOut, object: nil)
        
        self.checkDrivers()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrderStatusCnahged(withNotification:)), name: .onOrderStatusChnaged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onDriversUpdated(withNotification:)), name: .onDriversUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onGotLoggedOut(withNotification:)), name: .onSocketLogOut, object: nil)
        
        
        self.didFindMyLocation = false
        if(dataManager.order.id == 0)
        {
            if(!(currentLocation.coordinate.latitude == 0 && currentLocation.coordinate.longitude == 0))
            {
                print("SET PREV COORDINATES")
                dataManager.order.coordinates = currentLocation.coordinate
                dataManager.order.address = self.searchAddress.text!
            }
            else //restart location manager
            {
              self.didFindMyLocation = false
              self.locationManager.stopUpdatingLocation()
              self.locationManager.startUpdatingLocation()
            }
            
        }
        else
        {
           checkOrderStatus()
        }

        searchController?.searchBar.sizeToFit()//sizeThatFits(CGSize(width: subviewTop.searchPlaceView.bounds.width, height: subviewTop.searchPlaceView.bounds.height))
        searchController?.searchBar.showsCancelButton = false
     }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewMap.clear()
        self.didFindMyLocation = false
        
        //add observer for orderStatusChanged
        NotificationCenter.default.removeObserver(self, name: .onOrderStatusChnaged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onDriversUpdated, object: nil)
        NotificationCenter.default.removeObserver(self, name: .onSocketLogOut, object: nil)
    
    }
    
    
    //version check
    func versionCheck(){
        dataManager.checkVersion { (success, message) in
            if(success)
            {
                
            }
            
        }

    }
    
    //setup menu
    func setupMenu() {
        
        userName.text = dataManager.user.name
        
        userPic.layer.borderWidth = 0.0
        userPic.layer.cornerRadius = 27.0
        userPic.clipsToBounds = true
        userPic.layer.masksToBounds = true
        
        if(dataManager.user.user_pic != "")
        {
            dataManager.load_image(urlString: dataManager.user.user_pic,  handler: { (image) in
                if(image != nil)
                {
                    self.userPic.image = image
                }
            })
        }
        
        if dataManager.user.user_image != nil
        {
          userPic.image = dataManager.user.user_image
        }
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.labelVersion.text = "v. \(version)"
        }
    }

    
    
    //show non-empty order
    func showCurrentOrder(){
        
        self.orderButton.setTitle("YOUR ORDER STATE", for: .normal)
        self.orderButton.setTitle("YOUR ORDER STATE", for: .highlighted)
        
        if(dataManager.order.orderStatus == .SCHEDULED)
        {
            self.orderButton.setTitle("YOUR SUBSCRIBE STATE", for: .normal)
            self.orderButton.setTitle("YOUR SUBSCRIBE STATE", for: .highlighted)
        }
        
        self.searchController?.searchBar.text = dataManager.order.address
        self.searchAddress.text = dataManager.order.address
        self.currentLocation = CLLocation(latitude:  dataManager.order.coordinates.latitude, longitude:  dataManager.order.coordinates.longitude)
        self.snowPlowLoactionMarker?.position = dataManager.order.coordinates
        self.snowPlowLoactionMarker?.icon = UIImage(named: "plow_location")
        self.snowPlowLoactionMarker?.map = self.viewMap
        self.snowPlowLoactionMarker?.icon = UIImage(named: "plow_location")
        
        self.viewMap.animate(toLocation: dataManager.order.coordinates)
    }
    
    //check if sessiou valid
    func checkState()
    {
        //check if our session is valid and if it is - go get drivers, and if not then go to login
        print("checkSession from customer!")
        
                       print("session is valid")
        
                    //get all drivers first (in case we'd missed any socket message)
                    checkDrivers()
        
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
                                DispatchQueue.main.async(execute: {
                                    
                                    if(self.dataManager.order.id != 0)
                                    {
                                        self.showCurrentOrder()
                                    }
                                    else
                                    {
                                        print("COULD NOT GET PREV. ORDER: \(message)")
                                    }
                                })
                            }
                        })
        
                 
                    self.versionCheck()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        viewMap.removeFromSuperview()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
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
            currentGPSLocation = locationArray.lastObject as! CLLocation
            //currentLocation = locationArray.lastObject as! CLLocation
        
            print("DID_UPDATE_LOCATION. Location is: \(currentGPSLocation). DidFindMyLocation: \(didFindMyLocation)")
        
            if !didFindMyLocation {
                //viewMap.camera = GMSCameraPosition.camera(withTarget: locationObj.coordinate, zoom: 14.0)
                viewMap.animate(with: GMSCameraUpdate.setTarget(locationObj.coordinate))
                viewMap.settings.myLocationButton = true
                viewMap.settings.indoorPicker = true
                
                didFindMyLocation = true
                
                //put snowPlow marker here
                if(dataManager.order.id == 0)
                {
                    dataManager.order.coordinates = locationObj.coordinate
                    print("orderCoordinates (location manager): \(dataManager.order.coordinates)")
                    
                    
                    snowPlowLoactionMarker?.position = locationObj.coordinate
                    snowPlowLoactionMarker?.icon = UIImage(named: "plow_location")
                    snowPlowLoactionMarker?.map = viewMap
                    snowPlowLoactionMarker?.icon = UIImage(named: "plow_location")
                    
                    self.geocodeLocation(location: locationObj, withCompletionHandler: {(status, success) -> () in
                                        if success{
                                            self.searchAddress.text = self.fetchedFormattedAddress
                                            self.dataManager.order.address = self.fetchedFormattedAddress
                                            print("Updated ORDER BY LOCATION: \(self.dataManager.order.coordinates)")
                                            self.searchController?.searchBar.text = self.fetchedFormattedAddress
                                            self.searchController?.searchBar.sizeToFit()
                                            self.currentLocation = locationArray.lastObject as! CLLocation
                                        }
                                        else{
                                            
                                      }
                       })
                }
             }
             else
             {
            
             }
        
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !didFindMyLocation {
            //let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            //viewMap.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: 14.0)
            // viewMap.animate(with: GMSCameraUpdate.setTarget(myLocation.coordinate))
            //viewMap.settings.myLocationButton = true
            
            //didFindMyLocation = true
        }
    }
    
    func putDriverMarkers()
    {
        
     
     if(!dataManager.gotDriversUpdate)
     {
        return
     }
        dataManager.gotDriversUpdate = false
        
        //print(dataManager.nearbyDrivers)
        
        //1. copy current locations to prev
        copyOldDrivers()
        
        
        //2. get new drivers locations
        if(!dataManager.nearbyDrivers.isEmpty){
            for (_, driver) in dataManager.nearbyDrivers.enumerated() {
                let lat = driver["gps_lat"]
                let lng = driver["gps_lng"]
                let title = "\(driver["driver_id"] ?? defaultValue)"
                let coordinate = CLLocationCoordinate2D(latitude: lat as! CLLocationDegrees, longitude: lng as! CLLocationDegrees)
                if driver["driver_id"] as? Int != 0
                {
                   currentDrivers[driver["driver_id"] as! Int] = CLLocationCoordinate2D(latitude: lat as! CLLocationDegrees, longitude: lng as! CLLocationDegrees)
                    if previousDrivers[ driver["driver_id"] as! Int] == nil //this driver marker is new
                    {
                       self.setuplocationMarker(coordinate: coordinate, title: title, userData: driver)
                       print("Put new marker for driver \( driver["driver_id"] ?? defaultValue)")
                    }
                
                }
              }
        }

        //3. update markers 
        for (index, marker) in currentMarkers.enumerated().reversed()
        {
            if let driver = marker.userData as? Dictionary<String, AnyObject>
            {
              if driver["driver_id"] as? Int != 0
              {
                if let current_position = currentDrivers[ driver["driver_id"] as! Int]  //this driver marker is still in curent drivers
                {
                    if let prev_position = previousDrivers[ driver["driver_id"] as! Int]  //this driver marker is still in curent drivers
                    {
                       

                        let locationCurrent = CLLocation(latitude: current_position.latitude, longitude: current_position.longitude)
                        let locationPrev = CLLocation(latitude: prev_position.latitude, longitude: prev_position.longitude)
                        
                        if(locationCurrent.distance(from: locationPrev) >= 15.0)
                        {
                            marker.rotation = getBearing(point: current_position, origin: prev_position)
                            print("Update position for driver: \(driver["driver_id"] ?? defaultValue as AnyObject)")
                            CATransaction.begin()
                            
                            CATransaction.setAnimationDuration(3.0)
                            marker.position = currentDrivers[ driver["driver_id"] as! Int]!
                            CATransaction.commit()
                        }

                        //if this friver had taken our order
                        if(driver["driver_id"] as? Int == dataManager.order.driver_id && dataManager.order.id != 0 && locationCurrent.distance(from: locationPrev) >= 15.0)
                        {
                            marker.icon = UIImage(named: "plower_marker_orange")
                            marker.map = viewMap
                            
                             if let _ = self.pathRectangle.path
                             {
                                if(!GMSGeometryIsLocationOnPathTolerance(locationCurrent.coordinate, self.pathRectangle.path!, true, 25.0))
                                {
                                    self.getDirections(location: current_position, destination: dataManager.order.coordinates, withCompletionHandler: { (result, success) in
                                        //do anything after we'd successfully drew directions between driver and our order
                                        print("DRIVER IS ON NEW DIRECTION")
                                    })
                                }
                                else
                                {
                                   print("DRIVER IS STILL ON HIS DIRECTION")
                                }
                            }
                            else
                            {
                                self.getDirections(location: current_position, destination: dataManager.order.coordinates, withCompletionHandler: { (result, success) in
                                    print("DRAW NEW DIRECTION")
                                })
                            }
                        }

                    }
                   
                }
                else //remove this marker from drivers
                {
                   marker.map = nil
                   print("Driver \(driver["driver_id"] ?? defaultValue as AnyObject) got offline")
                   currentMarkers.remove(at: index)
                }
                
              }
            
            }
        
        }
        
    }

    func scaleDriverMarkers(bearingDifference: Double){
        
      let scale = getScale()
      let myImage = UIImage(named: "plower_marker")
      let markerData = UIImagePNGRepresentation(myImage!)
        for (_, marker) in currentMarkers.enumerated()
        {
            marker.icon =  UIImage(data: markerData!, scale: scale)
            marker.rotation += bearingDifference
            marker.map = self.viewMap
        }
    }

    func getScale() -> CGFloat {
      return  CGFloat((self.markerScaleFactor)*(1.0/viewMap.camera.zoom*2))
    }
    
    func setuplocationMarker(coordinate: CLLocationCoordinate2D, title:String, userData: NSDictionary) {
        let locationMarker = GMSMarker(position: coordinate)
        locationMarker.map = viewMap
        locationMarker.userData = userData
        locationMarker.appearAnimation = GMSMarkerAnimation.pop
        
        let myImage = UIImage(named: "plower_marker")
        let markerData = UIImagePNGRepresentation(myImage!)
        let scale = getScale()
        
        locationMarker.icon = UIImage(data: markerData!, scale: scale) //CGFloat(viewMap.camera.zoom))//UIImage(named: "plower_marker")
        
        locationMarker.opacity = 0.75
        currentMarkers.append(locationMarker)

        if let user_id = userData["driver_id"] as? Int
        {
            
           if(user_id == dataManager.order.driver_id && dataManager.order.id != 0)
           {
             locationMarker.icon = UIImage(named: "plower_marker_orange")
             locationMarker.map = viewMap
           
            if let _ = self.pathRectangle.path
            {
             if(!GMSGeometryIsLocationOnPathTolerance(coordinate, self.pathRectangle.path!, true, 25.0))
             {
                self.getDirections(location: coordinate, destination: dataManager.order.coordinates, withCompletionHandler: { (result, success) in
                    //do anything after we'd successfully drew directions between driver and our order
                    print("Draw new location")
                })
             }
            }
            else
            {
                self.getDirections(location: coordinate, destination: dataManager.order.coordinates, withCompletionHandler: { (result, success) in
                    //do anything after we'd successfully drew directions between driver and our order
                    print("Draw new location")
                })
            }
          }
        }
        else if let user_id = userData["id"] as? Int
        {
            
            if(user_id == dataManager.order.driver_id && dataManager.order.id != 0)
            {
                locationMarker.icon = UIImage(named: "plower_marker_orange")
                locationMarker.map = viewMap

                if let _ = self.pathRectangle.path
                {
                    if(!GMSGeometryIsLocationOnPathTolerance(coordinate, self.pathRectangle.path!, true, 25.0))
                    {
                        self.getDirections(location: coordinate, destination: dataManager.order.coordinates, withCompletionHandler: { (result, success) in
                            //do anything after we'd successfully drew directions between driver and our order
                            print("Draw new location")
                        })
                    }
                }
                else
                {
                    self.getDirections(location: coordinate, destination: dataManager.order.coordinates, withCompletionHandler: { (result, success) in
                       print("Draw new location")
                    })
                }
                
            }
        }
        
    }
    
    //on marker tap
    func mapView(_: GMSMapView, didTap: GMSMarker) -> Bool {
       print("marker tapped")
        
        if let _ = didTap.userData as? Dictionary<String, Any> {
        
        //subviewInfo.isHidden = false
        //let userData = didTap.userData as! NSDictionary
        didTap.icon = UIImage(named: "plower_marker_orange")
        //userLabel.text = userData["name"] as? String
        //likesLabel.text = String(describing: userData["likes"] as! Int)
        //dislikesLabel.text = String( describing: userData["dislikes"] as! Int )
        //print(userData["dislikes"]!)
        //print(userData["likes"]!)

        activeMarker?.icon = UIImage(named: "plower_marker")
        activeMarker = didTap;
        activeMarker?.map = viewMap
        
        }
        
       return true
    }

    
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        self.currentBearing = viewMap.camera.bearing
    }
    
    //on change camera position
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        
        if(didFindMyLocation && !locatingAddressFound && dataManager.order.id == 0)
        {
//            print("position changed")
//            let coordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: position.target.latitude, longitude: position.target.longitude)
//            snowPlowLoactionMarker?.position = coordinate!
//            snowPlowLoactionMarker?.map = viewMap
//            dataManager.order.coordinates = coordinate!
//            snowPlowLoactionMarker?.icon = UIImage(named: "plow_location")
            
           
        }
        if(locatingAddressFound == true)
        {
          //locatingAddressFound = false
        }
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
//
//        if(didFindMyLocation && !locatingAddressFound && dataManager.order.id == 0)
//        {
//            print("position changed. geocoding location")
//            let coordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: position.target.latitude, longitude: position.target.longitude)
//           
//            dataManager.order.coordinates = coordinate!
//            let locationObj: CLLocation! = CLLocation(latitude: position.target.latitude, longitude: position.target.longitude)
//            
//            self.geocodeLocation(location: locationObj, withCompletionHandler: {(status, success) -> () in
//                if success{
//                    self.searchAddress.text = self.fetchedFormattedAddress
//                    dataManager.order.address = self.fetchedFormattedAddress
//                    self.searchController?.searchBar.text = self.fetchedFormattedAddress
//                }
//                else{
//                    
//                    }
//            })
//            
//            
//        }
//        else if(locatingAddressFound == true)
//        {
//            locatingAddressFound = false
//        }

        //bearing difference 
        let bearingDifference = currentBearing - viewMap.camera.bearing
        currentBearing = viewMap.camera.bearing
        
        //scale markers
        let scale = getScale()
        print("Map idle. Zoom: \(scale)")
        scaleDriverMarkers(bearingDifference: bearingDifference)
        
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
    
    
    func geocodeAddress(address: String!, withCompletionHandler completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
        if let lookupAddress = address {
            var geocodeURLString = "address=" + lookupAddress + "&key=" + gmsApiKey
            geocodeURLString = baseURLGeocode + geocodeURLString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let geocodeURL = NSURL(string: geocodeURLString)
            
            DispatchQueue.main.async(execute: { () -> Void in
            
                let geocodingResultsData = NSData(contentsOf: geocodeURL! as URL)
                if let _ = geocodingResultsData as Data? {
                do {
                    let dictionary: Dictionary<String, AnyObject>! = try JSONSerialization.jsonObject(with: geocodingResultsData! as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, AnyObject>
                    // Get the response status.
                    let status: String! = dictionary["status"] as! String
                    
                    if status == "OK" {
                        let allResults: Array<Dictionary<String, Any>> =  dictionary["results"] as! [Dictionary<String, Any>]
                        self.lookupAddressResults = allResults[0] as Dictionary<String, Any>!
                        
                        // Keep the most important values.
                        self.fetchedFormattedAddress = self.lookupAddressResults["formatted_address"] as! String!
                        let geometry: Dictionary<String, Any>! = self.lookupAddressResults["geometry"] as! Dictionary<String, Any>!
                        self.fetchedAddressLongitude = ((geometry["location"] as! Dictionary<String, Any>!)["lng"] as! NSNumber).doubleValue
                        self.fetchedAddressLatitude = ((geometry["location"] as! Dictionary<String, Any>!)["lat"] as! NSNumber).doubleValue
                        
                        //get the county (if Fairfield - let it be fairfield, if not - let it be Westchester by default)
                        if let addressComponents = self.lookupAddressResults["address_components"] as? [Dictionary<String, Any>]
                        {
                            for (_, component) in addressComponents.enumerated() {
                                if let types = component["types"] as? [String]
                                {
                                    if(types[0] ==  "administrative_area_level_3")
                                    {
                                        if let short_name = component["short_name"] as? String
                                        {
                                            self.dataManager.order.county_area = short_name
                                            print("GOT COUNTY: \(short_name)")
                                        }
                                    }
                                }
                            }
                        }
                        
                        completionHandler(status, true)
                    }
                    else {
                        completionHandler(status, false)
                    }
                    

                }
                catch let error{
                  print(error)
                   completionHandler("No valid data received. Could not locate such address", false)
                }
              }
            } as @convention(block) () -> Void)
            
        }
        else {
            completionHandler("No valid data received. Could not locate such address", false)
        }
        
    }
    
    func geocodeLocation(location: CLLocation, withCompletionHandler completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
        if let lookupLocation = location.coordinate as CLLocationCoordinate2D? {
            var geocodeURLString = "latlng=" + String(lookupLocation.latitude) + "," + String(lookupLocation.longitude) + "&key=" + gmsApiKey
            geocodeURLString = baseURLGeocode + geocodeURLString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            let geocodeURL = NSURL(string: geocodeURLString)
            print("GEOCODE: \(String(describing: geocodeURL))")
            DispatchQueue.main.async(execute: { () -> Void in
                
                let geocodingResultsData = NSData(contentsOf: geocodeURL! as URL)
                   if let _ = geocodingResultsData as Data? {
                    do {
                        let dictionary: Dictionary<String, AnyObject>! = try JSONSerialization.jsonObject(with: geocodingResultsData! as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! Dictionary<String, AnyObject>
                        // Get the response status.
                        let status: String! = dictionary["status"] as! String
                        
                        if status == "OK" {
                            let allResults: Array<Dictionary<String, Any>> =  dictionary["results"] as! [Dictionary<String, Any>]
                            self.lookupAddressResults = allResults[0] as Dictionary<String, Any>!
                            
                            // Keep the most important values.
                            self.fetchedFormattedAddress = self.lookupAddressResults["formatted_address"] as! String!
                            let geometry: Dictionary<String, Any>! = self.lookupAddressResults["geometry"] as! Dictionary<String, Any>!
                            self.fetchedAddressLongitude = ((geometry["location"] as! Dictionary<String, Any>!)["lng"] as! NSNumber).doubleValue
                            self.fetchedAddressLatitude = ((geometry["location"] as! Dictionary<String, Any>!)["lat"] as! NSNumber).doubleValue
                            
                            //get the county (if Fairfield - let it be fairfield, if not - let it be Westchester by default)
                            if let addressComponents = self.lookupAddressResults["address_components"] as? [Dictionary<String, Any>]
                            {
                                for (_, component) in addressComponents.enumerated() {
                                     if let types = component["types"] as? [String]
                                     {
                                       if(types[0] ==  "administrative_area_level_3")
                                       {
                                         if let short_name = component["short_name"] as? String
                                         {
                                            self.dataManager.order.county_area = short_name
                                            print("GOT COUNTY: \(short_name)")
                                         }
                                       }
                                     }
                                }
                            }
                            
                            
                            completionHandler(status, true)
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
                            if let routeResult:NSDictionary = results?[0] as NSDictionary?
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
                                        
                                        print("REDRAW DIRECTION")
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
    

    
    
    //cancel search
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
         searchAddress.resignFirstResponder()
        
    }
    
    //search become active
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        print("Should show our own home ")
        self.subviewInfo.isHidden = true
        self.subviewConstraint.constant = -35
        return true
    }
    
    //search bookmark button clicked (put default address)
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        
        self.subviewInfo.isHidden = true
        self.subviewConstraint.constant = -35

        if dataManager.order.id == 0
        {
            if(!(dataManager.user.homeAddressCoordinates?.latitude == 0 && dataManager.user.homeAddressCoordinates?.longitude == 0) && dataManager.user.homeAddress != "")
            {
                if let defaultCoordinate = dataManager.user.homeAddressCoordinates
                {
                    print("SET DEFAULT COORDINATES")
                    currentLocation = CLLocation(latitude: defaultCoordinate.latitude, longitude: defaultCoordinate.longitude)
                    self.searchController?.searchBar.text = dataManager.user.homeAddress
                    dataManager.order.coordinates = currentLocation.coordinate
                    dataManager.order.address = (self.searchController?.searchBar.text)!
                    
                    self.locatingAddressFound = true
                   
                    //if let _ = self.snowPlowLoactionMarker as GMSMarker? {
                    
                        self.snowPlowLoactionMarker?.position = defaultCoordinate
                        snowPlowLoactionMarker?.map = viewMap
                        snowPlowLoactionMarker?.icon = UIImage(named: "plow_location")
                        self.viewMap.animate(with: GMSCameraUpdate.setTarget(defaultCoordinate))
                    //}
                }
            }
        }

        
    }
    
    //set default address 
    @IBAction func setDefaultAddress()
    {
        let lat = currentLocation.coordinate.latitude
        let lng = currentLocation.coordinate.longitude
        let addr = (self.searchController?.searchBar.text)!
        
        if(addr != "" && !(lat == 0 && lng == 0))
        {
            dataManager.setDefaultAddress(address: addr, lat: lat, lng: lng) { (success, error) in

                DispatchQueue.main.async(execute: {
                    self.subviewInfo.isHidden = true
                    self.subviewConstraint.constant = -35
                })

                if(!success)
                {
                    self.alert.dismiss(animated: true, completion: nil)
                    self.alert = UIAlertController(title: "Error", message: error, preferredStyle: UIAlertControllerStyle.alert)
                    self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    
                    DispatchQueue.main.async(execute: {
                        self.present(self.alert, animated: true, completion: nil)
                    })
                }
                else
                {
                  self.dataManager.user.homeAddress = addr
                  self.dataManager.user.homeAddressCoordinates = self.currentLocation.coordinate
                }
               
            }
        }
    }
    
    
    //start search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchAddress.resignFirstResponder()
        
        self.geocodeAddress(address: searchAddress.text, withCompletionHandler: {(status, success) -> () in
            if success{
                print("position changed due to address geocoding")
                let coordinate: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: self.fetchedAddressLatitude, longitude: self.fetchedAddressLongitude)
               
                self.locatingAddressFound = true
                self.snowPlowLoactionMarker?.position = coordinate!
                self.viewMap.animate(with: GMSCameraUpdate.setTarget(coordinate!))
                
                self.currentLocation = CLLocation(latitude:  self.fetchedAddressLatitude, longitude: self.fetchedAddressLongitude)
                self.dataManager.order.coordinates = coordinate!
                print("Order update by search?")
                print("orderCoordinates (auto fill): \(self.dataManager.order.coordinates)")

                //dataManager.order.address = self.searchAddress.text!
            }
            else{
                self.alert.dismiss(animated: true, completion: nil)
                self.alert = UIAlertController(title: "Error", message: status, preferredStyle: UIAlertControllerStyle.alert)
                self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                DispatchQueue.main.async(execute: {
                    self.present(self.alert, animated: true, completion: nil)
                })
               }
        })
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.bottomConstraint.constant = (keyboardFrame.size.height) + 16
            })
        }
    }
    
    
    func keyboardWillHide(notification: NSNotification) {
        
                       self.bottomConstraint.constant = 16
       
    }
    
    
    //check status of order (on timer)
    func checkOrderStatus()
    {
            if(dataManager.orderStatusChanged)
            {
                if(dataManager.soundsOn)
                {
                  self.playSound(type: "thecalling")
                }
                print("ORDER STATUS CHANGED!")
                print("Order: \(dataManager.order)")
                dataManager.orderStatusChanged = false
                //order status had been changed
                dataManager.setUserPreferences()
                
                if(dataManager.order.orderStatus == .FINISHED)
                {
                    //dataManager.order = Order()
                    //dataManager.setUserPreferences()
                    self.orderButton.setTitle("ORDER SNOWPLOW", for: .normal)
                    self.orderButton.setTitle("ORDER SNOWPLOW", for: .highlighted)
                    
                    
                    //change button header
                    self.alert.dismiss(animated: true, completion: nil)
                    self.alert = UIAlertController(title: "Order has been completed!", message: "Would you like to rate the service provider?", preferredStyle: UIAlertControllerStyle.alert)
                    self.alert.addAction(UIAlertAction(title: "YES", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                        DispatchQueue.main.async(execute: {
                            DispatchQueue.main.async(execute: {
                                self.performSegue(withIdentifier: "goRateFinishedOrder", sender: self)
                            })
                        })
                    }))
                    self.alert.addAction(UIAlertAction(title: "NO", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                        DispatchQueue.main.async(execute: {
                            self.dataManager.order = Order()
                            self.dataManager.setUserPreferences()
                            self.dataManager.order.address = self.searchAddress.text!
                            self.dataManager.order.coordinates = self.currentLocation.coordinate
                        
                        })
                    }))
                    DispatchQueue.main.async(execute: {
                        //clear driver's path
                        self.pathRectangle.map = nil
                        //present alert
                        self.present(self.alert, animated: true, completion: nil)
                    })
                }
                else if(dataManager.order.orderStatus == .CANCELLED){
                    
                    self.alert.dismiss(animated: true, completion: nil)
                    alert = UIAlertController(title: "Order had been cancelled", message: "Your order had been cancelled either by driver or by admin!", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                        DispatchQueue.main.async(execute: {
                                self.dataManager.order = Order()
                                self.dataManager.setUserPreferences()
                                self.dataManager.order.address = self.searchAddress.text!
                                self.dataManager.order.coordinates = self.currentLocation.coordinate
                                self.orderButton.setTitle("ORDER SNOWPLOW", for: .normal)
                                self.orderButton.setTitle("ORDER SNOWPLOW", for: .highlighted)
                        })
                    }) )
                    self.pathRectangle.map = nil
                    self.present(self.alert, animated: true, completion: nil)
                }
                else if(dataManager.order.orderStatus == .NEW){
                    self.alert.dismiss(animated: true, completion: nil)
                    self.alert = UIAlertController(title: "New order!", message: "New order had been created for you by SnoHub", preferredStyle: UIAlertControllerStyle.alert)
                    self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (UIAlertAction) in
                        DispatchQueue.main.async(execute: {
                           self.showCurrentOrder()
                        })
                    }) )
                    self.present(self.alert, animated: true, completion: nil)
                }
                else if(dataManager.order.orderStatus == .ACCEPTED)
                {
                    self.alert.dismiss(animated: true, completion: nil)
                    self.alert = UIAlertController(title: "Order has been accepted!", message: "\(dataManager.order.driver_Name) has accepted your order", preferredStyle: UIAlertControllerStyle.alert)
                    self.alert.addAction(UIAlertAction(title: "YES", style: UIAlertActionStyle.default, handler:nil))
                    self.present(self.alert, animated: true, completion: nil)
                    
                    //put path
                    for (_, marker) in currentMarkers.enumerated().reversed()
                    {
                    
                        if let driver = marker.userData as? Dictionary<String, AnyObject>
                        {
                            if driver["driver_id"] as? Int != 0
                            {
                                
                                        if(driver["driver_id"] as? Int == dataManager.order.driver_id && dataManager.order.id != 0)
                                        {
                                            marker.icon = UIImage(named: "plower_marker_orange")
                                            marker.map = viewMap
                                            
                                            if let _ = self.pathRectangle.path
                                            {
                                                if(!GMSGeometryIsLocationOnPathTolerance(marker.position, self.pathRectangle.path!, true, 25.0))
                                                {
                                                    self.getDirections(location: marker.position , destination: dataManager.order.coordinates, withCompletionHandler: { (result, success) in
                                                        //do anything after we'd successfully drew directions between driver and our order
                                                    })
                                                }
                                            }
                                            else
                                            {
                                                self.getDirections(location: marker.position , destination: dataManager.order.coordinates, withCompletionHandler: { (result, success) in
                                                    //do anything after we'd successfully drew directions between driver and our order
                                                })
                                            }
                                            
                                        }
                                
                             }
                        }
                        
                    }
                }
            }
        
           if(dataManager.etaChanged)
            {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm MM/dd/yyyy"
                if(dataManager.order.eta != nil)
                {
                    let dateStr = dateFormatter.string(from: dataManager.order.eta!)
                    
                    self.alert.dismiss(animated: true, completion: nil)
                    self.alert = UIAlertController(title: "Driver had changed the ETA!", message: "\(dataManager.order.driver_Name) should arrive at " + dateStr, preferredStyle: UIAlertControllerStyle.alert)
                    self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:nil))
                    self.present(self.alert, animated: true, completion: nil)
                    dataManager.etaChanged = false
                }
            }
          //})
        
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
    
    //update drivers online statuses and positions on a map 
    func checkDrivers()
    {
        //dataManager.getOnlineDrivers(location: currentLocation, completionCallback: self.putDriverMarkers)
        putDriverMarkers()
    }
    
    
    @IBAction func startSearch(){
       searchAddress.becomeFirstResponder()
    }
    
    @IBAction func stopSearch(){
        searchAddress.resignFirstResponder()
    }
    
    @IBAction func closeInfo(){
        subviewInfo.isHidden = true
        subviewConstraint.constant = -35
    }
   
    func goToLogin(){
     
        self.performSegue(withIdentifier: "goToLogin", sender: self)
    
    }
    
    //check where to go next. If we don't have an order - go place order, 
    //and if we got one - go to order page depending on what status order has
    @IBAction func goNext()
    {
      
        
        if(dataManager.order.id == 0 && didFindMyLocation)
        {
            if(!(currentLocation.coordinate.latitude == 0 && currentLocation.coordinate.longitude == 0))
            {
                print("SET PREV COORDINATES")
                dataManager.order.coordinates = currentLocation.coordinate
                dataManager.order.address = (self.searchController?.searchBar.text)!
            }
        }
        
      print("Order address: \(dataManager.order.address). Order coordinates: \(dataManager.order.coordinates). Current location: \(currentLocation.coordinate)")
        
      if(dataManager.order.id == 0)
      {
        let count = dataManager.order.address.characters.count
        if(count > 0 && count < 356 )
        {
         self.performSegue(withIdentifier: "goToPlaceOrder", sender: self)
        }
        else
        {
          self.alert.dismiss(animated: true, completion: nil)
          self.alert = UIAlertController(title: "Invalid address!", message: "Address should not be too long or empty. Please enter avalid address", preferredStyle: UIAlertControllerStyle.alert)
          self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
          self.present(self.alert, animated: true, completion: nil)
         
        }
      }
      else
      {
        if(dataManager.order.orderStatus != .NEW && dataManager.order.orderStatus != .SCHEDULED)
        {
          self.performSegue(withIdentifier: "goToOrderState", sender: self)
        }
        else
        {
          self.performSegue(withIdentifier: "goToOrderPlaced", sender: self)
        }
      }
        
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        //we got to stop timer for any segue
        print("Nullifying the timers")
        if(segue.identifier != "ShowSettingsCustomer")
        {
            
        }
        //and stop drivers update timer 
        
        
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
            self.menuConstraint.constant = -260 // heightCon is the IBOutlet to the constraint
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()
        })
  
      }
    
    }
    
    @IBAction func openSettings()
    {
        self.performSegue(withIdentifier: "ShowSettingsCustomer", sender: self)
    }
    
    @IBAction func logOut()
    {
   
        dataManager.LogOut()
        print("LOGGED OUT. CLEARED USER: \(dataManager.user)")
        dataManager.closeSocketConnection()
        DispatchQueue.main.async(execute: {
            self.stopSocketTimer()
        })
        self.performSegue(withIdentifier: "goToLogin", sender: self)
    }
    
    //@available(iOS 10.0, *)
    @IBAction func goToSurropt(){
        if let url = URL(string: "https://snohub.com") {
        //            UIApplication.shared.open(url) {
        //                boolean in
        //                // do something with the boolean
        //            }
          if #available(iOS 10.0, *) {
              UIApplication.shared.open(url, options: [:], completionHandler: nil)
          } else {
              UIApplication.shared.openURL(url)
          }
        }

    }
    
    //@available(iOS 10.0, *)
    @IBAction func goSeeOrdersHistory(){
        let urlString = dataManager.urlBase + "/orders/ordersHistory?token=" + dataManager.user.webTokenID
        if let url = URL(string: urlString) {
            //            UIApplication.shared.open(url) {
            //                boolean in
            //                // do something with the boolean
            //            }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        
    }

    
    @IBAction func goPlaceOrder(){
        menuShown = false
        UIView.animate(withDuration: 0.5, animations: {
            self.menuConstraint.constant = -260 // heightCon is the IBOutlet to the constraint
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()
        })
    
        self.searchController?.searchBar.becomeFirstResponder()
    }
    
    @IBAction func goSeePrices()
    {
        self.performSegue(withIdentifier: "showPricesCustomer", sender: self)
    }
    
    @IBAction func goToMyOrders()
    {
        self.performSegue(withIdentifier: "goToMyOrders", sender: self)
    }
 
    func stopSocketTimer()
    {
        self.dataManager.socketCheckTimer?.invalidate()
        self.dataManager.socketCheckTimer = nil
    }
    
    
}


// Handle the user's selection (of autocomplete).
extension ViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        // Do something with the selected place.
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress ?? defaultValue)")
        print("Place attributions: \(String(describing: place.attributions))")
        dataManager.order.address = place.formattedAddress! // (self.searchController?.searchBar.text)!
        self.searchController?.searchBar.text = place.formattedAddress!
    
        self.currentLocation = CLLocation(latitude: place.coordinate.latitude, longitude: place.coordinate.longitude)
        dataManager.order.coordinates = place.coordinate
        
        if let _ = self.snowPlowLoactionMarker as GMSMarker? {
            self.snowPlowLoactionMarker?.position = place.coordinate
            self.snowPlowLoactionMarker?.icon = UIImage(named: "plow_location")
            self.snowPlowLoactionMarker?.map = self.viewMap
            self.viewMap.animate(with: GMSCameraUpdate.setTarget(place.coordinate))
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.subviewInfo.isHidden = false
            self.subviewConstraint.constant = 5 // heightCon is the IBOutlet to the constraint
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()
        })
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    
    //markers functions
    func copyOldDrivers()
    {
        previousDrivers.removeAll()
        for(_, element) in currentDrivers.enumerated()
        {
          previousDrivers[element.key] = element.value
        }
        currentDrivers.removeAll()
    }
    
    func getBearing(point: CLLocationCoordinate2D, origin: CLLocationCoordinate2D) -> Double {
        func degreesToRadians(degrees: Double) -> Double { return degrees * Double.pi / 180.0 }
        func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / Double.pi }
        
        let lat1 = degreesToRadians(degrees: origin.latitude)
        let lon1 = degreesToRadians(degrees: origin.longitude)
        
        let lat2 = degreesToRadians(degrees: point.latitude);
        let lon2 = degreesToRadians(degrees: point.longitude);
        
        let dLon = lon2 - lon1;
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x);
        
        return radiansToDegrees(radians: radiansBearing)
    }

//camera functions
    
    @IBAction func useCamera(sender: UITapGestureRecognizer) {
        
      
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
            self.userPic.image = resizedImage
             dataManager.user.user_image = resizedImage
            
            dataManager.uploadPicture(imageToLoad: resizedImage, type: 0, completionCallback: { (success, message) in
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
                    
                    self.subviewActions.isHidden = false
                    vc.popoverPresentationController?.delegate = self
                    vc.preferredContentSize = CGSize(width: self.view.bounds.width, height:self.subviewActions.bounds.height)
                    //vc.popoverPresentationController?.sourceView = self.subviewActions
                    //vc.popoverPresentationController?.sourceRect = self.subviewActions.bounds
                    
                    
                    vc.completionWithItemsHandler = {(activityType, completed, items, error) in
                        print("Activity controller status: \(completed)")
                    }
                })
                
            }

            
        }
        
    }
    
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {

        let bounds = CGRect(x:self.subviewActions.bounds.origin.x, y: self.subviewActions.bounds.origin.y, width: self.view.bounds.width, height: self.subviewActions.bounds.height)
        popoverPresentationController.sourceView = self.subviewActions
        popoverPresentationController.sourceRect = bounds
        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection(rawValue:0)

    }

    //home button find and add new functions
    //--------------------------------------
    func findButtonHome()
    {
        for object in viewMap.subviews {
            print("ClassName for subview: \(object.theClassName)")
            if object.theClassName == "GMSUISettingsPaddingView" {
                for view in object.subviews {
                    print("ClassName: \(view.theClassName)")
                    if view.theClassName == "GMSUISettingsView" {
                        for subbutton in view.subviews
                        {
                            print("Settings View className: \(subbutton.theClassName)")
                            if(subbutton.theClassName == "GMSx_QTMButton")
                            {
                                //let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.homeButtonTapped))
                                //gestureRecognizer.delegate = self
                                //subbutton.addGestureRecognizer(gestureRecognizer)
                                
                                if let buttonHome = subbutton as? UIButton
                                {
                                    buttonHome.addTarget(self,action:#selector(self.homeButtonTapped),for:.touchUpInside)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func homeButtonTapped()
    {
        //put snowPlow marker here where your location is
        if(dataManager.order.id == 0 && currentGPSLocation.coordinate.longitude != 0 && currentGPSLocation.coordinate.latitude != 0)
        {
            dataManager.order.coordinates = currentGPSLocation.coordinate
            print("orderCoordinates (location manager): \(dataManager.order.coordinates)")
            
            
            snowPlowLoactionMarker?.position = currentGPSLocation.coordinate
            snowPlowLoactionMarker?.icon = UIImage(named: "plow_location")
            snowPlowLoactionMarker?.map = viewMap
            snowPlowLoactionMarker?.icon = UIImage(named: "plow_location")
            
            self.geocodeLocation(location: currentGPSLocation, withCompletionHandler: {(status, success) -> () in
                if success{
                    self.searchAddress.text = self.fetchedFormattedAddress
                    self.dataManager.order.address = self.fetchedFormattedAddress
                    print("Updated ORDER BY LOCATION: \(self.dataManager.order.coordinates)")
                    self.searchController?.searchBar.text = self.fetchedFormattedAddress
                    self.searchController?.searchBar.sizeToFit()
                    self.currentLocation = self.currentGPSLocation
                    
                    //show save button
                    UIView.animate(withDuration: 0.5, animations: {
                        self.subviewInfo.isHidden = false
                        self.subviewConstraint.constant = 5 // heightCon is the IBOutlet to the constraint
                        self.view.layoutIfNeeded()
                        self.view.layoutSubviews()
                    })
                }
                else{
                    
                }
            })
        }

    
    }
    // \home button find and add new functions
    //--------------------------------------
    
    
    
    //SOCKET NOTIFICATIONS
    
    //orderStatusChanged
    func onOrderStatusCnahged(withNotification notification : NSNotification)
    {
       print("ORDER STATUS CHANGED : NOTIFICATION CAME")
       checkOrderStatus()
    }
    
    //drivers list been updated from socket
    func onDriversUpdated(withNotification notification : NSNotification)
    {
      print("DRIVERS LIST BEEN UPDATED")
      self.checkDrivers()
    }
    
    //socket message on being logged out
    func onGotLoggedOut(withNotification notification : NSNotification)
    {
        if(dataManager.gotLoggedOut)
        {
            self.alert.dismiss(animated: true, completion: nil)
            self.alert = UIAlertController(title: "Login error!", message: "You were logged out from server. Someone may have logged you in from other device. Please try to login again." , preferredStyle: UIAlertControllerStyle.alert)
            self.alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {
                UIAlertAction in
                self.goToLogin()
            }) )
            
            DispatchQueue.main.async(execute: {
                self.present(self.alert, animated: true, completion: nil)
                self.stopSocketTimer()
            })
            
        }
    }
    
  }


//searchBar text color
extension UISearchBar {
    public func setSearchTextcolor(color: UIColor) {
        let clrChange = subviews.flatMap { $0.subviews }
        guard let sc = (clrChange.filter { $0 is UITextField }).first as? UITextField else { return }
        sc.textColor = color
    }
}

//image extension
extension UIImage {
    
    func crop(to:CGSize) -> UIImage {
        guard let cgimage = self.cgImage else { return self }
        
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        
        let contextSize: CGSize = contextImage.size
        
        //Set to square
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        let cropAspect: CGFloat = to.width / to.height
        
        var cropWidth: CGFloat = to.width
        var cropHeight: CGFloat = to.height
        
        if to.width > to.height { //Landscape
            cropWidth = contextSize.width
            cropHeight = contextSize.width / cropAspect
            posY = (contextSize.height - cropHeight) / 2
        } else if to.width < to.height { //Portrait
            cropHeight = contextSize.height
            cropWidth = contextSize.height * cropAspect
            posX = (contextSize.width - cropWidth) / 2
        } else { //Square
            if contextSize.width >= contextSize.height { //Square on landscape (or square)
                cropHeight = contextSize.height
                cropWidth = contextSize.height * cropAspect
                posX = (contextSize.width - cropWidth) / 2
            }else{ //Square on portrait
                cropWidth = contextSize.width
                cropHeight = contextSize.width / cropAspect
                posY = (contextSize.height - cropHeight) / 2
            }
        }
        
        let rect: CGRect = CGRect(x:posX, y:posY, width:cropWidth, height:cropHeight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = contextImage.cgImage!.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let cropped: UIImage = UIImage(cgImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        
        UIGraphicsBeginImageContextWithOptions(to, true, self.scale)
        cropped.draw(in: CGRect(x:0, y:0, width:to.width, height:to.height))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resized!
    }
}

//searchBar extension to make it completely white
extension UISearchBar {
    
    func cleanWhite(){
        for view in self.subviews.last!.subviews {
            //print("view class: " + String(describing: type(of: view)))
            if view.isKind(of: NSClassFromString("UISearchBarBackground")!) {
                view.removeFromSuperview()
            }
            
        }
        
        for view in self.subviews.last!.subviews {
            print("view class: " + String(describing: type(of: view)))
            
        }

    }
    
}

extension NSObject {
    var theClassName: String {
        return NSStringFromClass(type(of: self))
    }
}
