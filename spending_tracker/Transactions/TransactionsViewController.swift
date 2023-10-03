import UIKit
import RxCocoa
import RxSwift

private enum Constants {
    static let transactionTableViewCellId = "TransactionTableViewCellId"
    static let retryingString = NSLocalizedString("RETRYING_IN_X_SECONDS_STRING", comment: "Error message title.")
    static let cancelString = NSLocalizedString("CANCEL", comment: "Title of Cancel button")
    static let clearCacheString = NSLocalizedString("CLEAR_CACHE", comment: "Title of button which deletes all Transactions from the cache.")
    static let searchBarPlaceholderString = NSLocalizedString("SEARCHBAR_PLACEHOLDER", comment: "Placeholder text of searchbar used to filter transactions.")
}

class TransactionsViewController: UIViewController, BindableType {
    
    private let disposeBag = DisposeBag()
    
    var viewModel: TransactionsViewModel!
    private let resultSearchController = UISearchController(searchResultsController: nil) // Pass nil if you wish to display search results in the same view that you are searching.
    
    private weak var addButton: UIBarButtonItem!
    private weak var clearCacheButton: UIBarButtonItem!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var noDataLabel: UILabel!
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        return dateFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.resultSearchController.searchBar.placeholder = Constants.searchBarPlaceholderString
        self.resultSearchController.obscuresBackgroundDuringPresentation = false
        
        self.definesPresentationContext = true // Fixes issue where the search bar remains on the screen if the user navigates to another view controller while the UISearchController is active.
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        self.navigationItem.rightBarButtonItem = addButton
        self.addButton = addButton
        
        let clearCacheButton = UIBarButtonItem(title: Constants.clearCacheString)
        self.navigationItem.leftBarButtonItem = clearCacheButton
        self.clearCacheButton = clearCacheButton
        
        self.initTableView()
    }
    
    private func initTableView() {
        self.tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: Constants.transactionTableViewCellId)
        self.tableView.register(UINib.init(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: Constants.transactionTableViewCellId)
        
        self.tableView.tableHeaderView = self.resultSearchController.searchBar
        self.tableView.backgroundView = UIView() // Workaround fix around issue where UITableView's bounce area doesn't change its color on dark theme, when UISearchController is used. See SO: 31463381
    }
    
    func bindViewModel() {
        viewModel.filteredSortedItems
            .drive(tableView.rx.items) { (tableView: UITableView, index: Int, transaction: Transaction) in
                let indexPath = IndexPath(item: index, section: 0)
                
                let cell = tableView.dequeueReusableCell(withIdentifier: Constants.transactionTableViewCellId, for: indexPath) as! TransactionTableViewCell
                
                cell.summaryLabel.text = transaction.summary
                if let categoryImage = UIImage(named: transaction.category.decorationImageName) {
                    cell.categoryImageView.image = categoryImage
                }
                else {
                    cell.categoryImageView.image = UIImage(named: "image_not_found")
                }
                
                cell.sumLabel.text = transaction.sum.formattedCurrencyString(currency: transaction.currency)
                cell.decorationView.backgroundColor = UIColor(rgbaColor: transaction.category.decorationColor)
                
                cell.dateLabel.text = self.dateFormatter.string(from: transaction.paidDate)
                
                return cell
            }
            .disposed(by: disposeBag)
        
        tableView.rx.itemSelected
            .do(onNext: { [unowned self] indexPath in
                tableView.deselectRow(at: indexPath, animated: false)
            })
            .map { [unowned self] indexPath in
                try! tableView.rx.model(at: indexPath)
            }
            .bind(to: viewModel.showDetailsAction.inputs)
            .disposed(by: disposeBag)
        
        addButton.rx.tap
            .map{ _ in }
            .bind(to: viewModel.createNewAction.inputs)
            .disposed(by: disposeBag)
        
        clearCacheButton.rx.tap
            .map{ _ in }
            .bind(to: viewModel.clearCacheAction.inputs)
            .disposed(by: disposeBag)
        
        resultSearchController.searchBar.rx.text
            .compactMap { $0 == nil ? "" : $0 }
            .bind(to: viewModel.filterText)
            .disposed(by: disposeBag)
        
        // Workaround for bug where tapping Cancel did not cause searchBar.rx.text to emit "".
        // This could be fixed directly in the Reactive extension, if we also listened to cancelButtonClicked in rx.value.
        resultSearchController.searchBar.rx.cancelButtonClicked
            .map{ "" }
            .bind(to: viewModel.filterText)
            .disposed(by: disposeBag)
        
        viewModel.requestInProgress
            .drive(activityIndicatorView.rx.isAnimating)
            .disposed(by: disposeBag)
        
        viewModel.requestInProgress
            .map { !$0 }
            .drive(addButton.rx.isEnabled,clearCacheButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.filteredSortedItems
            .asDriver(onErrorJustReturn: [])
            .map { items -> Bool in
                items.count > 0
            }
            .drive(noDataLabel.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.userCancelledHandler.accept({[weak self] (error,timeToWait) in
            guard let self = self else { return Observable.empty() }
            
            return self.rx.showRetryAlert(title: error.localizedDescription,time: timeToWait)
                .map{_ in}
        })
    }
}
