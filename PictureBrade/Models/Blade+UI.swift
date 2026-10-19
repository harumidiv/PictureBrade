//
//  Blade+UI.swift
//  PictureBrade
//

import SwiftUI
import UIKit

extension RGBColor {
    var color: Color { Color(red: red, green: green, blue: blue) }
    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: 1) }
}
