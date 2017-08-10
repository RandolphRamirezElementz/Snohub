//
//  PricesViewController.swift
//  SnowHub
//
//  Created by Liubov Perova on 2/14/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit
import WebKit

class PricesViewController: UIViewController, WKNavigationDelegate, UIWebViewDelegate {
    
    @IBOutlet weak var prevItem: UIBarButtonItem!
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var pricesPage: UIWebView!
    @IBOutlet weak var loadingAction: UIActivityIndicatorView!

    var dataManager:DataManager = DataManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
    
        //load webpage to webview
        pricesPage.delegate = self
        let url = URL(string: dataManager.urlBase + "/orders/prices?session_id=\(dataManager.user.SID)")!
        pricesPage.loadRequest(URLRequest(url: url))
        loadingAction.startAnimating()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        loadingAction.stopAnimating()
        loadingAction.isHidden = true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction  func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }


}
