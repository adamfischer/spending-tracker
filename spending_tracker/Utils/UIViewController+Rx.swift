import Foundation
import RxSwift
import UIKit

struct AlertAction {
    var title: String
    var style: UIAlertAction.Style
    
    static func action(title: String, style: UIAlertAction.Style = .default) -> AlertAction {
        return AlertAction(title: title, style: style)
    }
}

private enum Constants {
    static let retryingString = NSLocalizedString("RETRYING_IN_X_SECONDS_STRING", comment: "Error message title.")
    static let cancelString = NSLocalizedString("CANCEL", comment: "Title of Cancel button")
}

extension Reactive where Base: UIViewController {
    
    func showAlert(title: String?, message: String?, style: UIAlertController.Style, actions: [AlertAction])
    -> Observable<Int> {
        return Observable.create { observer in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
            
            actions.enumerated().forEach { index, action in
                let action = UIAlertAction(title: action.title, style: action.style) { _ in
                    observer.onNext(index)
                    observer.onCompleted()
                }
                alertController.addAction(action)
            }
            
            base.present(alertController, animated: true, completion: nil)
            
            return Disposables.create { alertController.dismiss(animated: true, completion: nil) }
        }
        .observe(on:MainScheduler.instance)
        .subscribe(on: MainScheduler.instance)
    }
    
    /// Alert with Ok and cancel buttons and textfield. Returns nil in Observable if user tapped cancel.
    func showAlertWithTextField(title: String?,
                                message: String?,
                                okButtonTitle: String,
                                cancelButtonTitle: String,
                                textFieldConfiguration: ((UITextField) -> Void)? = nil)
     -> Observable<String?> {
        return Observable.create { observer in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            alertController.addTextField(configurationHandler: textFieldConfiguration)
            
            let okAction = UIAlertAction(title: okButtonTitle, style: .default) { _ in
                observer.onNext(alertController.textFields![0].text)
                observer.onCompleted()
            }
            
            let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .destructive) { _ in
                observer.onNext(nil)
                observer.onCompleted()
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            
            base.present(alertController, animated: true, completion: nil)
            
            return Disposables.create { alertController.dismiss(animated: true, completion: nil) }
        }
        .observe(on:MainScheduler.instance)
        .subscribe(on: MainScheduler.instance)
    }
    
    func showRetryAlert(title: String?, time:Int) -> Observable<Int> {
        return Observable.create { observer in
            let alertController = UIAlertController(title: title,
                                                    message: String.localizedStringWithFormat(Constants.retryingString, String(time)),
                                                    preferredStyle: .alert)
            
            _ = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
                .map { timer in
                    return String.localizedStringWithFormat(Constants.retryingString, String(time - timer)) //"Retrying in \(time - timer) seconds..."
                }
                .bind(to: alertController.rx.message)
                
            
            
            let action = UIAlertAction(title: Constants.cancelString, style: .cancel) { _ in
                observer.onNext(0)
                observer.onCompleted()
            }
            alertController.addAction(action)

            base.present(alertController, animated: true, completion: nil)
            
            return Disposables.create { alertController.dismiss(animated: true, completion: nil) }
        }
        .observe(on:MainScheduler.instance)
        .subscribe(on: MainScheduler.instance)
    }
    
    func showPicker<T: CustomStringConvertible & Equatable>(items:Observable<[T]>,preSelectedItem:T? = nil) -> Observable<T?> {
        
        return Observable.create { observer in
            
            let pickerController = PickerViewController(items: items, preSelectedItem: preSelectedItem)
            
            base.present(pickerController, animated: true)
            
            // Forward selectedItem events to return value Observer.
            _ = pickerController.selectedItem?.bind(to: observer)

            return Disposables.create { pickerController.dismiss(animated: true, completion: nil) }
        }
        .observe(on:MainScheduler.instance)
        .subscribe(on: MainScheduler.instance)
    }
    
    func showDatePicker() -> Observable<Date?> {
        
        return Observable.create { observer in
            
            let datePickerVC = DatePickerViewController(initialDate: Date.now)
            
            base.present(datePickerVC , animated: true)
            
            // Forward selectedItem events to return value Observer.
            _ = datePickerVC.selectedDate?.bind(to: observer)

            return Disposables.create { datePickerVC.dismiss(animated: true, completion: nil) }
        }
        .observe(on:MainScheduler.instance)
        .subscribe(on: MainScheduler.instance)
    }
}
