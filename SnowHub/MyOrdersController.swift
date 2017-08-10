//
//  MyOrdersController.swift
//  SnowHub
//
//  Created by Liubov Perova on 12/15/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class MyOrdersController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var ordersTable: UITableView!
    @IBOutlet weak var switchTab : UISegmentedControl!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var headrView: UIView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    
    var dataManager = DataManager.sharedInstance
    var currentOrder: Dictionary? = Dictionary<String, Any?>()
    var currentOrders:[Dictionary<String, Any?>] = [Dictionary<String, Any?>]()
    var finishedOrders:[Dictionary<String, Any?>] = [Dictionary<String, Any?>]()
    var scheduledOrders:[Dictionary<String, Any?>] = [Dictionary<String, Any?>]()
    var currentTable: [Dictionary<String, Any?>] = [Dictionary<String, Any?>]()
    
    var colorGrayBack =  UIColor.init(red: 250.0/255.0, green: 251.0/255.0, blue: 252.0/255.0, alpha: 1.0)
    var colorBlue = UIColor.init(red: 0/255.0, green: 94.0/255.0, blue: 173.0/255.0, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ordersTable.dataSource = self
        ordersTable.delegate = self
        ordersTable.separatorColor = UIColor.clear;
    
        headrView.layer.masksToBounds = false;
        headrView.layer.shadowOffset = CGSize(width: 0, height: 8);
        headrView.layer.shadowRadius = 5;
        headrView.layer.shadowOpacity = 0.3;

        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
        self.navigationBar.isTranslucent = true
        
        headerLabel.text = (dataManager.user.isDriver ? "My Jobs" : "My Orders")
        
        
        dataManager.getOwnOrders(is_driver: (self.dataManager.user.isDriver ? "true" : "false"), completionCallback: { (allOrders) in
            print("All orders count: \(allOrders.count)")
            
            if(allOrders.count > 0)
            {
              for(_, order)in allOrders.enumerated()
              {
                if(order["status"] as? Int == 3 || order["status"] as? Int == 4)
                {
                  self.finishedOrders.append(order)
                }
                else
                {
                  self.currentOrders.append(order)
                }
              }
               self.currentOrders.reverse()
               self.finishedOrders.reverse()
               DispatchQueue.main.async(execute: {
                    self.switchTab.selectedSegmentIndex = 0
                    self.currentTable =  self.currentOrders
                    print("reload data table")
                    self.ordersTable.reloadData()
               })
            }
        })
        
        
    }

    
    
    func selectDriverInterface()
    {
      if(dataManager.user.isDriver)
      {
        self.view.backgroundColor = UIColor.white
        self.headrView.backgroundColor = colorGrayBack
        self.navigationBar.backgroundColor = colorGrayBack
        self.switchTab.backgroundColor = colorGrayBack
        self.switchTab.tintColor = colorBlue
        self.headerLabel.textColor = UIColor.init(red: 68.0/255.0, green: 68.0/255.0, blue: 69.0/255.0, alpha: 1.0)
        self.backButton.tintColor = UIColor.init(red: 68.0/255.0, green: 68.0/255.0, blue: 69.0/255.0, alpha: 1.0)
      }
    }
    
    override func viewDidLayoutSubviews() {
        selectDriverInterface()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //table delegates
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return currentTable.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 84
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellOrder", for: indexPath as IndexPath) as! MyOrdersCell
        
        let index = indexPath.row
        
        if(index <= (currentTable.count) )
        {
            let cellElement = currentTable[index]
            cell.ordersArrayIndex = index
            cell.cellOrder = cellElement
            cell.addressLabel.text = cellElement["address"] as? String
            
            if(cellElement["status"] as! Int == Status.FINISHED.rawValue)
            {
                if let timestring = cellElement["created"] as? String
                {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    
                    if let datePublished = dateFormatter.date(from: timestring){
                        dateFormatter.dateFormat = "dd/MM/yy"
                        cell.doneLabel.text = "Finished " + dateFormatter.string(from: datePublished)
                    }
                }
            }
            else
            {
               cell.doneLabel.text = "In progress"
                if(cellElement["status"] as! Int == Status.SCHEDULED.rawValue){
                  cell.doneLabel.text = "SCHEDULED"
                }
                else if(cellElement["status"] as! Int == Status.CANCELLED.rawValue){
                    cell.doneLabel.text = "CANCELLED"
                }
                else if(cellElement["status"] as! Int == Status.NEW.rawValue){
                    cell.doneLabel.text = "New"
                }
                else if(cellElement["status"] as! Int == Status.ACCEPTED.rawValue){
                    cell.doneLabel.text = "Accepted"
                }
                
            }
            
            cell.backgroundColor = UIColor.clear
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.makeBorder()

        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cell:MyOrdersCell = tableView.cellForRow(at: indexPath) as! MyOrdersCell
        
        currentOrder = cell.cellOrder
        if let current_id = currentOrder?["id"] as? Int
        {
            if dataManager.user.isDriver || ( !dataManager.user.isDriver && current_id != dataManager.order.id )
            {
             self.performSegue(withIdentifier: "goToMyOrderDetails", sender: self)
            }
            else if current_id == dataManager.order.id && !dataManager.user.isDriver
            {
              self.performSegue(withIdentifier: "goToMyAcceptedOrder", sender: self)
            }
        }
    }
    
    
    @IBAction func indexChanged()
    {
        print("Reloading tab \(switchTab.selectedSegmentIndex)")
        switch switchTab.selectedSegmentIndex
        {
        case 0:
            self.currentTable =  self.currentOrders
            self.ordersTable.reloadData()
        break
        case 1:
            self.currentTable =  self.finishedOrders
            self.ordersTable.reloadData()
        break
        default:
            break
        }
    }

    @IBAction func goBackToMap()
    {
        if(dataManager.user.isDriver)
        {
            self.performSegue(withIdentifier: "returnFromMenuToDriverMap", sender: self)
        }
        else{
            self.performSegue(withIdentifier: "returnFromMenuToUserMap", sender: self)
        }
    }

   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToMyOrderDetails" {
            print("Sending order details: \(String(describing: currentOrder))")
            if let destination = segue.destination as? MyOrderDetailsController {
                destination.currentOrder = currentOrder
            }
        }
        
    }
    
}
