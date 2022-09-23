import UIKit
import Charts

class StatisticsViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!

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
    }
}
