//
//  OnboardingStepOne.swift
//  SnowHub
//
//  Created by Liubov Perova on 4/24/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit
import MobileCoreServices
import Kingfisher
import KYCircularProgress

class OnboardingStepOne: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet weak var waitingWheel: UIActivityIndicatorView!
    @IBOutlet weak var takenImage: GradienImageView!
    @IBOutlet weak var chooseSourceView: InfoView!
    @IBOutlet weak var infoLabel: UILabel!

    
    
    var loading: Bool = false
    var UIImageData: Data? = nil
    var imageTaken = false
    var image_key:String { get { return "onboarding_step_1" } }
    var step_key:String  { get { return "1" } }
    var imagePicked:UIImage? = nil
    
    var uploadProgressBar:KYCircularProgress? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        
        waitingWheel.stopAnimating()
        waitingWheel.isHidden = true

       
        // Do any additional setup after loading the view.
        self.takenImage.layer.borderColor = UIColor(red:(1.0), green:(1.0), blue:(1.0), alpha:0.18).cgColor
        self.takenImage.layer.cornerRadius = 4.0
        self.takenImage.layer.borderWidth = 1.0
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
    
    
    //delegate methods for camera controller
    //camera functions
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        //add observer for uploadStatusChanged
        NotificationCenter.default.removeObserver(self, name: .onBoardingStepFinished, object: nil)
        NotificationCenter.default.removeObserver(self, name: .bytesSendForStep, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onStepFinished(withNotification:)), name: .onBoardingStepFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onProgressUpdated(withNotification:)), name: .bytesSendForStep, object: nil)

        self.navigationController?.isNavigationBarHidden = true

        self.loading = true
        
        if let image = self.imagePicked{
            self.takenImage.image = image
            self.UIImageData = UIImageJPEGRepresentation(image, 1.0)
            self.takenImage.setupView()
            //self.imageTaken = true
            self.infoLabel.text = "Tap to edit"
            print("Retrieved image from disk cache for step \(self.step_key)")
        }
        else if let image = ImageCache.default.retrieveImageInDiskCache(forKey: self.image_key, options: nil)
        {
           self.takenImage.image = image
           self.UIImageData = UIImageJPEGRepresentation(image, 1.0)
           self.takenImage.setupView()
           //self.imageTaken = true
            self.infoLabel.text = "Tap to edit"
           print("Retrieved image from disk cache for step \(self.step_key)")
        }
        else
        {
            ImageCache.default.retrieveImage(forKey: self.image_key, options: nil) {
                image, cacheType in
                if let image = image {
                    //self.imageTaken = true
                    self.takenImage.image = image
                    self.infoLabel.text = "Tap to edit"
                    self.UIImageData = UIImageJPEGRepresentation(image, 1.0)
                    self.takenImage.setupView()
                } else {
                    print("Step \(self.step_key) does not exist in cache. Try to get from URL")
                    self.getOnboardingImage(step:self.step_key)
                }
            }
        }
        self.loading = false
        //circular progressbar
        //let it show up only if upload in progress
        if self.stepIsUploading()
        {
           self.loading = true
        }
        
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .onBoardingStepFinished, object: nil)
        NotificationCenter.default.removeObserver(self, name: .bytesSendForStep, object: nil)

    }
    
    //function to check if current step is uploading any image
    func stepIsUploading() -> Bool{
     
     let uploadManager = UploadsManager.sharedInstance
     var isUploading = false
        
        if let step:Dictionary<String, Any> = uploadManager.onboardingSteps[self.step_key] as? Dictionary<String, Any>
        {
            if let started = step["started"] as? Bool, let finished = step["finished"] as? Bool, let progress = step["progress"] as? Float
            {
                if started && !finished
                {
                    DispatchQueue.main.async(execute: {
                        self.configureHalfCircularProgress(progress: Double(progress))
                    })
                    isUploading = true
                }
                else
                {
                    self.nextButton.isEnabled = true
                    self.prevItem.isEnabled = true
                }
            }

        }
     return isUploading
    }
    
    //is given stap  uploading? 
    func stepIsUploading(step_number: String) -> Bool{
        
        let uploadManager = UploadsManager.sharedInstance
        var isUploading = false
        
        if let step:Dictionary<String, Any> = uploadManager.onboardingSteps[step_number] as? Dictionary<String, Any>
        {
            if let started = step["started"] as? Bool, let finished = step["finished"] as? Bool, let active = step["active"] as? Bool
            {
                if started && !finished && active
                {
                    isUploading = true
                }
            }
            
        }
        return isUploading
    }

    
    
    @IBAction func showChooseView()
    {
        //if something is loading right now, then return
        if loading {
         return
        }
        
        self.chooseSourceView.isHidden = false
     
        UIView.animate(withDuration: 0.5, animations: {
            self.chooseSourceView.isHidden = false
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()
        })
    }
    
    @IBAction func closeChooseView()
    {
        self.chooseSourceView.isHidden = true
        
        UIView.animate(withDuration: 0.5, animations: {
            self.chooseSourceView.isHidden = true
            self.view.layoutIfNeeded()
            self.view.layoutSubviews()
        })
    }
    
    @IBAction func useCamera() {
        
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.camera) {
            
            let imagePicker = UIImagePickerController()
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = false
            imagePicker.showsCameraControls = true
            imagePicker.isModalInPopover = true
            
            imagePicker.modalPresentationStyle = UIModalPresentationStyle.overFullScreen

            //create overlay view 
            let overlayView: UIView = UIView()
            overlayView.frame = self.takenImage.frame
            overlayView.backgroundColor = UIColor.clear
            overlayView.layer.borderColor = UIColor(red:(0.0), green:(0.0), blue:(0.0), alpha:0.8).cgColor
            overlayView.layer.cornerRadius = 4.0
            overlayView.layer.borderWidth = 2.0
            imagePicker.cameraOverlayView = overlayView
            
            
            imagePicker.delegate = self
            imagePicker.sourceType =
                UIImagePickerControllerSourceType.camera
            imagePicker.mediaTypes = [(kUTTypeImage as NSString) as String]
            //imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true,
                         completion: nil)
            
        }
    }
    
    @IBAction func useCameraRoll() {
        
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.savedPhotosAlbum) {
            
            let imagePicker = UIImagePickerController()
            imagePicker.allowsEditing = true
            //imagePicker.showsCameraControls = true
            
            let width =  self.takenImage.frame.width * UIScreen.main.scale
            let height = self.takenImage.frame.height * UIScreen.main.scale
            
            imagePicker.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext

            imagePicker.preferredContentSize = CGSize(width: width, height: height)
            
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
            if let image = info[UIImagePickerControllerOriginalImage]
                as? UIImage {
                let width =  self.takenImage.bounds.width
                let height = self.takenImage.bounds.height
                
                if let croppedImage = self.cropImageToSize(image: image, size: CGSize(width: width, height:height))
                {
                    imageTaken = true
                    imagePicked = croppedImage
                    self.infoLabel.text = "Tap to edit"
                    self.UIImageData = UIImageJPEGRepresentation(croppedImage, 1.0)
                    print("Image data length: \(String(describing: self.UIImageData?.count))")
                    
                    ImageCache.default.store(croppedImage, forKey: self.image_key)
                    
                    self.takenImage.image = croppedImage
                    self.takenImage.setupView()
                    self.takenImage.layoutSubviews()
                    self.takenImage.layoutIfNeeded()
                    self.takenImage.setupView()
                    
                    
                    UIView.animate(withDuration: 0.5, animations: {
                        self.chooseSourceView.isHidden = true
                        self.view.layoutIfNeeded()
                        self.view.layoutSubviews()
                    })
                }
                
                
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

    //image been made, load everything to server
    
    @IBAction func goNext()
    {
        let dataManager:DataManager = DataManager.sharedInstance
        
        if(!imageTaken && isStepPassed())
        {
           self.goToNextStep()
           return
        }
        
        if( (dataManager.user.SIDunaccepted == "" && dataManager.user.SID == "") || self.UIImageData == nil /*|| !imageTaken */)
        {
            var message = "Please choose an image"
             if(dataManager.user.SIDunaccepted == "" && dataManager.user.SID == "")
             {
              message = "Your login is invalid!"
             }
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            //DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
            //})
        }
        else
        {
            
            self.nextButton.isEnabled = false
            self.prevItem.isEnabled = false
//            self.waitingWheel.startAnimating()
//            self.waitingWheel.isHidden = false
            
            
            /*
            
             let parameters = [
             "session_id": dataManager.user.SIDunaccepted as Any,
             "image": self.takenImage.image as Any
             ]
             
            dataManager.postFormData(parameters: parameters, urlstring: "/users/registerDriver/1", completionCallback: { (success, message) in
              
                DispatchQueue.main.async(execute: {
                  self.nextButton.isEnabled = true
                  self.prevItem.isEnabled = true
                  self.waitingWheel.stopAnimating()
                  self.waitingWheel.isHidden = true
                })
                
                if(success)
                {
                    //go to next step
                    DispatchQueue.main.async(execute: {
                        //ImageCache.default.store(self.takenImage.image!, forKey: self.image_key)
                        dataManager.onboarding_info["1"] = ["step_status":"PASSED"]
                        self.goToNextStep()
                    })
                }
                else
                {
                    let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    
                    DispatchQueue.main.async(execute: {
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                
            })
          */
           
           // let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
           // let filePath = "\(paths[0])/\(self.image_key).jpg"
           // UIImageJPEGRepresentation(self.takenImage.image!, 0.9)?.write(to: URL(fileURLWithPath: filePath))
           
           //upload image asynchronously via the upload manager
           let uploadManager = UploadsManager.sharedInstance
           uploadManager.startUpload(step_number: self.step_key, image: self.imageRotatedNormal(image:self.takenImage.image!) )
            

           //maenwhile go to next step
            DispatchQueue.main.async(execute: {
                self.goToNextStep()
            })
 
            
        }
        
    }

    @IBAction func goBack(){
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func getOnboardingImage(step: String){

        let dataManager = DataManager.sharedInstance

        if dataManager.onboarding_info.count > 0
        {
            if let stepOne = dataManager.onboarding_info[step] as? Dictionary<String, Any>
            {
                if let img_path = stepOne["pic_url"] as? String
                {
                    let url = URL(string: dataManager.urlBase + "/" + img_path)!
                    let resource = ImageResource(downloadURL: url, cacheKey: self.image_key)
                    
                    //let p = Bundle.main.path(forResource: "loading_spinner", ofType: "gif")!
                    //let img_data = try! Data(contentsOf: URL(fileURLWithPath: p))
                    
                    //self.takenImage.kf.indicatorType = .image(imageData: img_data)
                    self.takenImage.kf.indicatorType = .activity
                    
                    self.loading = true
                    self.infoLabel.text = "Loading saved image..."
                    self.takenImage.kf.setImage(with: resource, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { (image, error, cachetype, url) in
                        //if let _ = image {
                            DispatchQueue.main.async(execute: {
                                self.loading = false
                                self.infoLabel.text = "Tap to edit"
                                if let _ = image {
                                    self.takenImage.setupView()
                                    //self.imageTaken = true
                                    self.UIImageData = UIImageJPEGRepresentation(image!, 1.0)
                                }
                            })
                        //}
                    })
                }
            }
        }

    }

    //go to summary if all steps are passed or go to unfinished step(first we'd found)
    func goToNextStep(){
        if OnboardingSummary.numberOfStepsFinished() == 8
        {
            self.performSegue(withIdentifier: "goToSummaryFromStep1", sender: self)
        }
        else
        {
            //self.performSegue(withIdentifier: "goToStep2", sender:self)
            self.goToMinUnfinishedStep()
        }
    }
    
    //check if this step is passed
    func isStepPassed() -> Bool
    {
        var passed = false
        
        let dManager = DataManager.sharedInstance
        if dManager.onboarding_info.count > 0
        {
              if let step_info = dManager.onboarding_info[step_key] as? NSDictionary
                {
                    if let is_checked = step_info["step_status"] as? String
                    {
                        if is_checked != StepStatus.NOT_PASSED.rawValue
                        {
                            passed = true
                        }
                    }
                }
           
        }
       
        return passed
    }
    
    //go to min unfinished step
    func goToMinUnfinishedStep()
    {
        
        let dataManager = DataManager.sharedInstance
        
        var controllerID = "OnboardingStep"
        var min_step = 9;
        for (index, element) in dataManager.onboarding_info
        {
            if let step_info = element as? NSDictionary, index != self.step_key, !stepIsUploading(step_number: index)
            {
                if let is_checked = step_info["step_status"] as? String
                {
                    if is_checked == StepStatus.NOT_PASSED.rawValue || is_checked == StepStatus.REJECTED.rawValue
                    {
                        if(min_step > Int(index)!)
                        {
                            min_step = Int(index)!
                        }
                    }
                }
            }
        }
        DispatchQueue.main.async(execute: {
            
            if min_step < 9
            {
                controllerID = "OnboardingStep\(String(min_step))"
                let nextController = self.storyboard?.instantiateViewController(withIdentifier: controllerID)
                if let _ = nextController
                {
                    let navigationController = UINavigationController(rootViewController: nextController!)
                    self.present(navigationController, animated: true, completion: nil)
                }
            }
            else
            {
                self.performSegue(withIdentifier: "goToSummaryFromStep\(self.step_key)", sender: self)
            }
            
        })
    }

    //crop image to frame
    func cropImageToSize(image: UIImage, size: CGSize) -> UIImage? {

        let refWidth : CGFloat = CGFloat(image.cgImage!.width)
        let refHeight : CGFloat = CGFloat(image.cgImage!.height)
        var scaleX = refWidth / UIScreen.main.bounds.width
        var scaleY = refHeight / UIScreen.main.bounds.height
        var x = (refWidth - size.width * scaleX) / 2
        var y = (refHeight - size.height * scaleX) / 2
        var cropRect = CGRect(x: x, y: y, width: size.width*scaleX, height: size.height*scaleX)
        
        
                //the orientation gets messed when it comes to taken image so we should take care of min and max side
        if refWidth > refHeight
        {
            scaleX = refHeight / UIScreen.main.bounds.width
            scaleY = refWidth / UIScreen.main.bounds.height
            y = (refHeight - size.width * scaleX) / 2
            x = (refWidth - size.height * scaleX) / 2
            cropRect = CGRect(x: x, y: y, width: size.height*scaleX, height: size.width*scaleX)
        }
        
        print("Original image size: \(refWidth), \(refHeight)")
        print("Scale: \(scaleX), \(scaleY)")
        print("Screen Bounds: \(UIScreen.main.bounds.width), \(UIScreen.main.bounds.height)")
        print("CropRect: \(cropRect)")
        if let imageRef = image.cgImage!.cropping(to: cropRect) {
            return UIImage(cgImage: imageRef, scale: 0, orientation: image.imageOrientation)
        }
        
        return nil
    }
    
    //image rotations
    func imageRotatedNormal(image: UIImage) -> UIImage {
       
       var imageTurned = image
       let refWidth : CGFloat = CGFloat(imageTurned.cgImage!.width)
       let refHeight : CGFloat = CGFloat(imageTurned.cgImage!.height)
 
       //if orientation is wrong (cropped image shpuld be landscaped), then turn image 90 degrees
      if(refHeight > refWidth)
       {
         imageTurned = image.fixOrientation()//image.imageRotatedByDegrees(degrees: 90.0)
       }
        
       return imageTurned
    }
    
    //handle notifications
    func onStepFinished(withNotification notification : NSNotification)
    {
        print("Step finished info: \(String(describing: notification.userInfo))")
        if let info = notification.userInfo as? Dictionary<String, Any>
        {
            if let step_number = info["step_number"] as? String
            {
              if step_number == self.step_key
              {
                if let success = info["success"] as? Bool , let message = info["error"] as? String
                {
                  runFinishHandler(success: success, message: message)                
                }
                
              }
            }
        
        }
    }
    
    
    //progress updated according to upload manager
    func onProgressUpdated(withNotification notification : NSNotification){

        if let info = notification.userInfo as? Dictionary<String, Any>
        {
            if let step_number = info["step_number"] as? String
            {
                if step_number == self.step_key
                {
                    let uploadManager = UploadsManager.sharedInstance
                    if let step:Dictionary<String, Any> = uploadManager.onboardingSteps[self.step_key] as? Dictionary<String, Any>
                    {
                        if let started = step["started"] as? Bool, let finished = step["finished"] as? Bool, let progress = step["progress"] as? Float
                        {
                            if started && !finished
                            {
                                if self.uploadProgressBar == nil
                                {
                                    DispatchQueue.main.async(execute: {
                                        self.configureHalfCircularProgress(progress: Double(progress))
                                    })
                                }
                                else
                                {
                                    DispatchQueue.main.async(execute: {
                                        self.uploadProgressBar?.set(progress: Double(progress), duration: 0.0)
                                    })
                                }
                            }
                        }
                        
                    }
                }
            }
        }
    
    }
    
    private func configureHalfCircularProgress(progress: Double) {
        uploadProgressBar = KYCircularProgress(frame: CGRect(x: view.frame.width/2 - view.frame.width/8,
                                                             y: view.frame.height/2 -  view.frame.height/8,
                                                             width: view.frame.width/4,
                                                             height: view.frame.height/4))
        //uploadProgressBar?.colors = [UIColor(rgba: 0xA6E39DFF), UIColor(rgba: 0xAEC1E3FF), UIColor(rgba: 0xAEC1E3FF), UIColor(rgba: 0xF3C0ABFF)]
        uploadProgressBar?.colors = [UIColor(rgba: 0x000000FF), UIColor(rgba: 0xFFFFFFFF)]
        
//        let labelWidth = CGFloat(80.0)
//        let textLabel = UILabel(frame: CGRect(x: (view.frame.width - labelWidth) / 2, y: (view.frame.height - labelWidth) / 4, width: labelWidth, height: 32.0))
//        textLabel.font = UIFont(name: "HelveticaNeue", size: 24)
//        textLabel.textAlignment = .center
//        textLabel.textColor = .green
//        textLabel.alpha = 0.3
        uploadProgressBar?.set(progress: progress, duration: 0.0)
//        uploadProgressBar?.addSubview(textLabel)
        
        uploadProgressBar?.progressChanged {
            (progress: Double, circularProgress: KYCircularProgress) in
            print("progress: \(progress)")
//            DispatchQueue.main.async(execute: {
//                textLabel.text = String.init(format: "%.2f", progress * 100.0) + "%"
//            })
        }
        
        self.view.insertSubview((uploadProgressBar)!, aboveSubview: self.takenImage)
    }
    
    //step been finished (upon message from upload manager)
    func runFinishHandler(success:Bool, message: String ){
     
        let dataManager = DataManager.sharedInstance
        DispatchQueue.main.async(execute: {
            self.nextButton.isEnabled = true
            self.prevItem.isEnabled = true
            self.uploadProgressBar?.isHidden = true
        })
        
        if(success)
        {
            //go to next step
            DispatchQueue.main.async(execute: {
                //ImageCache.default.store(self.takenImage.image!, forKey: self.image_key)
                dataManager.onboarding_info[self.step_key] = ["step_status":"PASSED"]
                self.goToNextStep()
            })
        }
        else
        {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        }

    }
    
}

