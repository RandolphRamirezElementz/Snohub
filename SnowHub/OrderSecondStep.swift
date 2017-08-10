//
//  OrderSecondStep.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/2/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class OrderSecondStep: UIViewController, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, DropdownViewDelegate {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var nextItem: UIBarButtonItem!
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet weak var firstOption: CheckBoxButton!
    @IBOutlet weak var secondOption: CheckBoxButton!
    @IBOutlet weak var thirdOption: CheckBoxButton!
    @IBOutlet weak var fourthOption: CheckBoxButton!
    @IBOutlet weak var sixthOption: CheckBoxButton!
    @IBOutlet weak var seventhOption: CheckBoxButton!
    @IBOutlet weak var fifthOption: CheckBoxButton!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var promoCode: UITextField!
   
    @IBOutlet weak var issuesText: UITextView!
    //@IBOutlet weak var issuesTextField: UITextField!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var navigationBar: UINavigationBar!
    
    //driveway
    @IBOutlet var driveWayLength:BorderedViewDropdown!
    @IBOutlet var drivewayViewHieight: NSLayoutConstraint!
    
    //walkways number
    //@IBOutlet var walkWaysNumber:BorderedViewDropdown!
    
    //de-icing
    @IBOutlet weak var deIcingSwitch: CheckBoxButton!
    
    
    //labels for making them grayish
    @IBOutlet var firstLabel: UILabel!
    @IBOutlet var secondLabel: UILabel!
    @IBOutlet var thirdLabel: UILabel!
    @IBOutlet var fourthLabel: UILabel!
    @IBOutlet var deIcingLabel : UILabel!
    @IBOutlet var fifthLabel : UILabel!
    @IBOutlet var sixthLabel : UILabel!
    @IBOutlet var seventhLabel : UILabel!
    
    
    //services requests
    @IBOutlet weak var serviceNowOption: CheckBoxButton!
    @IBOutlet weak var serviceNextOption: CheckBoxButton!
    @IBOutlet weak var serviceEveryOption: CheckBoxButton!
    @IBOutlet var serviceNowLabel: UILabel!
    @IBOutlet var serviceNextLabel: UILabel!
    @IBOutlet var serviceEveryLabel : UILabel!
    
    
    //details view height:
     @IBOutlet var detailsViewHieight: NSLayoutConstraint!
    
    @IBOutlet weak var myPicker: UIPickerView!
    var currentDropdown: BorderedViewDropdown? = nil
    var pickData: [String] = []
    let grayishColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    //let grayishColor = UIColor.init(red: 127.0/255.0, green: 169.0/255.0, blue: 203.0/255.0, alpha: 1.0)
    var isPromoEntering = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.hideKeyboardWhenTappedAround()
    
        //setting issues text
        issuesText.layer.borderWidth = 1.0
        issuesText.layer.cornerRadius = 7.0
        issuesText.clipsToBounds = true
        issuesText.layer.borderColor = UIColor.init(red: 146.0/255.0, green: 187.0/255.0, blue: 213.0/255.0, alpha: 1.0).cgColor
        issuesText.delegate = self
        
        topView.layer.masksToBounds = false;
        topView.layer.shadowOffset = CGSize(width: 0, height: 8);
        topView.layer.shadowRadius = 5;
        topView.layer.shadowOpacity = 0.3;
        
        //issuesTextField.delegate = self
        detailsViewHieight.constant = 330
        promoCode.layer.borderColor = UIColor.white.cgColor
        promoCode.layer.borderWidth = 1.0
        promoCode.layer.cornerRadius = 3.0
        
        //deIcingSwitch.setChecked()
        let dataManager = DataManager.sharedInstance
        
        driveWayLength.pickList = dataManager.roadLengths
        driveWayLength.valueLabel.text = driveWayLength.pickList[0]
        
        //walkWaysNumber.pickList = ["None", "1", "2", "3", "4", "5"]
        //walkWaysNumber.valueLabel.text = walkWaysNumber.pickList[0]
        
        dataManager.order.walkways_number = 0
        
        if(dataManager.order.driveWayLength < 6)
        {
           driveWayLength.valueLabel.text = driveWayLength.pickList[dataManager.order.driveWayLength]
           driveWayLength.setValue = dataManager.order.driveWayLength
        }
        
        if(dataManager.order.markersThere)
        {
            firstOption.setChecked()
            firstLabel.textColor = UIColor.white
        }
        
        if(dataManager.order.asphaltDriveway)
        {
            secondOption.setChecked()
            secondLabel.textColor = UIColor.white
        }
        
        if(dataManager.order.gravelDriveway)
        {
            thirdOption.setChecked()
            thirdLabel.textColor = UIColor.white
        }
        
        if(dataManager.order.otherIssues)
        {
            fourthOption.setChecked()
            fourthLabel.textColor = UIColor.white
            
            issuesText.isHidden = false
            issuesText.text = dataManager.order.issuesThere
            
        }
        
        if(dataManager.order.deicing == 1)
        {
            deIcingSwitch.setChecked()
            deIcingLabel.textColor =  UIColor.white
        }
        
        if(dataManager.order.clean_front_walkway)
        {
            fifthOption.setChecked()
            fifthLabel.textColor = UIColor.white
        }
        
        if(dataManager.order.clean_back_walkway)
        {
            sixthOption.setChecked()
            sixthLabel.textColor = UIColor.white
        }
        
        if(dataManager.order.clean_side_walkway)
        {
            seventhOption.setChecked()
            seventhLabel.textColor = UIColor.white
        }
        
        //set the "service now" checked by default
        serviceNowLabel.textColor = UIColor.white
        serviceNowOption.setChecked()
        dataManager.order.serviceNow = serviceNowOption.checked
        
        driveWayLength.parent = self
        //walkWaysNumber.parent = self
        myPicker.delegate = self
        myPicker.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidLayoutSubviews() {
        //setting up scroll view
        //let fullscreenRect = UIScreen.main.bounds
        //scrollView.contentSize = CGSize(width: fullscreenRect.width, height: 680)
        //scrollView.contentInset = UIEdgeInsetsMake(0, 0, 2, 0)
        //print("Scrollview content size: \(scrollView.contentSize)")
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func firstSwitch(){
        firstOption.switchButton()
        
        let dataManager:DataManager = DataManager.sharedInstance
        dataManager.order.markersThere = firstOption.checked
        
        firstLabel.textColor = firstOption.checked ? UIColor.white : grayishColor
    }

    @IBAction func secondSwitch(){
        secondOption.switchButton()
        
        let dataManager:DataManager = DataManager.sharedInstance
        dataManager.order.asphaltDriveway = secondOption.checked

        secondLabel.textColor = secondOption.checked ? UIColor.white : grayishColor
        
        if(secondOption.checked)
        {
        dataManager.order.gravelDriveway = false
        thirdOption.setUnchecked()
        thirdLabel.textColor = grayishColor
        }
    }

    @IBAction func thirdSwitch(){
        thirdOption.switchButton()
        
        let dataManager:DataManager = DataManager.sharedInstance
        dataManager.order.gravelDriveway = thirdOption.checked

        thirdLabel.textColor = thirdOption.checked ? UIColor.white : grayishColor
       
        if(thirdOption.checked)
        {
        dataManager.order.asphaltDriveway = false
        secondOption.setUnchecked()
        secondLabel.textColor = grayishColor
        }
    }
    

    @IBAction func fourthSwitch(){
        fourthOption.switchButton()
        if(fourthOption.checked)
        {
          issuesText.isHidden = false
          detailsViewHieight.constant = 430
        }
        else{
          issuesText.isHidden = true
          detailsViewHieight.constant = 330
        }
        
        let dataManager:DataManager = DataManager.sharedInstance
        dataManager.order.otherIssues = fourthOption.checked
        
        fourthLabel.textColor = fourthOption.checked ? UIColor.white : grayishColor
    }
    
    @IBAction func fifthSwitch(){
        fifthOption.switchButton()
        
        let dataManager:DataManager = DataManager.sharedInstance
        dataManager.order.clean_front_walkway = fifthOption.checked
        
        fifthLabel.textColor = fifthOption.checked ? UIColor.white : grayishColor
    }

    @IBAction func sixthSwitch(){
        sixthOption.switchButton()
        
        let dataManager:DataManager = DataManager.sharedInstance
        dataManager.order.clean_back_walkway = sixthOption.checked
        
        sixthLabel.textColor = sixthOption.checked ? UIColor.white : grayishColor
    }

    @IBAction func seventhSwitch(){
        seventhOption.switchButton()
        
        let dataManager:DataManager = DataManager.sharedInstance
        dataManager.order.clean_side_walkway = seventhOption.checked
        
        seventhLabel.textColor = seventhOption.checked ? UIColor.white : grayishColor
    }
    
   
    @IBAction func deIcingSwitchAction(){
       deIcingSwitch.switchButton()
       deIcingLabel.textColor =  deIcingSwitch.checked ? UIColor.white : grayishColor
    }
    

    @IBAction func serviceNowSwitch(){
        serviceNowOption.switchButton()
        
        let dataManager:DataManager = DataManager.sharedInstance
        dataManager.order.serviceNow = serviceNowOption.checked
        
        serviceNowLabel.textColor = serviceNowOption.checked ? UIColor.white : grayishColor
    }

    @IBAction func serviceNextSwitch(){
        serviceNextOption.switchButton()
        
        let dataManager:DataManager = DataManager.sharedInstance
        dataManager.order.serviceNext = serviceNextOption.checked
        
        serviceNextLabel.textColor = serviceNextOption.checked ? UIColor.white : grayishColor
        
        if(serviceEveryOption.checked)
        {
            dataManager.order.serviceEvery = false
            serviceEveryOption.setUnchecked()
            serviceEveryLabel.textColor = grayishColor
        }
    }
    
    @IBAction func serviceEverySwitch(){
        serviceEveryOption.switchButton()
        
        let dataManager:DataManager = DataManager.sharedInstance
        dataManager.order.serviceEvery = serviceEveryOption.checked
        
        serviceEveryLabel.textColor = serviceEveryOption.checked ? UIColor.white : grayishColor
        
        if(serviceNextOption.checked)
        {
            dataManager.order.serviceNext = false
            serviceNextOption.setUnchecked()
            serviceNextLabel.textColor = grayishColor
        }
        
    }

   
    func textViewShouldEndEditing(_: UITextView) -> Bool {
        print("SHOULD END EDITING")
        issuesText.resignFirstResponder()
        
        if(!isPromoEntering)
        {
            let dataManager:DataManager = DataManager.sharedInstance
            dataManager.order.issuesThere = issuesText.text
        }
        else
        {
          //isPromoEntering = false
        }
        
        return true
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if(!isPromoEntering)
        {
//            issuesTextField.isHidden = true
//            issuesTextField.resignFirstResponder()
//            issuesText.text = issuesTextField.text
            let dataManager:DataManager = DataManager.sharedInstance
            dataManager.order.issuesThere = issuesText.text
            
        }
        else{
             //isPromoEntering = false
             //promoCode.text = issuesTextField.text
        }
//        issuesTextField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

//        if textField != issuesTextField
//        {
//            return true
//        }
//        
//        if(isPromoEntering){
//            promoCode.text = issuesTextField.text
//        }
//        else
//        {
//            issuesText.text = issuesTextField.text
//        }
        
        return true
    }
    
    func textView(_ : UITextView, shouldChangeTextIn range:  NSRange, replacementText text: String) -> Bool {
        
        if (text == "\n") {
            issuesText.resignFirstResponder()
            return false
        }
        
//        if(isPromoEntering){
//           promoCode.text = issuesTextField.text
//        }
//        else
//        {
//           issuesText.text = issuesTextField.text
//        }
     return true
    }
    
    
    func keyboardWillShow(notification: NSNotification) {
        
        if(promoCode.isFirstResponder)
        {
          isPromoEntering = true
//          issuesTextField.text = promoCode.text
        }
//        else if issuesText.isFirstResponder
//        {
//          issuesTextField.text = issuesText.text
//        }
//        
//        issuesTextField.isHidden = false
//        issuesTextField.becomeFirstResponder()
        
        
        
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue
        {
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.bottomConstraint.constant = (keyboardFrame.size.height)
            })
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
//        issuesTextField.isHidden = true
//        issuesTextField.resignFirstResponder()
//        issuesText.text = issuesTextField.text
//        issuesText.resignFirstResponder()

         self.bottomConstraint.constant = 0
         if(isPromoEntering)
         {
            isPromoEntering = false
         }
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

    @IBAction func goNextStep(){
      
        let dataManager:DataManager = DataManager.sharedInstance
        
        dataManager.order.driveWayLength = self.driveWayLength.setValue
        //dataManager.order.walkways_number = self.walkWaysNumber.setValue
        dataManager.order.deicing = self.deIcingSwitch.checked ? 1 : 0
        dataManager.order.promo_code = self.promoCode.text ?? ""
        
        dataManager.order.walkways_number = (dataManager.order.clean_back_walkway ? 1:0) + (dataManager.order.clean_front_walkway ? 1:0) + (dataManager.order.clean_side_walkway ? 1:0)
        
        dataManager.getOrderPrice { (success, error) in
            if(success)
            {
                DispatchQueue.main.async(execute: {
                                        self.performSegue(withIdentifier: "goToFinishOrder", sender:self) //go to next stage
                                    })
            }
            else
            {
               print("could not calculate order price. No valid response from server")
               let alert = UIAlertController(title: "Error", message: error == "" ? "Could not get valid price for this order" : error, preferredStyle: UIAlertControllerStyle.alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                                    DispatchQueue.main.async(execute: {
                                        self.present(alert, animated: true, completion: nil)
                                    })
                
            }
        }
        
    }
    
}


// this piece of code to put anywhere we like
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
