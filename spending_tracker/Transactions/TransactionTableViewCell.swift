import UIKit

struct TransactionTableViewCellConstants {
    static let height : CGFloat = 80.0
}

class TransactionTableViewCell: UITableViewCell {

    @IBOutlet weak var decorationView: UIView!
    @IBOutlet weak var decorationViewHeight: NSLayoutConstraint!
    @IBOutlet weak var categoryImageView: UIImageView!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var sumLabel: UILabel!
    @IBOutlet var debugColoredViews: [UIView]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // This constraint determines the overall height of the cell solely.
        self.decorationViewHeight.constant = TransactionTableViewCellConstants.height
        
        for view in debugColoredViews {
            view.backgroundColor = .clear
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
