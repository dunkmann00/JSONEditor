//
//  JSONDataViewController.swift
//  
//
//  Created by George Waters on 6/16/23.
//

import UIKit

extension UIMenu.Identifier {
    static let textFormat: UIMenu.Identifier = .init("com.georgeh2os.json-editor.text-format.menu")
    
    static let fontSize: UIMenu.Identifier = .init("com.georgeh2os.json-editor.font-size.menu")
    static let indentSize: UIMenu.Identifier = .init("com.georgeh2os.json-editor.indent-size.menu")
}

extension UIAction.Identifier {
    static let smallerFont: UIAction.Identifier = .init("com.georgeh2os.json-editor.font-size.smaller")
    static let largerFont: UIAction.Identifier = .init("com.georgeh2os.json-editor.font-size.larger")
    static let fontSizeValue: UIAction.Identifier = .init("com.georgeh2os.json-editor.font-size.value")
    
    static let smallerIndent: UIAction.Identifier = .init("com.georgeh2os.json-editor.indent-size.smaller")
    static let largerIndent: UIAction.Identifier = .init("com.georgeh2os.json-editor.inent-size.larger")
    static let indentSizeValue: UIAction.Identifier = .init("com.georgeh2os.json-editor.indent-size.value")
}

public class JSONDataViewController: TextDataViewController {
    static let FONT_SIZE_KEY = "jsonValueFormatterFontSize"
    static let INDENT_SIZE_KEY = "jsonValueFormatterIndentSize"
    
    let jsonObject: JSONValue?
    
    var attributedText: AttributedString? {
        didSet {
            textView.attributedText = NSAttributedString(attributedText ?? AttributedString())
            if !wrapText {
                textViewWidth.constant = textViewIntrinsicWidth()
            }
        }
    }
    
    lazy var textFormatMenu: UIMenu = {
        UIMenu(identifier: .textFormat, children: [changeFontSizeMenu, changeIndentSizeMenu])
    }()
    
    lazy var changeFontSizeMenu: UIMenu = {
        getFontSizeMenu()
    }()
    
    lazy var changeIndentSizeMenu: UIMenu = {
       getIndentSizeMenu()
    }()
    
    lazy var fontSizeValueAction: UIAction = {
        var attributes: UIAction.Attributes = [.keepsMenuPresented]
        if jsonValueFormatter.fontSize == JSONValueFormatter.defaultFontSize {
            attributes.insert(.disabled)
        }
        return UIAction(
            title: String(jsonValueFormatter.fontSize),
            identifier: .fontSizeValue,
            attributes: attributes,
            handler: { [weak self] action in
                print("Tapped font value")
                self?.jsonValueFormatter.fontSize = JSONValueFormatter.defaultFontSize
            }
        )
    }()
    
    lazy var indentSizeValueAction: UIAction = {
        var attributes: UIAction.Attributes = [.keepsMenuPresented]
        if jsonValueFormatter.spacePerIndent == JSONValueFormatter.defaultSpacePerIndent {
            attributes.insert(.disabled)
        }
        return UIAction(
            title: String(jsonValueFormatter.spacePerIndent),
            identifier: .indentSizeValue,
            attributes: attributes,
            handler: { [weak self] action in
                print("Tapped indent value")
                self?.jsonValueFormatter.spacePerIndent = JSONValueFormatter.defaultSpacePerIndent
            }
        )
    }()
    
    var jsonValueFormatter: JSONValueFormatter {
        didSet {
            if oldValue.fontSize != jsonValueFormatter.fontSize{
                fontSizeValueAction.title = String(jsonValueFormatter.fontSize)
                var attributes: UIAction.Attributes = [.keepsMenuPresented]
                if jsonValueFormatter.fontSize == JSONValueFormatter.defaultFontSize {
                    attributes.insert(.disabled)
                }
                fontSizeValueAction.attributes = attributes
                
                UserDefaults.standard.set(jsonValueFormatter.fontSize, forKey: Self.FONT_SIZE_KEY)
                
                needsUpdateAttributedText = true
            }
            
            if oldValue.spacePerIndent != jsonValueFormatter.spacePerIndent {
                indentSizeValueAction.title = String(jsonValueFormatter.spacePerIndent)
                var attributes: UIAction.Attributes = [.keepsMenuPresented]
                if jsonValueFormatter.spacePerIndent == JSONValueFormatter.defaultSpacePerIndent {
                    attributes.insert(.disabled)
                }
                indentSizeValueAction.attributes = attributes
                
                UserDefaults.standard.set(jsonValueFormatter.spacePerIndent, forKey: Self.INDENT_SIZE_KEY)
                
                needsUpdateAttributedText = true
            }
            updateConfigureTextBarButton()
        }
    }
    
    var needsUpdateAttributedText = false
    
    weak var textViewTapGesture: UITapGestureRecognizer!
    
    weak var configureTextBarButton: UIBarButtonItem!
    
    init?(coder: NSCoder, jsonString: String? = nil, jsonData: Data? = nil) {
        var text = "⍰"
        if let jsonString = jsonString {
            text = jsonString
        } else if let jsonData = jsonData,
                  let jsonDataString = String(data: jsonData, encoding: .utf8) {
            text = jsonDataString
        }
        
        var parser = JSONParser(bytes: Array(text.utf8))
        var jsonObject: JSONValue?
        
        self.jsonValueFormatter = Self.getJSONValueFormatter()
        
        do{
            jsonObject = try parser.parse()
            if let jsonObject = jsonObject {
                self.attributedText = jsonValueFormatter.attributedString(from: jsonObject)
            }
        } catch let error as JSONError {
            print(error.localizedDescription)
        } catch {
            print("Unknown error: \(error)")
        }
        
        self.jsonObject = jsonObject
             
        super.init(coder: coder, text: text)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        addConfigureTextBarButton()
        
        if let attributedText = self.attributedText {
            textView.attributedText = NSAttributedString(attributedText)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(textViewTapGestureRecognized(_:)))
        tapGesture.delegate = self
        textView.addGestureRecognizer(tapGesture)
        textViewTapGesture = tapGesture
        
        textView.copyResponderDelegate = self
    }
    
    private static func getJSONValueFormatter() -> JSONValueFormatter {
        UserDefaults.standard.register(defaults: [
            Self.FONT_SIZE_KEY: JSONValueFormatter.defaultFontSize,
            Self.INDENT_SIZE_KEY: JSONValueFormatter.defaultSpacePerIndent
        ])
        
        let storedFontSize = UserDefaults.standard.double(forKey: Self.FONT_SIZE_KEY)
        let storedIndentSize = UserDefaults.standard.integer(forKey: Self.INDENT_SIZE_KEY)
        
        return JSONValueFormatter(fontSize: storedFontSize, spacePerIndent: storedIndentSize)
    }
    
    func getFontSizeMenu() -> UIMenu {
        UIMenu(
            title: "Font Size",
            identifier: .fontSize,
            options: .displayInline,
            preferredElementSize: .small,
            children: [
                UIAction(
                    image: .init(systemName: "textformat.size.smaller"),
                    identifier: .smallerFont,
                    attributes: .keepsMenuPresented,
                    handler: { [weak self] action in
                        print("Make font smaller")
                        self?.jsonValueFormatter.fontSize -= 0.5
                    }
                ),
                fontSizeValueAction,
                UIAction(
                    image: .init(systemName: "textformat.size.larger"),
                    identifier: .largerFont,
                    attributes: .keepsMenuPresented,
                    handler: { [weak self] action in
                        print("Make font larger")
                        self?.jsonValueFormatter.fontSize += 0.5
                    }
                ),
            ]
        )
    }
    
    func getIndentSizeMenu() -> UIMenu {
        UIMenu(
            title: "Indent Size",
            identifier: .indentSize,
            options: .displayInline,
            preferredElementSize: .small,
            children: [
                UIAction(
                    image: .init(systemName: "minus"),
                    identifier: .smallerIndent,
                    attributes: .keepsMenuPresented,
                    handler: { [weak self] action in
                        print("Make indent smaller")
                        self?.jsonValueFormatter.spacePerIndent -= 1
                    }
                ),
                indentSizeValueAction,
                UIAction(
                    image: .init(systemName: "plus"),
                    identifier: .largerIndent,
                    attributes: .keepsMenuPresented,
                    handler: { [weak self] action in
                        print("Make indent larger")
                        self?.jsonValueFormatter.spacePerIndent += 1
                    }
                ),
            ]
        )
    }
    
    func addConfigureTextBarButton() {
        let configureTextImage = UIImage(systemName: "textformat.size")
                
        let configureTextBarButton = UIBarButtonItem(image: configureTextImage, menu: textFormatMenu)
        navigationItem.rightBarButtonItems? += [configureTextBarButton]
        
        self.configureTextBarButton = configureTextBarButton
    }
    
    func updateConfigureTextBarButton() {
        configureTextBarButton.menu = textFormatMenu
        
        if needsUpdateAttributedText {
            needsUpdateAttributedText = false
            
            guard let attributedText = attributedText else {
                return
            }
            self.attributedText = jsonValueFormatter.reformatAttributedString(attributedText)

        }
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

extension JSONDataViewController: CopyResponderDelegate {
    func textView(_ textView: UITextView, copyTextIn range: NSRange) -> String? {
        guard var attributedText = self.attributedText else {
            return nil
        }
        let startIndex = attributedText.index(attributedText.startIndex, offsetByCharacters: range.location)
        let endIndex = attributedText.index(startIndex, offsetByCharacters: range.length)

        let copyText: String = jsonValueFormatter.copyAttributedString(&attributedText, in: startIndex..<endIndex)
        
        self.attributedText = attributedText
        return copyText
    }
}

extension JSONDataViewController: UIGestureRecognizerDelegate {
    @objc func textViewTapGestureRecognized(_ sender: UITapGestureRecognizer) {
        print("Tap Gesture Recognized")
        guard let tappedIndex = getAttributedStringIndex(at: sender.location(in: textView)),
              let jsonFoldableValue = getJSONFoldableValue(at: tappedIndex),
              var attributedText = self.attributedText else {
            return
        }
        
        attributedText = jsonValueFormatter.toggle(jsonFoldableValue: jsonFoldableValue, in: attributedText)
        
        self.attributedText = attributedText
    }
    
    func getAttributedStringIndex(at point: CGPoint) -> AttributedString.Index? {
        var tapLocation = point
        tapLocation.x -= textView.textContainerInset.left
        tapLocation.y -= textView.textContainerInset.top
        
        guard let textLayoutManager = textView.textLayoutManager,
              let fragment = textLayoutManager.textLayoutFragment(for: tapLocation) else {
            return nil
        }
        
        let pointInLayoutFragment = CGPoint(x: tapLocation.x - fragment.layoutFragmentFrame.minX, y: tapLocation.y - fragment.layoutFragmentFrame.minY)
        guard let lineFragment = fragment.textLineFragments.first(where: { lineFragment in
                  lineFragment.typographicBounds.contains(pointInLayoutFragment)
              }) else {
            return nil
        }
        
        let pointInLineFragment = CGPoint(x: pointInLayoutFragment.x - lineFragment.typographicBounds.minX, y: pointInLayoutFragment.y - lineFragment.typographicBounds.minY)
        let textLayoutFragmentStart = textLayoutManager.offset(from: textLayoutManager.documentRange.location, to: fragment.rangeInElement.location)
        let charIndex = lineFragment.characterIndex(for: pointInLineFragment) + textLayoutFragmentStart
        
        guard let attributedText = attributedText else {
            return nil
        }
        
        return attributedText.characters.index(attributedText.startIndex, offsetBy: charIndex, limitedBy: attributedText.endIndex)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension JSONDataViewController {
    func getJSONFoldableValue(at index: AttributedString.Index) -> JSONFoldableValue? {
        guard let attributedText = attributedText else {
            return nil
        }
        
        let jsonFoldableValue = attributedText.runs[index][keyPath: \.jsonFoldableValue]
        
        return jsonFoldableValue
    }
}

extension JSONDataViewController {
    func textViewDidChangeSelection(_ textView: UITextView) {
        // If the tap gesture is still in the possible state, the selection will start but then get aborted if the user lifts their finger because the tap is then recognized, cancelling the selection gesture.
        // If the UITextView shared the gesture it uses to make a selection I could just handle this in the gestureRecognizer:shouldRecognizeSimultaneouslyWith: delegate method, but since it doesn't this seems to be a viable workaround.
        // Doing this either has no effect when tapping normally, or will cancel the tap gesture once the text selection starts.
        textViewTapGesture?.isEnabled = false
        textViewTapGesture?.isEnabled = true
    }
}
