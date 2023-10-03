import UIKit
import RxSwift

private enum Constants {
    static let doneString = NSLocalizedString("DONE", comment: "Title of Done button")
    static let cancelString = NSLocalizedString("CANCEL", comment: "Title of Cancel button")
}

class DatePickerViewController: UIViewController {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    // Input.
    let initialDate: Date
    
    // Output.
    var selectedDate: Observable<Date?>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.doneButton.title = Constants.doneString
        self.cancelButton.title = Constants.cancelString
        
        datePicker.date = initialDate
        
        let doneObservable: Observable<Date?> = doneButton.rx.tap
            .withLatestFrom( datePicker.rx.date)
            .map{ Optional($0) }
                             

        let cancelObservable: Observable<Date?> = cancelButton.rx.tap
            .map { nil }

        let backgroundTappedObservable: Observable<Date?> = backgroundView.rx.tapGesture().when(.recognized).map { _ in nil }

        selectedDate = Observable.merge(doneObservable,cancelObservable,backgroundTappedObservable).take(1)
    }
    
    init(initialDate: Date) {
        self.initialDate = initialDate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.initialDate = Date.now
        super.init(coder: coder)
    }
}
