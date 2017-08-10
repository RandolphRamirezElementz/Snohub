//
//  CheckoutViewController.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/24/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit
import Stripe

class CheckoutViewController: UIViewController, STPPaymentContextDelegate {
    
    // 1) To get started with, first head to https://dashboard.stripe.com/account/apikeys
    // and copy your "Test Publishable Key" (it looks like pk_test_abcdef) into the line below.
    let stripePublishableKey = DataManager.sharedInstance.stripePublicKey//"pk_live_5nrDeDcgqmho6OpicmVgWJ4h" //testing - "pk_test_cvdhKps2UkdxmuMTYxsWNguH"
    
    // 2) API backend
    let backendBaseURL: String? =  DataManager.sharedInstance.urlBase
    
    // 3) Optionally, to enable Apple Pay, follow the instructions at https://stripe.com/docs/mobile/apple-pay
    // to create an Apple Merchant ID. Replace nil on the line below with it (it looks like merchant.com.yourappname).
    let appleMerchantID: String? = "merchant.snohub.app"
    
    // These values will be shown to the user when they purchase with Apple Pay.
    let companyName = "SnoHub"
    let paymentCurrency = "usd"
    let dataManager:DataManager = DataManager.sharedInstance
    
    let paymentContext: STPPaymentContext
    
    let theme: STPTheme
    let paymentRow: CheckoutRowView
    let shippingRow: CheckoutRowView
    let totalRow: CheckoutRowView
    let buyButton: BuyButton
    let config = STPPaymentConfiguration.shared()
    let rowHeight: CGFloat = 44
    let productImage = UILabel()
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    let numberFormatter: NumberFormatter
    let shippingString: String
    var product = ""
    var paymentInProgress: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                if self.paymentInProgress {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator.alpha = 1
                    self.buyButton.alpha = 0
                }
                else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.alpha = 0
                    self.buyButton.alpha = 1
                }
            }, completion: nil)
        }
    }
    
    init(product: String, price: Double, settings: Settings) {
        self.product = product
        self.productImage.text = product
        self.theme = settings.theme
        StripeAPIClient.sharedClient.baseURLString = self.backendBaseURL
        
        // This code is included here for the sake of readability, but in your application you should set up your configuration and theme earlier, preferably in your App Delegate.
        config.publishableKey = self.stripePublishableKey
        config.appleMerchantIdentifier = self.appleMerchantID
        config.companyName = self.companyName
        config.requiredBillingAddressFields = settings.requiredBillingAddressFields
        config.requiredShippingAddressFields = settings.requiredShippingAddressFields
        config.shippingType = settings.shippingType
        config.additionalPaymentMethods = .applePay//settings.additionalPaymentMethods
        config.smsAutofillDisabled = !settings.smsAutofillEnabled
        
        let paymentContext = STPPaymentContext(apiAdapter: StripeAPIClient.sharedClient,
                                               configuration: config,
                                               theme: settings.theme)
        let userInformation = STPUserInformation()
        paymentContext.prefilledInformation = userInformation
        paymentContext.paymentAmount = Int(Double(price * 100.0))
        paymentContext.paymentCurrency = self.paymentCurrency
        self.paymentContext = paymentContext
        
        self.paymentRow = CheckoutRowView(title: "Payment", detail: "Select Payment",
                                          theme: settings.theme)
        var shippingString = "Contact"
        if config.requiredShippingAddressFields.contains(.postalAddress) {
            shippingString = config.shippingType == .shipping ? "Shipping" : "Delivery"
        }
        self.shippingString = shippingString
        self.shippingRow = CheckoutRowView(title: self.shippingString,
                                           detail: "Enter \(self.shippingString) Info",
            theme: settings.theme)
        self.totalRow = CheckoutRowView(title: "Total", detail: "", tappable: false,
                                        theme: settings.theme)
        self.buyButton = BuyButton(enabled: true, theme: settings.theme)
        var localeComponents: [String: String] = [
            NSLocale.Key.currencyCode.rawValue: self.paymentCurrency,
            ]
        localeComponents[NSLocale.Key.languageCode.rawValue] = NSLocale.preferredLanguages.first
        let localeID = NSLocale.localeIdentifier(fromComponents: localeComponents)
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: localeID)
        numberFormatter.numberStyle = .currency
        numberFormatter.usesGroupingSeparator = true
        self.numberFormatter = numberFormatter
        super.init(nibName: nil, bundle: nil)
        self.paymentContext.delegate = self
        paymentContext.hostViewController = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = self.theme.primaryBackgroundColor
        var red: CGFloat = 0
        self.theme.primaryBackgroundColor.getRed(&red, green: nil, blue: nil, alpha: nil)
        self.activityIndicator.activityIndicatorViewStyle = red < 0.5 ? .white : .gray
        self.navigationItem.title = "Order Checkout"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismiss as (Void) -> Void))

        
        //label with name of service
        self.productImage.font = UIFont.systemFont(ofSize: 17)
      
        
        
        self.view.addSubview(self.totalRow)
        self.view.addSubview(self.paymentRow)
        //self.view.addSubview(self.shippingRow)
        self.view.addSubview(self.productImage)
        self.view.addSubview(self.buyButton)
        self.view.addSubview(self.activityIndicator)
        self.activityIndicator.alpha = 0
        self.buyButton.addTarget(self, action: #selector(didTapBuy), for: .touchUpInside)
        self.totalRow.detail = self.numberFormatter.string(from: NSNumber(value: Float(self.dataManager.order.price)))!
        self.paymentRow.onTap = { [weak self] _ in
            
            
            //self?.paymentContext.configuration.additionalPaymentMethods.insert(STPPaymentMethodType.applePay)
            //self?.paymentContext.presentPaymentMethodsViewController()//.pushPaymentMethodsViewController()
            
            let paymentMethodsViewController = STPPaymentMethodsViewController.init(paymentContext: (self?.paymentContext)!)
            print("paymentMethodsViewController created. \(String(describing: self?.paymentContext.paymentMethods))")
            print("apple pay enabled: \(Stripe.deviceSupportsApplePay)")
            let navController = UINavigationController(rootViewController: paymentMethodsViewController)
            self?.present(navController, animated: true, completion: nil)

            
        }
        self.shippingRow.onTap = { [weak self] _ in
            self?.paymentContext.pushShippingViewController()
        }
        
        
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        UINavigationBar.appearance().isTranslucent = true

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = self.view.bounds.width
        self.productImage.sizeToFit()
        self.productImage.numberOfLines = 2
        self.productImage.frame = CGRect(x: 4, y: 15, width: (self.view.bounds.width - 8), height: 60)
        self.productImage.textColor = UIColor.white
        self.productImage.textAlignment = .center
        self.productImage.lineBreakMode = NSLineBreakMode.byWordWrapping
        self.productImage.center = CGPoint(x: width/2.0,
                                           y: self.productImage.bounds.height + rowHeight)
        self.paymentRow.frame = CGRect(x: 0, y: self.productImage.frame.maxY + rowHeight,
                                       width: width, height: rowHeight)
        self.shippingRow.frame = CGRect(x: 0, y: self.paymentRow.frame.maxY,
                                        width: width, height: rowHeight)
        self.totalRow.frame = CGRect(x: 0, y: self.shippingRow.frame.maxY,
                                     width: width, height: rowHeight)
        self.buyButton.frame = CGRect(x: 0, y: 0, width: 250, height: 44)
        self.buyButton.center = CGPoint(x: width/2.0, y: self.totalRow.frame.maxY + rowHeight*1.5)
        self.activityIndicator.center = self.buyButton.center
    }
    
    func didTapBuy() {
        //this is the right way to pay
        self.paymentInProgress = true
        self.paymentContext.requestPayment()
    
        //and this is way to skip payment
        //self.goToOrder(status: STPPaymentStatus.success)
        
    }
    
    // MARK: STPPaymentContextDelegate
    
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPErrorBlock) {
        StripeAPIClient.sharedClient.completeCharge(paymentResult, amount: self.paymentContext.paymentAmount,
                                                completion: completion)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        self.paymentInProgress = false
        let title: String
        let message: String
        switch status {
        case .error:
            title = "Error"
            message = error?.localizedDescription ?? ""
        case .success:
            title = "Success"
            message = "You bought a \(self.product)!"
        case .userCancellation:
            return
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
            self.goToOrder(status: status)
        })
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        self.paymentRow.loading = paymentContext.loading
        if let paymentMethod = paymentContext.selectedPaymentMethod {
            self.paymentRow.detail = paymentMethod.label
        }
        else {
            self.paymentRow.detail = "Select Payment"
        }
        if let shippingMethod = paymentContext.selectedShippingMethod {
            self.shippingRow.detail = shippingMethod.label
        }
        else {
            self.shippingRow.detail = "Enter \(self.shippingString) Info"
        }
        self.totalRow.detail = self.numberFormatter.string(from: NSNumber(value: Float(self.paymentContext.paymentAmount)/100))!
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        let alertController = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            // Need to assign to _ because optional binding loses @discardableResult value
            // https://bugs.swift.org/browse/SR-1681
            _ = self.navigationController?.popViewController(animated: true)
        })
        let retry = UIAlertAction(title: "Retry", style: .default, handler: { action in
            self.paymentContext.retryLoading()
        })
        alertController.addAction(cancel)
        alertController.addAction(retry)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func paymentContext(_ paymentContext: STPPaymentContext, didUpdateShippingAddress address: STPAddress, completion: @escaping STPShippingMethodsCompletionBlock) {
     
    }
    
    
    //=================place order and go to Order waiting status
    func goToOrder(status: STPPaymentStatus){
        
        if(status != .success)
        {
          return
        }
        
        
        DispatchQueue.main.async(execute: {
                       
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let orderPlacedVC:OrderPlacedController = storyboard.instantiateViewController(withIdentifier: "OrderPlacedController") as! OrderPlacedController
            self.present(orderPlacedVC, animated: true, completion: nil)
        })
        
    }
    //=================
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

