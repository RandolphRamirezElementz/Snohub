//
//  BorderedViewDropdown.swift
//  SnowHub
//
//  Created by Liubov Perova on 11/30/16.
//  Copyright © 2016 Liubov Perova. All rights reserved.
//

import UIKit

public protocol DropdownViewDelegate {
    
    var currentDropdown: BorderedViewDropdown? {get set}
    var pickData: [String] {get set}
    weak var myPicker: UIPickerView! {get set}
    
   
}



public class BorderedViewDropdown: UIView,  UIPickerViewDelegate{

    @IBOutlet weak var valueLabel: UILabel!
    
    var pickList:[String] = []
    var parent: DropdownViewDelegate!
    var setValue = 0;
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    
    private func setupView()
    {
        layer.borderWidth = 1.0
        layer.cornerRadius = 3.0
        clipsToBounds = true
        layer.borderColor = UIColor.white.cgColor
        layer.masksToBounds = true
        
         // 1. create a gesture recognizer (tap gesture)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(sender:)))
        
        // 2. add the gesture recognizer to a view
        self.addGestureRecognizer(tapGesture)
    }
    
    func setList(list:[String]){
      
    }
    
    func handleTap(sender:Any?){
        parent.myPicker.isHidden = false
        parent.currentDropdown = self
        parent.pickData = self.pickList
        parent.myPicker.reloadAllComponents()
    }

}
