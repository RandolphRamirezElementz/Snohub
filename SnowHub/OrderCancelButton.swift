//
//  OrderCancelButton.swift
//  SnowHub
//
//  Created by Liubov Perova on 2/13/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit

class OrderCancelButton: UIButton {

var cellOrder: Dictionary? = Dictionary<String, Any?>()
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.borderWidth = 1.0
        layer.cornerRadius = 15.0
        layer.borderColor = UIColor.white.cgColor
        clipsToBounds = true
    }


}
