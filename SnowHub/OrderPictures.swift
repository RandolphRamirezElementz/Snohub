//
//  OrderFirstStep.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/2/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit
import MobileCoreServices

class OrderPictures: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, DropdownViewDelegate {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var nextItem: UIBarButtonItem!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet weak var firstImage: UIImageView!
    @IBOutlet weak var exampleImage: UIImageView!
    
    @IBOutlet weak var pictureLoading: UIActivityIndicatorView!

    //pickers
    @IBOutlet weak var detailsView: TopView!
    @IBOutlet weak var myPicker: UIPickerView!
    
    @IBOutlet var driveWayLength:BorderedViewDropdown!
    @IBOutlet var snowDepth:BorderedViewDropdown!
    
    
    var currentDropdown: BorderedViewDropdown? = nil
    var pickData: [String] = []

    var newMedia: Bool?
    var targetImageView: UIImageView?
    var picTaken: Bool = false
    var dataManager:DataManager = DataManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("CURRENT ORDER TAKEN: \(dataManager.takenOrder)")
        styleUnselectedImage(toImage: firstImage)

        driveWayLength.pickList = dataManager.roadLengths
        driveWayLength.valueLabel.text = driveWayLength.pickList[0]
        driveWayLength.parent = self
        
        
        
        if(dataManager.takenOrder.driveWayLength > 0 && dataManager.takenOrder.driveWayLength < 6)
        {
            driveWayLength.valueLabel.text = driveWayLength.pickList[dataManager.takenOrder.driveWayLength]
            driveWayLength.setValue = dataManager.takenOrder.driveWayLength
        }

        snowDepth.pickList = dataManager.snowDepthArray
        snowDepth.valueLabel.text = snowDepth.pickList[2]
        snowDepth.setValue = 2
        snowDepth.parent = self
        
        myPicker.delegate = self
        myPicker.dataSource = self
        
    }

    //before view appears
    override func viewWillAppear(_ animated: Bool) {
        if(dataManager.takenOrder.orderStatus != .ACCEPTED)
        {
            self.detailsView.isHidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

   
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "picTakenGoCharge" {
            print("Sending order details: \(DataManager.sharedInstance.takenOrder)")
            if let destination = segue.destination as? OrderCloseController {
                destination.currentOrder = DataManager.sharedInstance.takenOrder
            }
        }

    }
   
    
    private func styleSelectedImage(toImage: UIImageView)
    {
        toImage.layer.borderWidth = 0.0
        toImage.layer.cornerRadius = 7.0
        toImage.clipsToBounds = true
        toImage.layer.masksToBounds = false
        toImage.layer.shadowColor = UIColor.black.cgColor;
        toImage.layer.shadowOffset = CGSize(width:5.0, height:5.0);
        toImage.layer.shadowOpacity = 0.5;
        toImage.layer.shadowRadius = 10.0;
        
        //add view for clipping mask
        let borderView = UIView()
        borderView.frame = toImage.bounds
        borderView.clipsToBounds = true
        borderView.layer.cornerRadius = 7
        borderView.layer.borderColor = UIColor.black.cgColor
        borderView.layer.borderWidth = 0.0
        borderView.isUserInteractionEnabled = false
        borderView.layer.masksToBounds = true
        
        toImage.addSubview(borderView)
        
    }
    
    private func styleUnselectedImage(toImage: UIImageView){
        toImage.layer.borderWidth = 1.0
        toImage.layer.cornerRadius = 7.0
        toImage.clipsToBounds = true
        toImage.layer.borderColor = UIColor.white.cgColor
    }
    

    @IBAction func useCamera(sender: UITapGestureRecognizer) {
        
        targetImageView = sender.view as? UIImageView
        
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.camera) {
            
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = true
            imagePicker.showsCameraControls = true
            imagePicker.isModalInPopover = true
            imagePicker.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            
            imagePicker.preferredContentSize = CGSize(width: 450, height: 450);
            //imagePicker.cameraOverlayView = overlayView
        
            imagePicker.delegate = self
            imagePicker.sourceType =
                UIImagePickerControllerSourceType.camera
            imagePicker.mediaTypes = [(kUTTypeImage as NSString) as String]
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true,
                                       completion: nil)
            newMedia = true
        }
    }
    
    @IBAction func useCameraRoll(sender: UILongPressGestureRecognizer) {
        
        targetImageView = sender.view as? UIImageView
        
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
            newMedia = true
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        self.dismiss(animated: true, completion: nil)
        self.exampleImage.isHidden = true
        
        if mediaType == (kUTTypeImage as String) {
            let image = info[UIImagePickerControllerOriginalImage]
                as! UIImage
            
            targetImageView?.contentMode = UIViewContentMode.scaleAspectFit
            targetImageView?.image = image
            if let _ = targetImageView as UIImageView?{
             self.styleSelectedImage(toImage: targetImageView!)
            }
            
            if (newMedia == true) {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
                
                //uploady
                let dataManager:DataManager = DataManager.sharedInstance
                
                picTaken = true
                if(dataManager.takenOrder.orderStatus == .ACCEPTED)
                {
                  //not sure if we have to do anything
                }
                else if(dataManager.takenOrder.orderStatus == .IN_PROGRESS)
                {
                  nextButton.setTitle("CHARGE", for: .highlighted)
                  nextButton.setTitle("CHARGE", for: .normal)
                }
                
            } else if mediaType == (kUTTypeMovie as String) {
                // Code to support video here
            }
            
        }
        
        
    }
    
    @IBAction func goNext(){
        if(picTaken)
        {
            picTaken = false
            pictureLoading.startAnimating()
            nextButton.isEnabled = false;
            
            let downsizedImage = resizeImage(image: self.firstImage.image!, newWidth: 300)
            self.firstImage.image = downsizedImage
            
            let dataManager:DataManager = DataManager.sharedInstance
            if(dataManager.takenOrder.orderStatus == .ACCEPTED)
            {
                
                let road_length = self.driveWayLength.setValue
                let inches = self.snowDepth.setValue + 1
            
                //upload picture and set status in single transaction
                dataManager.setInProgress(imageToLoad: downsizedImage, inches: inches, road_length: road_length, completionCallback: { (success, message) in
                  
                  if(success)
                  {
                    dataManager.takenOrder.orderStatus = .IN_PROGRESS
                    DispatchQueue.main.async(execute: {
                        self.pictureLoading.stopAnimating()
                        self.nextButton.isEnabled = true
                        dataManager.setUserPreferences()
                        self.performSegue(withIdentifier: "picTakenGoToMap", sender: self)
                    })
                  }
                  else
                  {
                    self.picTaken = true
                    
                    DispatchQueue.main.async(execute: {
                    self.pictureLoading.stopAnimating()
                    self.nextButton.isEnabled = true
                    let alert = UIAlertController(title: "Order Change Failed", message: message, preferredStyle: UIAlertControllerStyle.alert)
                    let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                    })
                  }
                    
                })
                
            }
            else if(dataManager.takenOrder.orderStatus == .IN_PROGRESS)
            {
                //dataManager.takenOrder.orderStatus = 3 //we'll change the status when we get there on server (in charge)
                dataManager.uploadPicture(imageToLoad: self.firstImage.image!, type: 3, completionCallback: { (success, message) in
                    print(message)
                    
                    //dataManager.setUserPreferences()
               
                    DispatchQueue.main.async(execute: {
                        
                        self.pictureLoading.stopAnimating()
                        self.nextButton.isEnabled = true;
                        
                        dataManager.setUserPreferences()
                        self.performSegue(withIdentifier: "picTakenGoCharge", sender: self)
                    })
                    
                })
                
                
            }
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
        
        return newImage!
    }
    
    //picker delegate methods---------------------------------------
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        print("PickList: \(pickData)")
        return pickData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        currentDropdown?.setValue = row
        currentDropdown?.valueLabel.text = pickData[row]
        pickerView.isHidden = true
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    //---------------------------------------------------------------

}
