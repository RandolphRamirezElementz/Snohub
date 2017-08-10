//
//  MyOrdersCell.swift
//  SnowHub
//
//  Created by Liubov Perova on 12/15/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class MyOrdersCell: UITableViewCell {

    @IBOutlet weak var doneLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var subView: UIView!
    @IBOutlet weak var doneState: UILabel!
    
    var ordersArrayIndex: Int = 0
    var cellOrder: Dictionary? = Dictionary<String, Any?>()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func makeBorder()
    {
      self.subView.layer.borderWidth = 1
      self.subView.layer.cornerRadius = 3
      self.subView.clipsToBounds = true
      self.subView.layer.borderColor = UIColor.init(red: 130.0/255.0, green: 172.0/255.0, blue: 204.0/255.0, alpha: 1.0).cgColor
        
      if(DataManager.sharedInstance.user.isDriver)
      {
         self.subView.layer.borderColor = UIColor.init(red: 0/255.0, green: 94.0/255.0, blue: 173.0/255.0, alpha: 1.0).cgColor
         self.doneLabel.textColor = UIColor.init(red: 68.0/255.0, green: 68.0/255.0, blue: 69.0/255.0, alpha: 1.0)
         self.addressLabel.textColor = UIColor.init(red: 54.0/255.0, green: 173.0/255.0, blue: 227.0/255.0, alpha: 1.0)
         self.doneState.textColor = UIColor.init(red: 68.0/255.0, green: 68.0/255.0, blue: 69.0/255.0, alpha: 1.0)
      }
        
    }

}
