import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var rootTabBarController = UITabBarController()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        //guard let _ = (scene as? UIWindowScene) else { return }
        
        
        // Get UIWindowScene.
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        
        // Create a new window property.
        self.window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        
        // Set windowScene for window.
        self.window?.windowScene = windowScene
        
        // Create child view controllers for the tabs. It's okay to create them immediately. Views are only loaded when the user switches tabs.
        let navigationController = UINavigationController(rootViewController: TransactionsViewController())
        navigationController.navigationBar.tintColor = UIColor(named: "foregroundColor")
        let statisticsViewController = StatisticsViewController()
        self.rootTabBarController.viewControllers = [navigationController,statisticsViewController]
        self.rootTabBarController.tabBar.tintColor = UIColor(named: "foregroundColor")
        
        // Set root.
        self.window?.rootViewController = rootTabBarController

        // Present the window.
        self.window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

