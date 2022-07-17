import UIKit

struct Transaction: Decodable {
    
    let id: Int
    let summary: String
    let category: Category
    let sum: Decimal // Money should be handled as Decimal instead of Double to prevent rounding errors.
    let currency: String
    let paidDate: Date
       
    private enum CodingKeys: String, CodingKey {
        case id, summary, category, sum, currency
        case paidDate = "paid" // Map the JSON key "paid" to "paidDate".
    }
    
    enum Category: String, Decodable, CaseIterable {
        case clothing, housing, travel, food, utilities, insurance, healthcare, financial, lifestyle, entertainment, miscellaneous
        
        func localizedCategoryName() -> String {
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
            default:
                return NSLocalizedString("CATEGORY_UNKNOWN", comment: "Name of an transaction category.")
            }
        }
        
        func decorationColor() -> UIColor {
            switch self {
            case .clothing:
                return .magenta
            case .housing:
                return .brown
            case .travel:
                return .blue
            case .food:
                return .green
            case .utilities:
                return .gray
            case .insurance:
                return .yellow
            case .financial:
                return .green
            case .lifestyle:
                return .purple
            case .entertainment:
                return .red
            case .miscellaneous:
                return .black
            default:
                return .lightGray
            }
        }
        
        func decorationImage() -> UIImage? {
            var imageName = ""

            switch self {
            case .clothing:
                imageName = "icon_clothing"
            case .housing:
                imageName = "icon_housing"
            case .travel:
                imageName = "icon_travel"
            case .food:
                imageName = "icon_food"
            case .utilities:
                imageName = "icon_utilities"
            case .insurance:
                imageName = "icon_insurance"
            case .financial:
                imageName = "icon_financial"
            case .lifestyle:
                imageName = "icon_lifestyle"
            case .entertainment:
                imageName = "icon_entertainment"
            case .miscellaneous:
                imageName = "icon_miscellaneous"
            case .healthcare:
                imageName = "icon_healthcare"
            }

            return UIImage(named: imageName)
        }
    }
}

extension Transaction {
    
    // Custom initializer is in an extension, so we don't lose the default memberwise initializer.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // Default decoding.
        self.summary = try values.decode(String.self, forKey: .summary)
        self.category = try values.decode(Category.self, forKey: .category)
        self.sum = try values.decode(Decimal.self, forKey: .sum)
        self.currency = try values.decode(String.self, forKey: .currency)
        self.paidDate = try values.decode(Date.self, forKey: .paidDate)
        
        // Decode id, if it should come as a String.
        if let idString = try? values.decode(String.self, forKey: .id), let id = Int(idString) {
            self.id = id
        }
        else {
            self.id = try values.decode(Int.self, forKey: .id)
        }
    }
}
