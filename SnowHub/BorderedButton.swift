//
//  BorderedButton.swift
//  SnowHub
//
//  Created by Liubov Perova on 10/24/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

public extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

class BorderedButton: UIButton {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.borderWidth = 0.0
        layer.cornerRadius = 24.0
        imageView?.layer.cornerRadius = 24.0
        clipsToBounds = true
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        setTitleColor(UIColor.init(red: 0.0/255.0, green: 80.0/255.0, blue: 148.0/255.0, alpha: 1.0), for: .normal)
        setTitleColor(UIColor.init(red: 0.0/255.0, green: 80.0/255.0, blue: 148.0/255.0, alpha: 0.8), for: .highlighted)
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor;
        layer.shadowOffset = CGSize(width:5.0, height:5.0);
        layer.shadowOpacity = 0.5;
        layer.shadowRadius = 10.0;
        
        //add view for clipping mask
        let borderView = UIView()
        borderView.frame = bounds
        borderView.clipsToBounds = true
        borderView.layer.cornerRadius = 24
        borderView.layer.borderColor = UIColor.black.cgColor
        borderView.layer.borderWidth = 0.0
        borderView.isUserInteractionEnabled = false
        borderView.layer.masksToBounds = true
        
        addSubview(borderView)
        
    }

}
