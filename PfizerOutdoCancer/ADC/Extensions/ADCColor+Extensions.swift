import SwiftUI

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
    
    static var adcDarkBlue: Color {
        Color(hex: 0x0000c9)
    }
    static var adcLightBlue: Color {
        Color(hex: 0x4178C6)
    }
    static var adcYellow: Color {
        Color(hex: 0xB28E34)
    }
    static var adcWhite: Color {
        Color(hex: 0xFFFFFF)
    }
    
    static var adcDarkBlueEmissive: Color {
        Color(hex: 0xACA8FF)
    }
    static var adcLightBlueEmissive: Color {
        Color(hex: 0xA8CCFF)
    }
    static var adcYellowEmissive: Color {
        Color(hex: 0xFFE6A9)
    }
    static var adcWhiteEmissive: Color {
        Color(hex: 0xFFFFFF)
    }
    
    static var adc: [Color] {
        return [.adcDarkBlue, .adcLightBlue, .adcYellow, .adcWhite]
    }
    
    static var adcEmissive: [Color] {
        return [.adcDarkBlueEmissive, .adcLightBlueEmissive, .adcYellowEmissive, .adcWhiteEmissive]
    }
    
    var toUIColor: UIColor {
        return UIColor(self)
    }
}

extension UIColor {
    convenience init(hex: Int, opacity: Double = 1.0) {
        let red = Double((hex & 0xff0000) >> 16) / 255.0
        let green = Double((hex & 0xff00) >> 8) / 255.0
        let blue = Double((hex & 0xff) >> 0) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: opacity)
    }
    
    static var adcDarkBlue: UIColor {
        UIColor(hex: 0x0000c9)
    }
    static var adcLightBlue: UIColor {
        UIColor(hex: 0x4178C6)
    }
    static var adcYellow: UIColor {
        UIColor(hex: 0xB28E34)
    }
    static var adcWhite: UIColor {
        UIColor(hex: 0xFFFFFF)
    }
    
    static var adcDarkBlueEmissive: UIColor {
        UIColor(hex: 0xACA8FF)
    }
    static var adcLightBlueEmissive: UIColor {
        UIColor(hex: 0xA8CCFF)
    }
    static var adcYellowEmissive: UIColor {
        UIColor(hex: 0xFFE6A9)
    }
    static var adcWhiteEmissive: UIColor {
        UIColor(hex: 0xFFFFFF)
    }
    
    
    static var adc: [UIColor] {
        return [.adcDarkBlue, .adcLightBlue, .adcYellow, .adcWhite]
    }
    
    static var adcEmissive: [UIColor] {
        return [.adcDarkBlueEmissive, .adcLightBlueEmissive, .adcYellowEmissive, .adcWhiteEmissive]
    }
    
    var hex: Int {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb = Int(
            (Int(red * 255) << 16) |
            (Int(green * 255) << 8) |
            Int(blue * 255)
        )
        
        return rgb
    }
}
