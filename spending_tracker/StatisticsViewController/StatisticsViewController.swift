import UIKit
import Charts

class StatisticsViewController: UIViewController {

    private var transactions = Array<Transaction>()
    private var summarizedTransactions : (summarizedValues:[Transaction.Category : Decimal],currency:String)? // Stores transactions summarized by category, all transactions are converted to a single currency.
    private weak var activityIndicatorView: UIActivityIndicatorView? = nil
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var pieChartView: PieChartView!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        self.commonInitStatisticsViewController()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.commonInitStatisticsViewController()
    }
    
    private func commonInitStatisticsViewController() {
        let item = UITabBarItem()
        item.title = NSLocalizedString("STATISTICS_TABBAR_TITLE", comment: "Title of tab bar button leading to Statistics screen.")
        item.image = UIImage(named: "icon_tabbar_statistics")
        self.tabBarItem = item
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = NSLocalizedString("STATISTICS_SCREEN_TITLE", comment: "Title of screen showing transaction statistics.")
        
        self.displayActivityIndicatorView()
        TransactionStore.shared.fetchTransactions { result in
            switch result {
            case .success(let transactions):
                self.transactions = transactions
                self.summarizedTransactions = self.summarizeTransactions(transactions: transactions)
                self.initPieChart()
            case .failure(let error):
                handleError(error: error)
            }
            
            DispatchQueue.main.async {
                self.dismissActivityIndicatorView()
            }
        }
    }
    
    private func summarizeTransactions(transactions:[Transaction]) -> (summarizedValues:[Transaction.Category : Decimal],currency:String) {
        var retval = (summarizedValues:[Transaction.Category : Decimal](),
                              currency:"HUF") // All amount are converted to HUF.
        
        for transaction in transactions {
            var hufValue : Decimal = Decimal(0)
            
            // TODO: ideally we should fetch real time currency exchange rates from a service like xe.com.
            if ( transaction.currency == "HUF" ) {
                hufValue += transaction.sum
            }
            else if ( transaction.currency == "EUR" ) {
                hufValue += (transaction.sum * Decimal(400))
            }
            else if ( transaction.currency == "USD" ) {
                hufValue += (transaction.sum * Decimal(400))
            }
            else {
                // Ignore all other currencies for now.
            }
            
            if ( retval.summarizedValues.keys.contains(transaction.category) ) {
                retval.summarizedValues[transaction.category]! += hufValue
            }
            else {
                retval.summarizedValues[transaction.category] = hufValue
            }
        }
        
        return retval
    }

    func initPieChart() {
        guard let summarizedTransactions = self.summarizedTransactions else {
            print("Failed to summarize transactions.")
            return
        }
        
        var values = [PieChartDataEntry]()
        var colors = [UIColor]()
        let currency = summarizedTransactions.currency
        for (category,value) in summarizedTransactions.summarizedValues {
            let label = "\(category.localizedCategoryName()): \(formattedCurrencyStringFrom(value: value, currency: currency))"// Used in the Legend.
            values.append(PieChartDataEntry(value: NSDecimalNumber(decimal:value).doubleValue, label: label, icon: category.decorationImage()))
            colors.append(category.decorationColor())
        }
        
        let dataSet = PieChartDataSet(entries: values, label: nil)
        dataSet.colors = colors
        dataSet.drawIconsEnabled = false
        dataSet.drawValuesEnabled = false

        let data = PieChartData(dataSet: dataSet)
        self.pieChartView.data = data
        self.pieChartView.isUserInteractionEnabled = false // Disable rotation of pie chart.
        self.pieChartView.holeColor = UIColor(named: "backgroundColor")
        self.pieChartView.drawEntryLabelsEnabled = false

        let legend: Charts.Legend = self.pieChartView.legend
        legend.horizontalAlignment = .left
        legend.verticalAlignment = .bottom
        legend.orientation = .vertical
        legend.form = .circle
        legend.font = NSUIFont.systemFont(ofSize: 16.0)
    }
    
    // MARK: - Activity Indicator
    func displayActivityIndicatorView() {
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
    
    func dismissActivityIndicatorView() {
        self.view.isUserInteractionEnabled = true
        self.activityIndicatorView?.removeFromSuperview()
    }

}
