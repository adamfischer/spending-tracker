import UIKit

private let kTransactionTableViewCellId = "TransactionTableViewCellId"

class TransactionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    private var transactions = Array<Transaction>()
    private var filteredTransactions = Array<Transaction>()
    private let resultSearchController = UISearchController(searchResultsController: nil) // Pass nil if you wish to display search results in the same view that you are searching.
    private weak var activityIndicatorView: UIActivityIndicatorView? = nil
    @IBOutlet private weak var tableView: UITableView!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.commonInitTransactionsViewController()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.commonInitTransactionsViewController()
    }
    
    private func commonInitTransactionsViewController() {
        // Init tab bar icon and title.
        let item = UITabBarItem()
        item.title = NSLocalizedString("TRANSACTIONS_TABBAR_TITLE", comment: "Title of tab bar button leading to Transactions screen.")
        item.image = UIImage(named: "icon_tabbar_transactions")
        self.tabBarItem = item
        
        self.resultSearchController.searchResultsUpdater = self
        self.resultSearchController.searchBar.placeholder = NSLocalizedString("SEARCHBAR_PLACEHOLDER", comment: "Placeholder text of searchbar used to filter transactions.")
        self.resultSearchController.searchBar.tintColor = UIColor(named: "foregroundColor")
        self.resultSearchController.hidesNavigationBarDuringPresentation = false
        self.resultSearchController.obscuresBackgroundDuringPresentation = false

        self.definesPresentationContext = true // Fixes issue where the search bar remains on the screen if the user navigates to another view controller while the UISearchController is active.
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initTableView()
                
        // Ideally vectorgraphic svg files should be used, but XCode 11 is not compatible.
        let logoIcon = UIImageView(image: UIImage(named: "logo"))
        logoIcon.tintColor = UIColor(named: "foregroundColor")
        logoIcon.translatesAutoresizingMaskIntoConstraints = false
        logoIcon.heightAnchor.constraint(equalToConstant: 30).isActive = true
        let segmentBarItem = UIBarButtonItem(customView: logoIcon)
        self.navigationItem.leftBarButtonItem = segmentBarItem
        
        self.displayActivityIndicatorView()
        TransactionStore.shared.fetchTransactions { result in
            switch result {
            case .success(let transactions):
                self.transactions = transactions
                self.tableView.reloadData()
            case .failure(let error):
                handleError(error: error)
            }
            
            DispatchQueue.main.async {
                self.dismissActivityIndicatorView()
            }
        }
    }
    
    private func initTableView() {
        self.tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: kTransactionTableViewCellId)
        self.tableView.register(UINib.init(nibName: "TransactionTableViewCell", bundle: nil), forCellReuseIdentifier: kTransactionTableViewCellId)
        
        self.tableView.tableHeaderView = self.resultSearchController.searchBar
        self.tableView.backgroundView = UIView() // Workaround fix around issue where UITableView's bounce area doesn't change its color on dark theme, when UISearchController is used. See SO: 31463381
    }
    
    // MARK: - TableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ( self.resultSearchController.isActive ) {
            return self.filteredTransactions.count
        }
        else {
            return self.transactions.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let transaction = resultSearchController.isActive ? self.filteredTransactions[indexPath.row] : self.transactions[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: kTransactionTableViewCellId, for: indexPath) as! TransactionTableViewCell
        cell.summaryLabel.text = transaction.summary
        cell.categoryImageView.image = transaction.category.decorationImage()
        cell.sumLabel.text = formattedCurrencyStringFrom(value: transaction.sum, currency: transaction.currency)
        cell.decorationView.backgroundColor = transaction.category.decorationColor()
        
        // Set Date/Time Style.
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        cell.dateLabel.text = dateFormatter.string(from: transaction.paidDate)

        return cell
    }
    
    // MARK: - TableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedTransaction = resultSearchController.isActive ? filteredTransactions[indexPath.row] : transactions[indexPath.row]

        let transactionDetailsViewController = TransactionDetailsViewController(transaction: selectedTransaction)
        self.navigationController?.pushViewController(transactionDetailsViewController, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Activity Indicator
    private func displayActivityIndicatorView() {
        if ( self.activityIndicatorView == nil ) {
            self.view.isUserInteractionEnabled = false
            let activityIndicatorView = UIActivityIndicatorView(style: .large)
            activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(activityIndicatorView)
        
            activityIndicatorView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            activityIndicatorView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
            
            activityIndicatorView.startAnimating()
            self.activityIndicatorView = activityIndicatorView
        }
    }
    
    private func dismissActivityIndicatorView() {
        self.view.isUserInteractionEnabled = true
        self.activityIndicatorView?.removeFromSuperview()
    }
    
    // MARK: - UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        self.filteredTransactions.removeAll()

        if ( (searchController.searchBar.text?.count ?? 0) > 0 ) {
            let filterText = searchController.searchBar.text!
            for transaction in self.transactions {
                if ( transaction.summary.lowercased().contains(filterText.lowercased())) {
                    self.filteredTransactions.append(transaction)
                }
            }
        }
        else {
            self.filteredTransactions = transactions // Fine because arrays are value types in swift.
        }

        tableView.reloadData()
    }
}
