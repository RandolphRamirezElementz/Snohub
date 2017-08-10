//
//  OrderController.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/15/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//
//
// FOR DRIVER. HERE DRIVER CAN TAKE AN ORDER
//
//

import UIKit

class OrderController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var detailsView: UIView!
    @IBOutlet weak var minFareView: UIView!
    
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
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var navigationBar: UINavigationBar!
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var roadLengthLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    //constraints for order details form
    @IBOutlet weak var secondConstraint: NSLayoutConstraint!
    @IBOutlet weak var thirdConstraint: NSLayoutConstraint!
    @IBOutlet weak var fourthConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var fifthConstraint: NSLayoutConstraint!
    @IBOutlet weak var sixthConstraint: NSLayoutConstraint!
    @IBOutlet weak var seventhConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollHeightConstraint: NSLayoutConstraint!

    //map view and its constraints and gradient
     @IBOutlet weak var viewMap: GMSMapView!
     @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var scrollView: UIScrollView!
     var locationManager = CLLocationManager()
     var didFindMyLocation = false
     var myCoordinate:CLLocationCoordinate2D = CLLocationCoordinate2D()
     var pathRectangle = GMSPolyline()
    
    var currentOrder_index: Int = 0
    //var currentOrder: Dictionary? = Dictionary<String, Any?>()
    var currentOrder: Order? = nil
    var dataManager:DataManager = DataManager.sharedInstance
      
    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewMap.settings.myLocationButton = false
        //self.setMap()
    
        
        //initial constraints set
        viewHeightConstraint.constant = 44
        scrollHeightConstraint.constant = 450
        secondConstraint.constant = 17
        thirdConstraint.constant = 17
        fourthConstraint.constant = 17
        fifthConstraint.constant = 17
        sixthConstraint.constant = 17
        seventhConstraint.constant = 17

        let length_types = dataManager.roadLengths
        
        print("\(String(describing: currentOrder))")
        
        if let order = currentOrder {
            
            addressLabel.text = order.address
            nameLabel.text = order.client_name
            priceLabel.text = "$" + String.localizedStringWithFormat("%.2f", order.driver_fee + order.debt)
            
            if(order.deicing != 0){
                          deicingLabelmark.isHidden = false
                          deicingLabel.isHidden = false
              }
            
            if(order.driveWayLength >= 0 && order.driveWayLength < 6)
            {
                self.roadLengthLabel.text = length_types[order.driveWayLength]
            }
            
            if(order.markersThere){
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
            
            if(order.asphaltDriveway){
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
           if(order.gravelDriveway){
                               thirdLabelmark.isHidden = false
                               thirdLabel.isHidden = false
                               fourthConstraint.constant += 27
                               viewHeightConstraint.constant += 27
                               fifthConstraint.constant += 27
                               sixthConstraint.constant += 27
                               seventhConstraint.constant += 27
                                scrollHeightConstraint.constant += 27
            
                           }
            if(order.otherIssues){
                                   fourLabelmark.isHidden = false
                                   notesText.isHidden = false
                                   notesText.text = order.issuesThere
                                   viewHeightConstraint.constant += 27
                                   fifthConstraint.constant += 27
                                   sixthConstraint.constant += 27
                                   seventhConstraint.constant += 27
                                    scrollHeightConstraint.constant += 27
                               }
            
            if(order.clean_front_walkway)
            {
                 scrollHeightConstraint.constant += 27
                viewHeightConstraint.constant += 27
                sixthConstraint.constant += 27
                seventhConstraint.constant += 27
                fifthLabel.isHidden = false
                fifthLabelmark.isHidden = false

            }
            
            if(order.clean_back_walkway)
            {
                 scrollHeightConstraint.constant += 27
                viewHeightConstraint.constant += 27
                seventhConstraint.constant += 27
                sixthLabel.isHidden = false
                sixthLabelmark.isHidden = false
            }
            
            if(order.clean_side_walkway)
            {
                 scrollHeightConstraint.constant += 27
                viewHeightConstraint.constant += 27
                seventhLabel.isHidden = false
                seventhLabelmark.isHidden = false
            }
            
            
            if(order.time_stamp != nil)
            {
                                 let dateFormatter = DateFormatter()
                                 dateFormatter.dateFormat = "MM/dd/yyyy"
                                 dateLabel.text = dateFormatter.string(from: (order.time_stamp)!)
                                 dateFormatter.dateFormat = "HH:mm"
                                 timeLabel.text = dateFormatter.string(from: (order.time_stamp)!)
            }
            
        }
        
        acceptButton.setTitleColor(UIColor.white, for: .highlighted)
        acceptButton.setTitleColor(UIColor.white, for: .normal)
        
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        navigationBar.layer.masksToBounds = false;
        navigationBar.layer.shadowOffset = CGSize(width: 0, height: 8);
        navigationBar.layer.shadowRadius = 5;
        navigationBar.layer.shadowOpacity = 0.3;

        //repalce buttons if we're looking at our current order
        if(dataManager.takenOrder.id == currentOrder?.id)
        {
           acceptButton.isHidden = true
           callButton.isHidden = false
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        let bounds = scrollView.bounds
        let bounds_fixed = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: self.view.bounds.width, height: bounds.height)
        scrollView.bounds = bounds_fixed
        setMap()
    }
    
    //getting location manager and map set
    func setMap(){

        self.viewMap.settings.myLocationButton = false
        
        locationManager.delegate = self;
        locationManager.requestAlwaysAuthorization();
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.startUpdatingLocation()

        //additional setup of google camera
        let camera: GMSCameraPosition = GMSCameraPosition.camera(withLatitude: 48.857165, longitude: 2.354613, zoom: 16.0)
        viewMap.camera = camera
        viewMap.delegate = self
        viewMap.isMyLocationEnabled = true
        
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
        
        viewMap.settings.consumesGesturesInView = false
        viewMap.settings.scrollGestures = false
        gradientView.setupView()
        //gradientView.sizeToFit()
        
        //set  marker on the order location
        if currentOrder != nil
        {
            myCoordinate = (currentOrder?.coordinates)!
            
            let zoom = viewMap.camera.zoom
            viewMap.camera = GMSCameraPosition.camera(withTarget: myCoordinate, zoom: zoom)
            
            let locationMarker = GMSMarker(position: myCoordinate)
            locationMarker.map = viewMap
            locationMarker.appearAnimation = GMSMarkerAnimation.pop
            locationMarker.icon = UIImage(named: "order_marker_orange")
            locationMarker.opacity = 0.75
        }
        
    }
    
    //-----------location manager delegates
    //location manager delegate methods
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        //locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse ||  status == CLAuthorizationStatus.authorizedAlways {
                    locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]) {
        
        let locationArray = locations as NSArray
        let locationObj = locationArray.lastObject as! CLLocation
        
        if(!didFindMyLocation ) //set location for first time
        {
            viewMap.settings.myLocationButton = false
            viewMap.settings.indoorPicker = true
            didFindMyLocation = true
            
            locationManager.stopUpdatingLocation()
    
            self.getDirections(location: locationObj.coordinate, destination: self.myCoordinate, withCompletionHandler: { (result, success) in
                
            })
        
        }
    
        
    }
    

    //----------------------------------------------------------

    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goSetTime" {
            if let destination = segue.destination as? OrderTimerController {
                destination.currentOrder_index = self.currentOrder_index
                destination.currentOrder = self.currentOrder!
                
            }
        }
        
    }
    
    @IBAction func acceptOrder(){
        
        print("CURRENT ORDER: \(String(describing: self.currentOrder))")
        if(dataManager.orderIsValidToTake(order: self.currentOrder) ){
            
            let order_id = self.currentOrder?.id
            
            dataManager.acceptOrder(id: order_id!,  completionCallback: {(success, message) in
                if(success)
                {
                    if (self.currentOrder != nil) {
                        
                        //print("CURRENT ORDER: \(self.currentOrder)")
                       
                        self.dataManager.takenOrder = self.currentOrder!
                        self.dataManager.takenOrder.orderStatus = .ACCEPTED
                        self.dataManager.setUserPreferences()
                    }
                    
                    print("ORDER BEEN ACCEPTED : \(self.dataManager.takenOrder)")
                    
                    DispatchQueue.main.async(execute: {
                        self.performSegue(withIdentifier: "goSetTime", sender:self) //go to next stage
                    })
                }
                else
                {
                    let alert = UIAlertController(title: "Error", message: message == "" ? "Some error happened while acceptring order. Check your order details and Internet connection" : message , preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    
                    DispatchQueue.main.async(execute: {
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                
            })
        }
        else
        {
            let alert = UIAlertController(title: "Error", message: "Your login or order info is incorrect", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }


    //get directions to our location
    func getDirections(location: CLLocationCoordinate2D, destination: CLLocationCoordinate2D, withCompletionHandler completionHandler: @escaping ((_ status: String, _ success: Bool) -> Void)) {
        let gmsApiKey: String! = "AIzaSyAkuYvAco7GALUTx1T-EG9CAgvgbug5U6U"
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
                            let results = dictionary["routes"] as! [Dictionary<String, AnyObject>]
                            if let routeResult = results[0] as Dictionary<String, AnyObject>?
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

}
