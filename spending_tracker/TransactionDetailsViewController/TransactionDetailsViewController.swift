import UIKit

class TransactionDetailsViewController: UIViewController {
    
    private let transaction: Transaction
    @IBOutlet private weak var categoryImageView: UIImageView!
    @IBOutlet private weak var summaryLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var sumLabel: UILabel!
    
    init(transaction: Transaction) {
        self.transaction = transaction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented, don't instantiate TransactionDetailsViewController from Interface Builder.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("TRANSACTION_DETAILS_TITLE", comment: "Title of screen showing details of a transaction.")
        self.summaryLabel.text = self.transaction.summary
        self.categoryImageView.image = self.transaction.category.decorationImage()
        self.sumLabel.text = formattedCurrencyStringFrom(value: self.transaction.sum, currency: self.transaction.currency)
        
        // Set Date/Time Style.
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        self.dateLabel.text = dateFormatter.string(from: transaction.paidDate)
    }
}
