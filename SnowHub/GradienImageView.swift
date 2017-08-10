//
//  GradienImageView.swift
//  SnowHub
//
//  Created by Liubov Perova on 5/4/17.
//  Copyright © 2017 Liubov Perova. All rights reserved.
//

import UIKit

class GradienImageView: UIImageView {

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
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    public func setupView()
    {
        let startColor = UIColor(red:(0.0), green:(0.0), blue:(0.0), alpha:0.5).cgColor
        //let middleColor =  UIColor(red:(0.0), green:(0.0), blue:(0.0), alpha:0.3).cgColor
        let endColor = UIColor(red:(0.0), green:(0.0), blue:(0.0), alpha:0.0).cgColor
        
        gradient.frame = self.bounds;
        gradient.startPoint = CGPoint.zero
        gradient.endPoint = CGPoint.init(x: 0, y: 0.5) ;
        gradient.colors = [endColor, startColor];
        layer.addSublayer(gradient)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.clipsToBounds = true
        let bounds = CGRect(x: self.bounds.origin.x, y: self.bounds.origin.y + self.bounds.height - 80.0, width: self.bounds.width, height: 80.0)
        gradient.frame = bounds;
        gradient.masksToBounds = true
        print("Layer bounds changed: \(gradient.frame)")
        
    }
    
//    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        print("Passing all touches to the next view (if any), in the view stack.")
//        return false
//    }

}
