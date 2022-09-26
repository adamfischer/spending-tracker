import Foundation
import UIKit

func formattedCurrencyStringFrom(value:Decimal,currency:String) -> String {
    let formatter = NumberFormatter()
    formatter.locale = NSLocale.current // This ensures the right separator behavior.
    formatter.numberStyle = NumberFormatter.Style.decimal
    formatter.usesGroupingSeparator = true
    
    let formattedNumber = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
    
    // Handle these special cases separately.
    if ( currency == "HUF" ) {
        return "\(formattedNumber) Ft"
    }
    else if ( currency == "USD" ) {
        return "$\(formattedNumber)"
    }
    else if ( currency == "EUR" ) {
        return "\(formattedNumber) €"
    }
    else {
        // Just append the currency string after the value.
        return "\(formattedNumber) \(currency)"
    }
}

func handleError(error:Error) {
    DispatchQueue.main.async {
        // This is okay, as we have a single window application.
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            let errorMessage = """
            \(error.localizedDescription)
            (\((error as NSError).domain) \((error as NSError).code))
            """
            
            let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: "Title of error message."),
                                          message: errorMessage,
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Title of OK message."),
                                          style: .default,
                                          handler: nil))
            
            // Ideally we should also check if a modal presentation / dismissal is in progress, and delay presentation. But that'd be an overkill here.
            sceneDelegate.rootTabBarController.topPresentedViewController().present(alert, animated: true, completion: nil)
        }
    }
}

extension UIViewController {

    func topPresentedViewController() -> UIViewController {
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topPresentedViewController()
        }
        else {
            return self
        }
    }
}

extension URLSession {
    func dataTask(
        with url: URL,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionDataTask {
        dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
            else if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                let error = NetworkError.httpResponseError(statusCode: response.statusCode)
                completion(.failure(error))
            }
            else if let data = data {
                completion(.success(data))
            }
            else {
                let error = NetworkError.noDataReceived
                completion(.failure(error))
            }
        }
    }
}
