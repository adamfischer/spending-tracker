import UIKit
import RxSwift
import RxCocoa
import Action

private enum Constants {
    static let title = NSLocalizedString("EDIT_TRANSACTION_TITLE", comment: "Title of screen which allows user to edit a transaction.")
    static let ok = NSLocalizedString("OK", comment: "Title of OK button")
    static let cancel = NSLocalizedString("CANCEL", comment: "Title of Cancel button")
    static let save = NSLocalizedString("SAVE", comment: "Title of Save button")
    static let delete = NSLocalizedString("DELETE", comment: "Title of Delete button")
    static let setCategory = NSLocalizedString("SET_CATEGORY", comment: "Title of button which changes the category of a transaction.")
    static let setDate = NSLocalizedString("SET_DATE", comment: "Title of button which changes the date of a transaction.")
    static let setAmount = NSLocalizedString("SET_AMOUNT", comment: "Title of button which changes the price of a transaction.")
    static let setCurrency = NSLocalizedString("SET_CURRENCY", comment: "Title of button which changes the currency of a transaction.")
    static let enterNewSum = NSLocalizedString("ENTER_NEW_SUM", comment: "Title of textfield where user enters a transaction's price.")
    static let error = NSLocalizedString("ERROR", comment: "Title of error message")
    static let summary = NSLocalizedString("SUMMARY", comment: "Placeholder of textfield where user enters a transaction's description.")
}

class EditTransactionViewController: UIViewController, BindableType {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    let disposeBag = DisposeBag()
    
    var viewModel: EditTransactionViewModel!
    
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var changeCategoryButton: UIButton!
    @IBOutlet weak var changeDateButton: UIButton!
    @IBOutlet weak var changeSumButton: UIButton!
    @IBOutlet weak var changeCurrencyButton: UIButton!
    
    @IBOutlet private weak var categoryImageView: UIImageView!
    @IBOutlet private weak var categoryLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var sumLabel: UILabel!
    
    @IBOutlet weak var summaryTextField: UITextField!
    
    func bindViewModel() {
        viewModel.categoryImageName
            .compactMap { UIImage(named: $0) }
            .drive(categoryImageView.rx.image)
            .disposed(by: disposeBag)
        
        viewModel.categoryName
            .drive(categoryLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.dateString
            .drive(dateLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.formattedAmountString
            .drive(sumLabel.rx.text)
            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .bind(to: viewModel.save)
            .disposed(by: disposeBag)
        
        deleteButton.rx.tap
            .bind(to: viewModel.delete)
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .bind(to: viewModel.cancel)
            .disposed(by: disposeBag)

        viewModel.summaryString
            .drive(summaryTextField.rx.text)
            .disposed(by: disposeBag)
        
        summaryTextField.rx.controlEvent([.editingDidEndOnExit,.editingDidEnd])
            .withUnretained(self)
            .map { (owner,controlEvent) in owner.summaryTextField.text ?? "" }
            .bind(to: viewModel.changeSummaryAction.inputs)
            .disposed(by: disposeBag)
        
        // To dismiss keyboard when we click outside the textfield while editing.
        view.rx.tapGesture(configuration: { tapGestureRecognizer, _ in
            tapGestureRecognizer.cancelsTouchesInView = false
        })
        .when(.recognized)
        .withUnretained(self)
        .subscribe(onNext: {(owner,event) in
            owner.view.endEditing(true)
        })
        .disposed(by: disposeBag)
        
        Observable.merge([changeSumButton.rx.tap.map{_ in},sumLabel.rx.tapGesture().when(.recognized).map{_ in}])
            .withLatestFrom( self.viewModel.sum )
            .map { $0.description }
            .withUnretained(self)
            .flatMap { (owner,currentText) -> Observable<String?> in
                owner.rx.showAlertWithTextField(title: Constants.setAmount,
                                            message: nil,
                                                okButtonTitle: Constants.ok,
                                                cancelButtonTitle: Constants.cancel,
                                            textFieldConfiguration: { textField in
                    textField.text = currentText
                    textField.placeholder = Constants.enterNewSum
                    textField.keyboardType = .decimalPad
                })
            }
            .compactMap { $0 }
            .bind(to: viewModel.changeSumAction.inputs)
            .disposed(by: disposeBag)
        
        viewModel.changeSumAction.errors
            .compactMap { (actionError: ActionError) -> Error? in
                if case .underlyingError(let error) = actionError {
                    return error
                }
                return nil
            }
            .withUnretained(self)
            .flatMap { (owner,error) -> Observable<Int> in
                owner.rx.showAlert(title: Constants.error,
                                   message: error.localizedDescription,
                                   style: .alert,
                                   actions: [AlertAction(title: Constants.ok, style: .default)])
            }
            .subscribe()
            .disposed(by: disposeBag)

        Observable.merge([changeCategoryButton.rx.tap.map{_ in},
                          categoryImageView.rx.tapGesture().when(.recognized).map{_ in},
                          categoryLabel.rx.tapGesture().when(.recognized).map{_ in}])
            .withLatestFrom(viewModel.category)
            .withUnretained(self)
            .flatMap { (owner,category) -> Observable<Transaction.Category?> in
                return owner.rx.showPicker(items: owner.viewModel.availableCategories.asObservable(),preSelectedItem: category)
            }
            .compactMap{ $0 }
            .bind(to: viewModel.changeCategoryAction.inputs)
            .disposed(by: disposeBag)
        
        changeCurrencyButton.rx.tap
            .withUnretained(self)
            .flatMap { (owner,_) -> Observable<Transaction.Currency?> in
                owner.rx.showPicker(items: owner.viewModel.availableCurrencies.asObservable())
            }
            .compactMap{ $0 }
            .bind(to: viewModel.changeCurrencyAction.inputs)
            .disposed(by: disposeBag)
        
        Observable.merge([changeDateButton.rx.tap.map{_ in},
                          dateLabel.rx.tapGesture().when(.recognized).map{_ in}])
            .withLatestFrom( self.viewModel.date )
            .withUnretained(self)
            .flatMap { (owner,currentText) -> Observable<Date?> in
                owner.rx.showDatePicker()
            }
            .compactMap { $0 }
            .bind(to: viewModel.changeDateAction.inputs)
            .disposed(by: disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localizeStrings()

        summaryTextField.addTarget(summaryTextField, action: #selector(resignFirstResponder), for: [.editingDidEndOnExit,.editingDidEnd])
        
        NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
            .withUnretained(self)
            .subscribe(onNext: { (owner,notification) in
                let userInfo = notification.userInfo!
                
                let keyboardHeight = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size.height
                
                // Scroll to make textfield completely visible.
                // Does nothing if it's already completely visible.
                var frameToScroll: CGRect = owner.summaryTextField.superview!.convert(owner.summaryTextField.frame, to: owner.scrollView)
                frameToScroll.origin.y += keyboardHeight - owner.view.safeAreaInsets.bottom
                frameToScroll.origin.y += 8; // Some extra margin.
                
                owner.scrollView.scrollRectToVisible(frameToScroll, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func localizeStrings() {
        self.summaryTextField.placeholder = Constants.summary
        self.navigationBar.topItem?.title = Constants.title
        self.cancelButton.title = Constants.cancel
        self.saveButton.title = Constants.save
        self.deleteButton.setTitle(Constants.delete, for: .normal)
        self.changeCategoryButton.setTitle(Constants.setCategory, for: .normal)
        self.changeDateButton.setTitle(Constants.setDate, for: .normal)
        self.changeSumButton.setTitle(Constants.setAmount, for: .normal)
        self.changeCurrencyButton.setTitle(Constants.setCurrency, for: .normal)
    }
}
