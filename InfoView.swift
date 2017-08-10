//
//  InfoView.swift
//  SnowHub
//
//  Created by Liubov Perova on 10/27/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

class InfoView: UIView {

    
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView()
    {
        layer.borderWidth = 0.0
        layer.cornerRadius = 7.0
        clipsToBounds = true
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor;
        layer.shadowOffset = CGSize(width:5.0, height:5.0);
        layer.shadowOpacity = 0.5;
        layer.shadowRadius = 10.0;
        
        //add view for clipping mask
        let borderView = UIView()
        borderView.frame = bounds
        borderView.clipsToBounds = true
        borderView.layer.cornerRadius = 7
        borderView.layer.borderColor = UIColor.black.cgColor
        borderView.layer.borderWidth = 0.0
        borderView.isUserInteractionEnabled = false
        borderView.layer.masksToBounds = true
        
        addSubview(borderView)

    }

}
