import Foundation
import RxSwift
import Action
import RxRelay
import RxCocoa

private enum Constants {
    static let conversionToNumberError = NSLocalizedString("ERROR_CONVERSION_TO_NUMBER", comment: "Error text shown when a user entered string cannot be converted to a number.")
}

enum TransactionDetailsError : Error {
    case unableToConvertStringToDecimal(stringToBeConverted: String)
}

extension TransactionDetailsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unableToConvertStringToDecimal(let stringToBeConverted):
            return String.localizedStringWithFormat(Constants.conversionToNumberError, stringToBeConverted)
        }
    }
}

struct EditTransactionViewModel {
    
    private let disposeBag = DisposeBag()
    
    private let sceneCoordinator: SceneCoordinatorType
    
    private let transaction: BehaviorRelay<Transaction>
    private let saveAction: Action<Transaction, Never>
    private let deleteAction: Action<Transaction, Never>
    
    // Inputs from View.
    let cancel: PublishRelay<Void> = PublishRelay()
    let save: PublishRelay<Void> = PublishRelay()
    let delete: PublishRelay<Void> = PublishRelay()
    
    // Outputs to View.
    let category: Driver<Transaction.Category>
    let categoryImageName: Driver<String>
    let categoryName: Driver<String>
    let summaryString: Driver<String>
    let dateString: Driver<String>
    let formattedAmountString: Driver<String>
    let date: Driver<Date>
    let sum: Driver<Decimal>
    let availableCategories: Driver<[Transaction.Category]>
    let availableCurrencies: Driver<[Transaction.Currency]>
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        return dateFormatter
    }()
    
    init(transaction: Transaction,
         coordinator: SceneCoordinatorType,
         saveAction: Action<Transaction, Never>,
         deleteAction: Action<Transaction, Never>) {
        self.sceneCoordinator = coordinator
        self.transaction = BehaviorRelay(value: transaction)
        
        self.saveAction = saveAction
        self.deleteAction = deleteAction
             
        category = self.transaction.asDriver().map { $0.category }
        categoryImageName = self.transaction.asDriver().map { $0.category.decorationImageName }
        categoryName = self.transaction.asDriver().map { $0.category.description }
        summaryString = self.transaction.asDriver().map { $0.summary }
        dateString = self.transaction.asDriver().map { EditTransactionViewModel.dateFormatter.string(from: $0.paidDate) }
        formattedAmountString = self.transaction.asDriver().map { $0.sum.formattedCurrencyString(currency: $0.currency) }
        date = self.transaction.asDriver().map { $0.paidDate }
        sum = self.transaction.asDriver().map { $0.sum }

        save
            .withLatestFrom(self.transaction)
            .bind(to: saveAction.inputs)
            .disposed(by: disposeBag)
            
        delete
            .withLatestFrom(self.transaction)
            .bind(to: deleteAction.inputs)
            .disposed(by: disposeBag)
        
        Signal.merge([save.asSignal(),delete.asSignal(),cancel.asSignal()])
            .emit(onNext: { coordinator.pop() } )
            .disposed(by: disposeBag)
        
        availableCategories = self.transaction.asDriver().map { transaction in
            return Transaction.Category.allCases.sorted {
                $0.description.localizedCaseInsensitiveCompare($1.description) == .orderedAscending
            }
        }
        
        availableCurrencies = self.transaction.asDriver().map { transaction in
            Transaction.Currency.allCases.sorted {
                $0.description.localizedCaseInsensitiveCompare($1.description) == .orderedAscending
            }
        }
    }
    
    lazy var changeCategoryAction: Action<Transaction.Category,Never> = { this in
        return Action(workFactory: { category in
            Observable.create( { observer in
                var newTransaction = this.transaction.value
                newTransaction.category = category
                this.transaction.accept(newTransaction)

                observer.onCompleted()
                return Disposables.create()
            })
        })
    }(self)
    
    lazy var changeCurrencyAction: Action<Transaction.Currency,Never> = { this in
        return Action(workFactory: { currency in
            Observable.create( { observer in
                var newTransaction = this.transaction.value
                newTransaction.currency = currency
                this.transaction.accept(newTransaction)

                observer.onCompleted()
                return Disposables.create()
            })
        })
    }(self)
    
    lazy var changeSummaryAction: Action<String,Never> = { this in
        return Action(workFactory: { summary in
            Observable.create( { observer in
                var newTransaction = this.transaction.value
                newTransaction.summary = summary
                this.transaction.accept(newTransaction)

                observer.onCompleted()
                return Disposables.create()
            })
        })
    }(self)
    
    
    lazy var changeSumAction: Action<String,Never> = { this in
        return Action(workFactory: { sum in
            Observable.create( { observer in
                if let decimal = Decimal.init(string: sum) {
                    var newTransaction = this.transaction.value
                    newTransaction.sum = decimal
                    this.transaction.accept(newTransaction)
                }
                else {
                    observer.onError(TransactionDetailsError.unableToConvertStringToDecimal(stringToBeConverted: sum))
                }

                observer.onCompleted()
                return Disposables.create()
            })
        })
    }(self)
    
    lazy var changeDateAction: Action<Date,Never> = { this in
        return Action(workFactory: { date in
            Observable.create( { observer in
                var newTransaction = this.transaction.value
                newTransaction.paidDate = date
                this.transaction.accept(newTransaction)

                observer.onCompleted()
                return Disposables.create()
            })
        })
    }(self)
}


