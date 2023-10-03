import UIKit

protocol BindableType: AnyObject {
    associatedtype ViewModelType
    
    var viewModel: ViewModelType! { get set }
    
    func bindViewModel()
}

extension BindableType where Self: UIViewController {
    func bindViewModel(to model: ViewModelType) {
        viewModel = model
        loadViewIfNeeded()
        bindViewModel()
    }
}
