import RxSwift

protocol SceneCoordinatorType {
    /// Transition to another scene.
    @discardableResult
    func transition(to scene: Scene, type: SceneTransitionType) -> Completable
    
    /// Pop scene from navigation stack or dismiss current modal.
    @discardableResult
    func pop(animated: Bool) -> Completable
}

extension SceneCoordinatorType {
    @discardableResult
    func pop() -> Completable {
        return pop(animated: true)
    }
}
