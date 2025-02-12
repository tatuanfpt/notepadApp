//
//  CGColor+Extension.swift
//  notepadApp
//
//  Created by TuanTa on 12/2/25.
//


// CGColor+Extensions.swift
import UIKit

extension CGColor {
    func toString() -> String {
        let color = UIColor(cgColor: self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return "\(red),\(green),\(blue),\(alpha)"
    }
    
    static func fromString(_ string: String) -> CGColor {
        let components = string.components(separatedBy: ",").compactMap { CGFloat(Double($0)!) }
        let color = UIColor(red: components[0], green: components[1], blue: components[2], alpha: components[3])
        return color.cgColor
    }
}

// UIColor+Random.swift
import UIKit

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }
}
