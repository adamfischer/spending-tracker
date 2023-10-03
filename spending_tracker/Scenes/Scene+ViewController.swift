import UIKit

extension Scene {
    func createViewControllerAndBindToViewModel() -> UIViewController {
        switch self {
        case .transactions(let viewModel):
            let viewController = TransactionsViewController()
            let navigationController = UINavigationController(rootViewController: viewController)
            viewController.bindViewModel(to: viewModel)
            return navigationController
            
        case .editTransaction(let viewModel):
            let viewController = EditTransactionViewController()
            viewController.bindViewModel(to: viewModel)
            return viewController
        }
    }
}
