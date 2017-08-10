//
//  CheckBoxButton.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/2/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class CheckBoxButton: UIButton {

    var checked: Bool = false
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.borderWidth = 1.0
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = 4.0
        clipsToBounds = true
        frame = CGRect(x:frame.origin.x, y:frame.origin.y, width: 25, height:25)
    }

    func setChecked(){
        self.checked = true
        self.setImage(UIImage(named: "check_mark"), for: .normal)
        self.setImage(UIImage(named: "check_mark"), for: .highlighted)
    }
    
    func setUnchecked(){
        self.checked = false
        self.setImage(nil, for: .normal)
        self.setImage(nil, for: .highlighted)

    }
    
    func switchButton()
    {
        if(self.checked)
        {
            self.setUnchecked()
        }
        else
        {
            self.setChecked()
        }
    }
}
