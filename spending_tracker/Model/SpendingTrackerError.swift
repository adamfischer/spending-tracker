import UIKit

// Error can be unconditionally and implicitly bridged to NSError. For Int based enum error types the error values are mapped to NSError codes. Domain is synthesized from the app name and enum name. But we also need localizedDescription, so LocalizedError is implemented.
enum SpendingTrackerError: Int, LocalizedError {
    case NoDataReceived = 100
    
    var errorDescription: String? {
        switch self {
        case .NoDataReceived:
            return NSLocalizedString("ERROR_NO_DATA_RECEIVED", comment: "Localized description of error.")
        }
    }
}
