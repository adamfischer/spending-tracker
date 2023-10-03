import Foundation
import RxSwift
import RxRelay
import Action
import RxCocoa

class TransactionsViewModel {
    private let disposeBag = DisposeBag()
    
    private let sceneCoordinator: SceneCoordinatorType
    private let transactionStore: TransactionStore
    
    // Inputs from View.
    let filterText = BehaviorRelay(value: "")
    let userCancelledHandler: BehaviorRelay<((Error,Int) -> Observable<Void>)>  = BehaviorRelay(value: { (error,time) in Observable.never()})
    
    // Outputs to View.
    let filteredSortedItems: Driver<[Transaction]>!
    let requestInProgress: Driver<Bool>
        
    // Inputs from View.
    lazy var updateAction: Action<Transaction, Never> = {
        return Action(workFactory: { [weak self] newTransaction in
            guard let self = self else { return Completable.never() }
            
            return self.transactionStore.add(transaction: newTransaction)
        })
    }()
    
    lazy var deleteAction: Action<Transaction, Never> = {
        return Action(workFactory: { [weak self] newTransaction in
            guard let self = self else { return Completable.never() }
            
            return self.transactionStore.delete(transaction: newTransaction)
        })
    }()
    
    lazy var clearCacheAction: Action<Void, Never> = {
        return Action { [weak self] in
            guard let self = self else { return Completable.never() }
            
            return self.transactionStore.clearCache()
        }
    }()

    lazy var showDetailsAction: Action<Transaction, Never> = {
        return Action { [weak self] transaction in
            guard let self = self else { return Observable.never() }
            
            let transactionDetailsViewModel = EditTransactionViewModel(transaction: transaction,
                                                                          coordinator: self.sceneCoordinator,
                                                                          saveAction: self.updateAction,
                                                                          deleteAction: self.deleteAction)
            
            return self.sceneCoordinator
                .transition(to: Scene.editTransaction(transactionDetailsViewModel),
                            type: .modal)
                .asObservable()
        }
    }()
    
    lazy var createNewAction: Action<Void, Never> = {
        return Action { [weak self] in
            guard let self = self else { return Observable.never() }
            
            // Create new Transaction to be edited, with dummy initial data.
            let transaction = self.transactionStore.createNewTransaction(summary: "",
                                                                         category: .miscellaneous,
                                                                         sum: 0,
                                                                         currency: .HUF,
                                                                         paidDate: Date.now)
            
            let transactionDetailsViewModel = EditTransactionViewModel(transaction: transaction,
                                                                       coordinator: self.sceneCoordinator,
                                                                          saveAction: self.updateAction,
                                                                          deleteAction: self.deleteAction)
            
            return self.sceneCoordinator
                .transition(to: Scene.editTransaction(transactionDetailsViewModel),
                            type: .modal)
                .asObservable()
        }
    }()
    
    init(coordinator: SceneCoordinatorType, transactionStore: TransactionStore) {
        self.sceneCoordinator = coordinator
        self.transactionStore = transactionStore
        
        self.userCancelledHandler
            .bind(to: transactionStore.userCancelledHandler)
            .disposed(by: disposeBag)
        
                
        self.requestInProgress = self.transactionStore.transactions.asDriver().map { $0 == nil }
        
        let nonNillItems: Driver<[Transaction]> = self.transactionStore.transactions.asDriver()
            .compactMap { transactions in
                transactions ?? []
            }
        
        self.filteredSortedItems = Driver.combineLatest(nonNillItems, filterText.asDriver())
            .map { (items, filterText) in
                items.filter {
                    if filterText.count > 0 {
                        return $0.summary.lowercased().contains(filterText.lowercased()) || String(describing:$0.sum).contains(filterText)
                    }
                    else {
                        return true
                    }
                }
            }
            .map { $0.sorted(by: {a,b in
                a.paidDate > b.paidDate
            }) }
     }
}
