import Foundation

struct Transaction {
    
    let id: Int
    var summary: String
    var category: Category
    var sum: Decimal // Money should be handled as Decimal instead of Double to prevent rounding errors.
    var currency: Currency
    var paidDate: Date
       
    enum CodingKeys: String, CodingKey {
        case id, summary, category, sum, currency
        case paidDate = "paid" // Map the JSON key "paid" to "paidDate".
    }
    
    enum Currency: String, Codable, CaseIterable, CustomStringConvertible {
        case EUR, HUF, USD
        
        // Could be just raw value.
        var description: String {
            switch self {
            case .EUR:
                return "EUR"
            case .HUF:
                return "HUF"
            case .USD:
                return "USD"
            }
        }
    }
    
    enum Category: String, Codable, CaseIterable, CustomStringConvertible {
        case clothing, housing, travel, food, utilities, insurance, healthcare, financial, lifestyle, entertainment, miscellaneous
                
        var description: String {
            switch self {
            case .clothing:
                return NSLocalizedString("CATEGORY_CLOTHING", comment: "Name of an transaction category.")
            case .housing:
                return NSLocalizedString("CATEGORY_HOUSING", comment: "Name of an transaction category.")
            case .travel:
                return NSLocalizedString("CATEGORY_TRAVEL", comment: "Name of an transaction category.")
            case .food:
                return NSLocalizedString("CATEGORY_FOOD", comment: "Name of an transaction category.")
            case .utilities:
                return NSLocalizedString("CATEGORY_UTILITIES", comment: "Name of an transaction category.")
            case .insurance:
                return NSLocalizedString("CATEGORY_INSURANCE", comment: "Name of an transaction category.")
            case .financial:
                return NSLocalizedString("CATEGORY_FINANCIAL", comment: "Name of an transaction category.")
            case .lifestyle:
                return NSLocalizedString("CATEGORY_LIFESTYLE", comment: "Name of an transaction category.")
            case .entertainment:
                return NSLocalizedString("CATEGORY_ENTERTAINMENT", comment: "Name of an transaction category.")
            case .miscellaneous:
                return NSLocalizedString("CATEGORY_MISC", comment: "Name of an transaction category.")
            case .healthcare:
                return NSLocalizedString("CATEGORY_HEALTHCARE", comment: "Name of an transaction category.")
            }
        }
        
        var decorationColor: RGBAColor {
            switch self {
            case .clothing:
                return RGBAColor(redByte: 204, greenByte: 0, blueByte: 0, alphaByte: 255)
            case .housing:
                return RGBAColor(redByte: 0, greenByte: 255, blueByte: 0, alphaByte: 255)
            case .travel:
                return RGBAColor(redByte: 255, greenByte: 255, blueByte: 51, alphaByte: 255)
            case .food:
                return RGBAColor(redByte: 255, greenByte: 0, blueByte: 0, alphaByte: 255)
            case .utilities:
                return RGBAColor(redByte: 255, greenByte: 51, blueByte: 255, alphaByte: 255)
            case .insurance:
                return RGBAColor(redByte: 0, greenByte: 204, blueByte: 102, alphaByte: 255)
            case .financial:
                return RGBAColor(redByte: 0, greenByte: 0, blueByte: 204, alphaByte: 255)
            case .lifestyle:
                return RGBAColor(redByte: 51, greenByte: 0, blueByte: 102, alphaByte: 255)
            case .entertainment:
                return RGBAColor(redByte: 102, greenByte: 0, blueByte: 102, alphaByte: 255)
            case .miscellaneous:
                return RGBAColor(redByte: 96, greenByte: 96, blueByte: 96, alphaByte: 255)
            default:
                return RGBAColor(redByte: 96, greenByte: 96, blueByte: 96, alphaByte: 255)
            }
        }
        
        var decorationImageName: String {
            switch self {
            case .clothing:
                return "icon_clothing"
            case .housing:
                return "icon_housing"
            case .travel:
                return "icon_travel"
            case .food:
                return "icon_food"
            case .utilities:
                return "icon_utilities"
            case .insurance:
                return "icon_insurance"
            case .financial:
                return "icon_financial"
            case .lifestyle:
                return "icon_lifestyle"
            case .entertainment:
                return "icon_entertainment"
            case .miscellaneous:
                return "icon_miscellaneous"
            case .healthcare:
                return "icon_healthcare"
            }
        }
    }
}

// MARK: Codable

extension Transaction: Codable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Transaction.CodingKeys.self)
        
        self.summary = try container.decode(String.self, forKey: .summary)
        self.category = try container.decode(Category.self, forKey: .category)
        self.sum = try container.decode(Decimal.self, forKey: .sum)
        self.currency = try container.decode(Currency.self, forKey: .currency)
        self.paidDate = try container.decode(Date.self, forKey: .paidDate)
        
        // Decode id, if it should come as a String.
        if let idString = try? container.decode(String.self, forKey: .id), let id = Int(idString) {
            self.id = id
        }
        else {
            self.id = try container.decode(Int.self, forKey: .id)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Transaction.CodingKeys.self)
        
        try container.encode(self.summary, forKey: .summary)
        try container.encode(self.category, forKey: .category)
        try container.encode(self.sum, forKey: .sum)
        try container.encode(self.currency, forKey: .currency)
        try container.encode(self.paidDate, forKey: .paidDate)
        try container.encode(self.id, forKey: .id)
    }
}
