import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var rootTabBarController = UITabBarController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        self.window = window
        
        let sceneCoordinator = SceneCoordinator(window: window)
        let transactionStore = TransactionStore()
        
        // Initial View Model.
        let transactionsViewModel = TransactionsViewModel(coordinator: sceneCoordinator,transactionStore: transactionStore)
        let firstScene = Scene.transactions(transactionsViewModel)
        
        // This creates initial VC, and binds a View Model to it.
        sceneCoordinator.transition(to: firstScene, type: .root)

        return true
    }
}

func appDelegate() -> AppDelegate {
    guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
        fatalError("could not get app delegate ")
    }
    return delegate
 }
