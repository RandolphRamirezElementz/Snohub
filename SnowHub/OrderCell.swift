//
//  OrderCell.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/7/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class OrderCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
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
    
    
}
