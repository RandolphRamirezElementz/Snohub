//
//  GradientView.swift
//  SnowHub
//
//  Created by Liubov Perova on 2/2/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit

class GradientView: UIView {

    let gradient:CAGradientLayer = CAGradientLayer()
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
        
    }
    
    public func setupView()
    {
        let startColor =  UIColor(red:(0.0/255.0), green:(90.0/255.0), blue:(165.0/255.0), alpha:0.7).cgColor
        let middleColor =  UIColor(red:(52.0/255.0), green:(123.0/255.0), blue:(182.0/255.0), alpha:0.3).cgColor
        let endColor =  UIColor(red:(52.0/255.0), green:(122.0/255.0), blue:(182.0/255.0), alpha:0.03).cgColor

        gradient.frame = self.bounds;
        gradient.startPoint = CGPoint.zero
        gradient.endPoint = CGPoint.init(x: 1, y: 1) ;
        gradient.colors = [startColor, middleColor, endColor];
        layer.addSublayer(gradient)
        
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = self.bounds;
        print("Layer bounds changed: \(gradient.frame)")
        
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        print("Passing all touches to the next view (if any), in the view stack.")
        return false
    }

   
    
    
}
