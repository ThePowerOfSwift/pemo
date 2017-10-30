//
//  UICustom.swift
//  PEMO
//
//  Created by Jaeseong on 2017. 10. 23..
//  Copyright © 2017년 Jaeseong. All rights reserved.
//

import UIKit


extension UITextField {
    func setBottomBorder() {
        self.borderStyle = .none
        self.layer.backgroundColor = UIColor.white.cgColor
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
}

extension UIView {
    // 메인화면 하단 View Top Border
    func addTopBorderWithColor(color: UIColor, width: CGFloat) {
        let border = CALayer()
        border.backgroundColor = color.cgColor
        border.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: width)
        self.layer.addSublayer(border)
    }
}
extension UIColor {
    @nonobjc class var piWhite: UIColor {
        return UIColor(white: 237.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var piWarmGrey: UIColor {
        return UIColor(white: 155.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var piViolet: UIColor {
        return UIColor(red: 189.0 / 255.0, green: 16.0 / 255.0, blue: 224.0 / 255.0, alpha: 1.0)
    }
    @nonobjc class var piPaleGrey: UIColor {
        return UIColor(red: 239.0 / 255.0, green: 239.0 / 255.0, blue: 244.0 / 255.0, alpha: 1.0)
    }
}
