//
//  DarkBorderdButton.swift
//  SnowHub
//
//  Created by Liubov Perova on 12/12/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class DarkBorderdButton: UIButton {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.borderWidth = 2.0
        layer.cornerRadius = 15.0
        layer.borderColor = UIColor.white.cgColor
        clipsToBounds = true
    }


}
