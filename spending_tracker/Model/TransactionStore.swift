import Foundation
import RxSwift
import RxRelay
import Action
import RxCocoa

private enum Constants {
    static let maxAttempts = 5
    static let baseURL = URL(string: "https://development.sprintform.com")!
    static let cachedTransactionsFileName = "cachedTransitions.data"
}

/// Fetches, caches and persists Transactions.
class TransactionStore {
    private let disposeBag = DisposeBag()
    let transactions = BehaviorRelay<[Transaction]?>(value:nil)
    let userCancelledHandler: BehaviorRelay<((Error,Int) -> Observable<Void>)> = BehaviorRelay(value: { (error,time) in Observable.never()})
    
    init() {
        transactions
            .skip(1) // Ignore initial value
            .flatMap({ [unowned self] transactions -> Completable in
                if let transactions = transactions {
                    return self.saveTransactionsToPersistentStorage(transactions: transactions)
                        .catch({ error in
                            print("Error encountered while trying to persist cached transaction data: \(error)")
                            return Completable.empty()
                        })
                }
                else {
                    return self.removeAllTransactionsFromPersistentStorage()
                        .catch({ error in
                            print("Error encountered while trying to remove cached transaction data: \(error)")
                            return Completable.empty()
                        })
                }
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        loadTransactionsFromPersistentStorage()
            .subscribe(onSuccess: { [unowned self] transactions in
                self.transactions.accept(transactions)
            })
            .disposed(by: disposeBag)
        
        transactions
            .filter { $0 == nil }
            .flatMapLatest { [unowned self] transactions in
                self.fetchTransactions().retry(when: self.retryHandler(userCancelledHandler: self.userCancelledHandler))
            }
            .asDriver(onErrorJustReturn: Array<Transaction>()) // Use an empty array on failure, user can add Transactions locally.
            .drive(transactions)
            .disposed(by: disposeBag)
    }
    
    // MARK: Manipulation of cached Transactions.
    
    func add(transaction: Transaction) -> Completable {
        return Completable.create(subscribe: { [unowned self] completable in
            if var currentTransactions = self.transactions.value {
                currentTransactions.removeAll(where: { item in
                    transaction.id == item.id
                })
                currentTransactions.append(transaction)
                
                self.transactions.accept(currentTransactions)
            }
            
            completable(.completed)
            
            return Disposables.create()
        })
    }
    
    /// Reset stored Transaction cache to its initial nil state. TransactionStore will immediately try to redownload data.
    func clearCache() -> Completable {
        return Completable.create(subscribe: { [unowned self] completable in
            self.transactions.accept(nil)
            
            completable(.completed)
            
            return Disposables.create()
        })
    }
    
    func delete(transaction: Transaction) -> Completable {
        return Completable.create(subscribe: { [unowned self] completable in
            if var currentTransactions = self.transactions.value {
                currentTransactions.removeAll(where: { item in
                    transaction.id == item.id
                })
                
                self.transactions.accept(currentTransactions)
            }

            completable(.completed)
            
            return Disposables.create()
        })
    }
    
    // MARK: Persistent Storage.
    
    private func saveTransactionsToPersistentStorage(transactions: [Transaction]) -> Completable {
        return Completable.create(subscribe: { completable in
            let jsonEncoder = JSONEncoder()
            do {
                let jsonData = try jsonEncoder.encode(transactions)
                try saveToDocuments(data: jsonData,fileName: Constants.cachedTransactionsFileName)
                completable(.completed)
            }
            catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        })
    }
    
    private func loadTransactionsFromPersistentStorage() -> Single<[Transaction]> {
        return Single.create(subscribe: { single in
            do {
                let data = try readFromDocuments(fileName: Constants.cachedTransactionsFileName)
                let transactions = try JSONDecoder().decode([Transaction].self, from: data)
                single(.success(transactions))
            }
            catch {
                single(.failure(error))
            }
            
            return Disposables.create()
        })
    }
    
    private func removeAllTransactionsFromPersistentStorage() -> Completable {
        Completable.create( subscribe: { completable in
            do {
                try removeFromDocuments(fileName: Constants.cachedTransactionsFileName)
                completable(.completed)
            }
            catch {
                completable(.error(error))
            }
            
            return Disposables.create()
        })
    }
    
    // MARK: Download Transaction data from server.
    
    private func fetchTransactions() -> Observable<[Transaction]> {
        request(pathComponent: "transactions.json", params: [] )
            // Uncomment to test slow fetch.
            //.delay(.milliseconds(2500), scheduler: MainScheduler.instance)
            .map { data in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                return try decoder.decode([Transaction].self, from: data)
            }
    }
    
    private func request(method: String = "GET", pathComponent: String, params: [(String, String)]) -> Observable<Data> {
        let url = Constants.baseURL.appendingPathComponent(pathComponent)
        var request = URLRequest(url: url)
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        if method == "GET" {
            let queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
            urlComponents.queryItems = queryItems
        } else {
            let jsonData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            request.httpBody = jsonData
        }
        
        request.url = urlComponents.url!
        request.httpMethod = method
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Switch these to disable/enable caching.
        let session = URLSession(configuration: .ephemeral)
        //let session = URLSession.shared
        
        return session.rx.data(request: request)
    }
    
    private func retryHandler(userCancelledHandler: BehaviorRelay<((Error,Int) -> Observable<Void>)>? = nil) -> ((Observable<Error>) -> Observable<Int>) {
        let userCancelledHandler = userCancelledHandler ?? BehaviorRelay(value: {_,_  in Observable.never()})
        
        return { (e: Observable<Error>) in
            return Observable.combineLatest(e.enumerated(),userCancelledHandler).flatMapLatest { (errorTuple, userCancelled) in
                let (attempt, error) = errorTuple
                
                if attempt >= Constants.maxAttempts - 1 {
                    // Give up, propagate error.
                    return Observable<Int>.error(error)
                }
                else {
                    let timeToWait = Int.random(in: 1..<Int(pow(2, Double(attempt + 1))))
                    print("== retrying after \(timeToWait) seconds ==")
                    let reconnection = Observable<Int>.timer(.seconds(timeToWait),
                                                             scheduler: MainScheduler.instance)
                        .take(1)
                    
                    let cancel: Observable<Int> = userCancelled(error,timeToWait)
                        .map {_ in
                            throw error
                        }
                    
                    return Observable.merge(cancel, reconnection)
                }
            }
        }
    }
    
    // MARK: Create new empty Transaction.
    
    private func getNextId() -> Int {
        let currentMaxId = self.transactions.value?.map{ $0.id }.max() ?? 0
        
        return currentMaxId + 1
    }
    
    func createNewTransaction(summary: String,
                              category: Transaction.Category,
                              sum: Decimal,
                              currency: Transaction.Currency,
                              paidDate: Date) -> Transaction {
        return Transaction(id:getNextId(), summary: summary, category: category, sum: sum, currency: currency, paidDate: paidDate)
    }
}
