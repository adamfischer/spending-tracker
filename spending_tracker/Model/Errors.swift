import UIKit

// LocalizedError and CustomNSError ensure correct bridging to NSError.
enum NetworkError: LocalizedError, CustomNSError {
    case noDataReceived
    case httpResponseError(statusCode: Int)
    
    static var errorDomain: String {
        return "com.adamfischer.spending-tracker.networkerror"
    }
    
    var errorDescription: String? {
        switch self {
        case .noDataReceived:
            return NSLocalizedString("ERROR_NO_DATA_RECEIVED", comment: "Localized description of error.")
        case .httpResponseError(let statusCode):
            let description = NSLocalizedString("ERROR_HTTP_RESPONSE_STATUS_CODE", comment: "Localized description of error.")
            return "\(description) \(statusCode): \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
        }
    }

    var errorCode: Int {
        switch self {
        case .noDataReceived:
            return 100
        case .httpResponseError:
            return 101
        }
    }
}
