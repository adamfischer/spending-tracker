import UIKit
import RxSwift
import RxCocoa

class SceneCoordinator: SceneCoordinatorType {
    
    private var window: UIWindow
    private var currentViewController: UIViewController!
    
    required init(window: UIWindow) {
        self.window = window
    }
    
    // Return currently displayed child view controller if a container view controller is used.
    static func actualViewController(for viewController: UIViewController) -> UIViewController {
        
        // The only container view controller handled is UINavigationController. Expand if a new one is used.
        if let navigationController = viewController as? UINavigationController {
            return navigationController.viewControllers.first!
        }
        else {
            return viewController
        }
    }
    
    @discardableResult
    func transition(to scene: Scene, type: SceneTransitionType) -> Completable {
        let subject = PublishSubject<Void>()
        let viewController = scene.createViewControllerAndBindToViewModel()
        
        switch type {
        case .root:
            currentViewController = SceneCoordinator.actualViewController(for: viewController)
            window.rootViewController = viewController
            subject.onCompleted()
            
        case .push:
            guard let navigationController = currentViewController.navigationController else {
                fatalError("Can't push a view controller without a current navigation controller")
            }
            
            // Subscriber is notified when push completes.
            _ = navigationController.rx.delegate
                .sentMessage(#selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)))
                .map { _ in }
                .bind(to: subject)
            navigationController.pushViewController(viewController, animated: true)
            currentViewController = SceneCoordinator.actualViewController(for: viewController)
            
        case .modal:
            viewController.modalPresentationStyle = .fullScreen
            currentViewController.present(viewController, animated: true) {
                subject.onCompleted()
            }
            currentViewController = SceneCoordinator.actualViewController(for: viewController)
        }
        
        
        return subject.asObservable()
            .take(1)
            .ignoreElements()
            .asCompletable()
    }
    
    @discardableResult
    func pop(animated: Bool) -> Completable {
        let subject = PublishSubject<Void>()
        if let presenter = currentViewController.presentingViewController {
            // Dismiss modal view controller.
            currentViewController.dismiss(animated: animated) {
                self.currentViewController = SceneCoordinator.actualViewController(for: presenter)
                subject.onCompleted()
            }
        } else if let navigationController = currentViewController.navigationController {
            // Navigate up the stack. Subscriber is notified when pop completes.
            _ = navigationController.rx.delegate
                .sentMessage(#selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)))
                .map { _ in }
                .bind(to: subject)
            guard navigationController.popViewController(animated: animated) != nil else {
                fatalError("can't navigate back from \(String(describing: currentViewController))")
            }
            currentViewController = SceneCoordinator.actualViewController(for: navigationController.viewControllers.last!)
        } else {
            fatalError("Not a modal, no navigation controller: can't navigate back from \(String(describing: currentViewController))")
        }
        return subject.asObservable()
            .take(1)
            .ignoreElements()
            .asCompletable()
    }
}
