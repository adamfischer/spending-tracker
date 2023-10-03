import Foundation
import RxCocoa
import UIKit
import RxSwift

// MARK: Decimal

extension Decimal {
    func formattedCurrencyString(currency:Transaction.Currency) -> String {
        let formatter = NumberFormatter()
        formatter.locale = NSLocale.current
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.usesGroupingSeparator = true
        
        let formattedNumber = formatter.string(from: NSDecimalNumber(decimal: self)) ?? "0"
        
        switch currency {
        case .HUF:
            return "\(formattedNumber) Ft"
        case .EUR:
            return "\(formattedNumber) €"
        case .USD:
            return "$\(formattedNumber)"
        }
    }
}

// MARK: Color

struct RGBAColor {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}

extension RGBAColor {
    init(gray: Double) {
        self.init(red: gray / 255.0, green: gray / 255.0, blue: gray / 255.0, alpha: 1.0)
    }
    
    init(redByte: UInt8, greenByte: UInt8, blueByte: UInt8, alphaByte: UInt8) {
        self.init(red: Double(redByte) / 255.0, green: Double(greenByte) / 255.0, blue: Double(blueByte) / 255.0, alpha: Double(alphaByte) / 255.0)
    }
}

extension UIColor {
    convenience init(rgbaColor rgba: RGBAColor) {
        self.init(red: rgba.red, green: rgba.green, blue: rgba.blue, alpha: rgba.alpha)
    }
}

// MARK: Persist Data to Documents Directory.

func documentDirectory() -> String {
    let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                .userDomainMask,
                                                                true)
    return documentDirectory[0]
}


func append(toPath path: String, withPathComponent pathComponent: String) -> String? {
    if var pathURL = URL(string: path) {
        pathURL.appendPathComponent(pathComponent)
        
        return pathURL.absoluteString
    }
    
    return nil
}

func readFromDocuments(fileName: String) throws -> Data  {
    let filePath = append(toPath: documentDirectory(),withPathComponent: fileName)!

    return try Data(contentsOf: URL(fileURLWithPath: filePath))
}

func saveToDocuments(data: Data, fileName: String) throws {
    let filePath = append(toPath: documentDirectory(),withPathComponent: fileName)!
    
    return try data.write(to: URL(fileURLWithPath: filePath),options: .atomic)
}

func removeFromDocuments(fileName: String) throws {
    let filePath = append(toPath: documentDirectory(),withPathComponent: fileName)!

    return try FileManager.default.removeItem(atPath: filePath)
}
