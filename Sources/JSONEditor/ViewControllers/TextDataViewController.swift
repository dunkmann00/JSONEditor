//
//  TextDataViewController.swift
//  
//
//  Created by George Waters on 6/14/23.
//

import UIKit

public class TextDataViewController: UIViewController, UITextViewDelegate {
    
    var text: String {
        didSet {
            textView.text = text
            
            if !wrapText {
                textViewWidth.constant = textViewIntrinsicWidth()
            }
        }
    }
    
    var isTextEditable = false
    
    var wrapText = true {
        didSet {
            if wrapText {
                textViewWidth.isActive = false
                textViewEqualWidthToScrollViewContainer.isActive = true
                
                wrapButton.isSelected = true
                
            } else {
                textViewEqualWidthToScrollViewContainer.isActive = false
                textViewWidth.constant = textViewIntrinsicWidth()
                textViewWidth.isActive = true
                
                wrapButton.isSelected = false
            }
        }
    }
    
    @IBOutlet var textViewEqualWidthToScrollViewContainer: NSLayoutConstraint!
    @IBOutlet var textViewWidth: NSLayoutConstraint!
    
    @IBOutlet weak var scrollViewContainer: UIScrollView!
    @IBOutlet weak var textView: CopyResponderTextView!
    
    weak var wrapBarButtonItem: UIBarButtonItem!
    weak var wrapButton: UIButton!
        
    public init?(coder: NSCoder, text: String? = nil, textData: Data? = nil) {
        var vcText = ""
        if let text = text {
            vcText = text
        } else if let textData = textData, let text = String(data: textData, encoding: .utf8) {
            vcText = text
        }
        self.text = vcText
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        textView.text = text
        
        textView.isEditable = isTextEditable
        
        let wrapBarButtonItem = createWrapButton()
        navigationItem.rightBarButtonItem = wrapBarButtonItem
        self.wrapBarButtonItem = wrapBarButtonItem
        
        
        // This seems like its a bug. When I don't use any bottom inset here the scroll indicators are on the very bottom, basically behind the home indicator. But when I set it to any thing, then it uses my custom inset + the safe area inset. So by just setting it to something small like 0.1, it adjusts it by the safe area amount as desired.
        scrollViewContainer.horizontalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0.1, right: 0)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func createWrapButton() -> UIBarButtonItem {
        let lineWrapImage = UIImage(systemName: "arrow.uturn.right")
        let lineWrapButton = UIButton(primaryAction: UIAction(
            image: lineWrapImage,
            handler: { [weak self] action in
                guard let self = self else {return}
                self.wrapText.toggle()
            }
        ))
        
        lineWrapButton.isSelected = true
        
        var configuration = UIButton.Configuration.filled()
        configuration.image = lineWrapImage
        configuration.cornerStyle = .capsule
        configuration.automaticallyUpdateForSelection = false
        
        var backgroundConfig = UIBackgroundConfiguration.clear()
        backgroundConfig.strokeColor = .tintColor
        backgroundConfig.strokeWidth = 2.0
        configuration.background = backgroundConfig
        
        lineWrapButton.configurationUpdateHandler = { button in
            if button.isHighlighted {
                button.configuration?.background.backgroundColor = UIColor(red: 0.0, green: 0.4, blue: 0.89, alpha: 1.0)
            } else if button.state.contains(.selected) {
                button.configuration?.background.backgroundColor = .tintColor
            } else {
                button.configuration?.background.backgroundColor = .clear
            }
        }
        
        configuration.imageColorTransformer = UIConfigurationColorTransformer({ _ in
            if lineWrapButton.state.contains(.highlighted) || lineWrapButton.state.contains(.selected) {
                return .white
            } else {
                return .tintColor
            }
        })
        
        lineWrapButton.configuration = configuration
        lineWrapButton.transform = CGAffineTransform(rotationAngle: .pi)
        
        self.wrapButton = lineWrapButton
        
        return UIBarButtonItem(customView: lineWrapButton)
    }
    
    func textViewIntrinsicWidth() -> CGFloat {
        let intrinsicSize = textView.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        
        return intrinsicSize.width
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension TextDataViewController: PackageStoryboarded {
    static let vcIdentifier = "TextDataViewController"
    
    public static func instantiate(creator: ((NSCoder) -> TextDataViewController?)? = nil) -> Self {
        let storyboard = UIStoryboard(name: "Storyboard", bundle: Bundle.module)
        return storyboard.instantiateViewController(identifier: TextDataViewController.vcIdentifier, creator: creator) as! Self
    }
}
