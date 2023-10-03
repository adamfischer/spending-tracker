import UIKit
import RxSwift
import RxCocoa
import RxGesture

private enum Constants {
    static let doneString = NSLocalizedString("DONE", comment: "Title of Done button")
    static let cancelString = NSLocalizedString("CANCEL", comment: "Title of Cancel button")
}

class PickerViewController<T:CustomStringConvertible & Equatable>: PickerViewControllerWithIBOutlets {
    
    let disposeBag = DisposeBag()
    
    // Inputs.
    let items: Observable<[T]>
    let preSelectedItem: T?
    
    // Outputs.
    var selectedItem: Observable<T?>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.doneButton.title = Constants.doneString
        self.cancelButton.title = Constants.cancelString
        
        self.items.bind(to: pickerView.rx.itemTitles){ (_, element) in
            return String(describing:element)
        }
        .disposed(by: disposeBag)
        
        items
            .take(1)
            .compactMap { item in
                guard let preSelectedItem = self.preSelectedItem else { return nil }
                
                return item.firstIndex(of:preSelectedItem)
            }
            .subscribe(onNext: { index in
                self.pickerView.selectRow(index, inComponent: 0, animated: false)
            })
            .disposed(by: disposeBag)
        
        
        let doneObservable: Observable<T?> = doneButton.rx.tap
            .withLatestFrom(pickerView.rx.itemSelected.startWith((row:0,component:0)))
            .map({ (row: Int, component: Int) in
                try! self.pickerView.rx.model(at: IndexPath(row: row, section: component))
            })

        let cancelObservable: Observable<T?> = cancelButton.rx.tap.map { nil }
        
        let backgroundTappedObservable: Observable<T?> = backgroundView.rx.tapGesture().when(.recognized).map { _ in nil }

        selectedItem = Observable.merge(doneObservable,cancelObservable,backgroundTappedObservable).take(1)
    }
    
    init(items:Observable<[T]>,preSelectedItem:T? = nil) {
        self.items = items
        self.preSelectedItem = preSelectedItem
        super.init(nibName: "PickerViewControllerWithIBOutlets", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.items = Observable.of([])
        self.preSelectedItem = nil
        super.init(coder: coder)
    }
}

// We need a separate subclass just for the IB Outlets, because generic classes don't support Interface Builder.
class PickerViewControllerWithIBOutlets: UIViewController {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
}
