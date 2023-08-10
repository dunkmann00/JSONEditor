//
//  JSONExtensions.swift
//
//
//  Created by George Waters on 6/21/23.
//

import UIKit
import OrderedCollections


typealias JSONColor = UIColor
extension JSONColor {
    private static let redText = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .light ? UIColor(red: 0.694, green: 0.101, blue: 0.176, alpha: 1.0) : UIColor(red: 0.9, green: 0.13, blue: 0.23, alpha: 1.0)
    }
    private static let greenText = UIColor.init { traitCollection in
        traitCollection.userInterfaceStyle == .light ? UIColor(red: 0.18, green: 0.5, blue: 0.276, alpha: 1.0) : UIColor(red: 0.29, green: 0.8, blue: 0.44, alpha: 1.0)
    }
    private static let blueText = UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .light ? UIColor(red: 0.066, green: 0.212, blue: 0.65, alpha: 1.0) : UIColor(red: 0.1, green: 0.45, blue: 1.0, alpha: 1.0)
    }
    
    static let key: JSONColor      = redText
    static let string: JSONColor   = greenText
    static let number: JSONColor   = redText
    static let boolean: JSONColor  = blueText
    static let null: JSONColor     = blueText
    static let syntax: JSONColor   = UIColor.label
}

//extension AttributeContainer {
//    static func foregroundColor(_ color: JSONColor) -> Self {
//        var test: AttributeContainer.Builder = AttributeContainer().foregroundColor
//        var container = test(color)
//        container.foregroundColor = color
//        return container
//    }
//
//    static func jsonVisualHelper(_ jsonVisualHelper: JSONVisualHelper) -> Self {
//        var container = AttributeContainer()
//        container.jsonVisualHelper = jsonVisualHelper
//        return container
//    }
//}

extension AttributedString {
//    func setHeadIndent(_ headIndent: CGFloat, for item: JSONValue, wrap: NSLineBreakMode = .byWordWrapping) -> Self {
//        guard item.isValue else { return self }
//
//        return setHeadIndent(headIndent, wrap: wrap)
//    }
    
    func setHeadIndent(_ headIndent: CGFloat, wrap: NSLineBreakMode = .byWordWrapping) -> Self {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = headIndent
        paragraphStyle.lineBreakMode = wrap
        
        var container = AttributeContainer()
        container.paragraphStyle = paragraphStyle
        
        return self.mergingAttributes(container, mergePolicy: .keepNew)
    }
    
    static func sfEllipsis(attributes: AttributeContainer = .init()) -> Self {
        let ellipsis = UIImage(
            systemName: "ellipsis",
            withConfiguration: UIImage.SymbolConfiguration(scale: .large)
        )!.withTintColor(.syntax, renderingMode: .alwaysOriginal)
        let textAttachment = NSTextAttachment(image: ellipsis)
        return AttributedString("\(Unicode.Scalar(NSTextAttachment.character)!)", attributes: attributes.attachment(textAttachment))
    }
    
    static func sfPlusCircle(attributes: AttributeContainer = .init()) -> Self {
        let plusCircle = UIImage(
            systemName: "plus.circle",
            withConfiguration: UIImage.SymbolConfiguration(scale: .default)
        )!.withTintColor(.syntax, renderingMode: .alwaysOriginal)
        let textAttachment = NSTextAttachment(image: plusCircle)
        return AttributedString("\(Unicode.Scalar(NSTextAttachment.character)!)", attributes: attributes.attachment(textAttachment))
    }
    
    static func sfMinusCircle(attributes: AttributeContainer = .init()) -> Self {
        let plusCircle = UIImage(
            systemName: "minus.circle",
            withConfiguration: UIImage.SymbolConfiguration(scale: .default)
        )!.withTintColor(.syntax, renderingMode: .alwaysOriginal)
        let textAttachment = NSTextAttachment(image: plusCircle)
        return AttributedString("\(Unicode.Scalar(NSTextAttachment.character)!)", attributes: attributes.attachment(textAttachment))
    }
}

struct JSONFoldableValue {
    let id: UUID = UUID()
    var isFolded: Bool = true
    var isWholeStringTappable = true
    var fontSize: CGFloat
    var spacePerIndent: Int
    
    var attributedString: AttributedString {
        mutating get {
            if let _attributedString = _attributedString {
                return _attributedString
            }
            
            print("Generating string from creator")
            let attributedString = attributedStringCreator()
            _attributedString = attributedString
            attributedStringCreator = nil
            
            return attributedString
        }
        
        set {
            _attributedString = newValue
            attributedStringCreator = nil
        }
    }
    private var attributedStringCreator: (() -> AttributedString)!
    private var _attributedString: AttributedString?
}

extension JSONFoldableValue {
    init(fontSize: CGFloat, spacePerIndent: Int, attributedString: AttributedString) {
        self.fontSize = fontSize
        self.spacePerIndent = spacePerIndent
        self._attributedString = attributedString
    }
    
    init(fontSize: CGFloat,spacePerIndent: Int, attributedString creator: (@escaping () -> AttributedString)) {
        self.fontSize = fontSize
        self.spacePerIndent = spacePerIndent
        self.attributedStringCreator = creator
    }
}

extension JSONFoldableValue: Hashable {
    static func == (lhs: JSONFoldableValue, rhs: JSONFoldableValue) -> Bool {
        return lhs.id == rhs.id &&
               lhs.isFolded == rhs.isFolded &&
               lhs.isWholeStringTappable == rhs.isWholeStringTappable &&
               lhs._attributedString == rhs._attributedString
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isFolded)
        hasher.combine(isWholeStringTappable)
        hasher.combine(_attributedString)
    }
}

struct JSONValueFormatter {
    var foldAtDepth: Int = Self.defaultFoldAtDepth
    var foldStringsAtLength: Int = Self.defaultFoldStringsAtLength
    private(set) var font = UIFont(name: Self.fontName, size: Self.defaultFontSize)!
    var fontSize: CGFloat {
        get {
            font.pointSize
        }
        set {
            guard newValue >= Self.minimumFontSize else { return }
            font = UIFont(name: Self.fontName, size: newValue)!
            characterWidth = " ".size(withAttributes: [.font: font]).width
        }
    }
    var spacePerIndent: Int {
        get {
            _spacePerIndent
        }
        set {
            guard newValue >= Self.minimumSpacePerIndent else { return }
            _spacePerIndent = newValue
        }
    }
    private var _spacePerIndent: Int = Self.defaultSpacePerIndent
    private var characterWidth: CGFloat = Self.defaultCharacterWidth
}

extension JSONValueFormatter {
    init(foldAtDepth: Int = Self.defaultFoldAtDepth, foldStringsAtLength: Int = Self.defaultFoldStringsAtLength, fontSize: CGFloat = Self.defaultFontSize, spacePerIndent: Int = Self.defaultSpacePerIndent) {
        self.foldAtDepth = foldAtDepth
        self.foldStringsAtLength = foldStringsAtLength
        self.fontSize = fontSize
//        self.font = UIFont(name: Self.fontName, size: fontSize)!
        self.spacePerIndent = spacePerIndent
//        self.characterWidth = " ".size(withAttributes: [.font: font]).width
    }
}

extension JSONValueFormatter {
    static let fontName = "Menlo"
    static let defaultFontSize: CGFloat = 15
    static let defaultSpacePerIndent: Int = 2
    static let defaultCharacterWidth: CGFloat = 9.03076171875
    static let defaultFoldAtDepth: Int = 1
    static let defaultFoldStringsAtLength: Int = 70
    
    static let minimumFontSize: CGFloat = 6
    static let minimumSpacePerIndent: Int = 1
}

// MARK: - Public

extension JSONValueFormatter { // Public
    func attributedString(from jsonValue: JSONValue) -> AttributedString {
        var jsonAttrString = attributedString(from: jsonValue, depth: 0)
        jsonAttrString.font = font
        return jsonAttrString
    }
    
    func toggle(jsonFoldableValue: JSONFoldableValue, in attributedString: AttributedString) -> AttributedString {
        guard let jsonFoldableValueRange = range(of: jsonFoldableValue, in: attributedString) else {
            return attributedString
        }
        var jsonFoldableValue = jsonFoldableValue
        var alternateAttributedString = jsonFoldableValue.attributedString
        if jsonFoldableValue.fontSize != fontSize || jsonFoldableValue.spacePerIndent != spacePerIndent {
            alternateAttributedString = reformatAttributedString(alternateAttributedString)
            jsonFoldableValue.fontSize = fontSize
            jsonFoldableValue.spacePerIndent = spacePerIndent
        }
        jsonFoldableValue.attributedString = AttributedString(attributedString[jsonFoldableValueRange])
        jsonFoldableValue.isFolded.toggle()
        
        alternateAttributedString = set(jsonFoldableValue: jsonFoldableValue, in: alternateAttributedString)
        
        var attributedString = attributedString
        attributedString.replaceSubrange(jsonFoldableValueRange, with: alternateAttributedString)
        attributedString.font = font
        return attributedString
    }
    
    func copyAttributedString(_ attributedString: inout AttributedString, in range: Range<AttributedString.Index>) -> AttributedString {
        // Create a copy of the part of the string we want to copy
        var copyString = AttributedString(attributedString[range])
        
        // Expand all JSONFoldableValues in copyString and return expanded string. (Also updates copyString to look the same, i.e. have the same parts folded/expanded, but have the new JSONFoldableValues with their attributedStrings property generated)
        var expandedCopy = expandAttributedString(&copyString)
        
        // Similar to updating copyString, update attributedString
        attributedString.replaceSubrange(range, with: copyString)
        
        expandedCopy.font = font
        
        return expandedCopy
    }
    
    func copyAttributedString(_ attributedString: inout AttributedString, in range: Range<AttributedString.Index>) -> String {
        var copyAttributedString: AttributedString = copyAttributedString(&attributedString, in: range)
        copyAttributedString = replaceAttributedString(copyAttributedString, jsonVisualHelper: .formatSpace(), with: " ")
        copyAttributedString = replaceAttributedString(copyAttributedString, jsonVisualHelper: .foldOrExpand)
        
        return String(copyAttributedString.characters[...])
    }
    
    func reformatAttributedString(_ attributedString: AttributedString) -> AttributedString {
        var updatedAttributedString: AttributedString = attributedString.split(separator: "\n").map { attributedSubstring in
            var attributedStringLine = AttributedString(attributedSubstring)
            let runs = attributedStringLine.runs[\.jsonVisualHelper]
                                    
            for (jsonVisualHelper, range) in runs {
                if case .formatSpace(let depth) = jsonVisualHelper {
                    attributedStringLine.replaceSubrange(range, with: whitespaceForDepth(depth: depth))
                    break
                }
            }
            
            return attributedStringLine
        }.joined(separator: AttributedString("\n", attributes: .init().foregroundColor(.syntax)))
        
        updatedAttributedString.font = font
        
        return updatedAttributedString
    }
}

// MARK: - Attributed String Generation

extension JSONValueFormatter { // Attributed String Generation
    private func attributedString(from jsonValue: JSONValue, depth: Int) -> AttributedString {
        switch jsonValue {
        case .string(let string):
            return attributedString(from: string)
        case .number(let string):
            return AttributedString(string, attributes: .init().foregroundColor(.number))
        case .bool(let bool):
            return AttributedString(String(bool), attributes: .init().foregroundColor(.boolean))
        case .null:
            return AttributedString("null", attributes: .init().foregroundColor(.null))
        case .array(let array):
            return attributedString(from: array, depth: depth)
        case .object(let orderedDictionary):
            return attributedString(from: orderedDictionary, depth: depth)
        }
    }
    
    private func attributedString(from string: String) -> AttributedString {
        if string.count < foldStringsAtLength {
            return AttributedString("\"\(string)\"", attributes: .init().foregroundColor(.string))
        }
        
        let expandedAttributedString = AttributedString("\"\(string)\"", attributes: .init().foregroundColor(.string))
        
        let jsonFoldableValue = JSONFoldableValue(fontSize: fontSize, spacePerIndent: spacePerIndent, attributedString: expandedAttributedString)
        
        var endIndex = string.index(string.startIndex, offsetBy: foldStringsAtLength)
        while endIndex != string.endIndex && endIndex != string.startIndex && string[endIndex] != " " {
            endIndex = string.index(before: endIndex)
        }
        
        // If we went all the way back to the start it means there were no spaces in the string. So rather than trying to truncate at a word boundary we will just truncate at a character boundary
        if endIndex == string.startIndex {
            endIndex = string.index(string.startIndex, offsetBy: foldStringsAtLength)
        }
        
        var attributedString = AttributedString("\"\(string[..<endIndex])") +
        AttributedString("...", attributes: .init().jsonVisualHelper(.truncate)) +
                               AttributedString("\"")
        attributedString.foregroundColor = .string
        attributedString.jsonFoldableValue = jsonFoldableValue
        
        return attributedString
    }
    
    private func attributedString(from array: [JSONValue], depth: Int) -> AttributedString {
        let foldable = array.count > 0 && depth >= foldAtDepth
        let attrStringCreator = {
            var joinedAttrString = array.map { jsonValue in
                 whitespaceForDepth(depth: depth+1) + attributedString(from: jsonValue, depth: depth+1)
            }.joined(separator: AttributedString(",\n", attributes: .init().foregroundColor(.syntax)))
            
            if array.count > 0 {
                joinedAttrString = wrapJsonAttributedString(joinedAttrString, with: "\n", foldable: false) + whitespaceForDepth(depth: depth)
            }
            return wrapJsonAttributedString(joinedAttrString, with: "[]", foldable: foldable, attributes: .init().foregroundColor(.syntax))
        }
        
        if foldable {
            var jsonFoldableValue = JSONFoldableValue(fontSize: fontSize, spacePerIndent: spacePerIndent, attributedString: attrStringCreator)
            jsonFoldableValue.isWholeStringTappable = false
            var attributedString = .sfPlusCircle(attributes: .init().jsonVisualHelper(.foldOrExpand)) +
                                   AttributedString("[") + .sfEllipsis() + AttributedString("]")
            attributedString.foregroundColor = .syntax
            attributedString.jsonFoldableValue = jsonFoldableValue
            
            return attributedString
        } else {
            return attrStringCreator()
        }
    }
    
    private func attributedString(from object: OrderedDictionary<String, JSONValue>, depth: Int) -> AttributedString {
        let foldable = object.count > 0 && depth >= foldAtDepth
        let attrStringCreator = {
            var joinedAttrString = object.map { jsonValue in
                whitespaceForDepth(depth: depth+1) + attributedString(from: jsonValue, depth: depth+1)
            }.joined(separator: AttributedString(",\n", attributes: .init().foregroundColor(.syntax)))

            if object.count > 0 {
                joinedAttrString = wrapJsonAttributedString(joinedAttrString, with: "\n", foldable: false) + whitespaceForDepth(depth: depth)
            }
            return wrapJsonAttributedString(joinedAttrString, with: "{}", foldable: foldable, attributes: .init().foregroundColor(.syntax))
        }
        
        if foldable {
            var jsonFoldableValue = JSONFoldableValue(fontSize: fontSize, spacePerIndent: spacePerIndent, attributedString: attrStringCreator)
            jsonFoldableValue.isWholeStringTappable = false
            var attributedString = .sfPlusCircle(attributes: .init().jsonVisualHelper(.foldOrExpand)) +
                                   AttributedString("{") + .sfEllipsis() + AttributedString("}")
            attributedString.foregroundColor = .syntax
            attributedString.jsonFoldableValue = jsonFoldableValue
            
            return attributedString
        } else {
            return attrStringCreator()
        }
    }
    
    
    private func attributedString(from item: OrderedDictionary<String, JSONValue>.Element, depth: Int) -> AttributedString {
        return attributedString(from: item.key) +
               AttributedString(": ", attributes: .init().foregroundColor(.syntax)) +
               attributedString(from: item.value, depth: depth)
    }
}

// MARK: - Folding

extension JSONValueFormatter { // Folding
    private func set(jsonFoldableValue: JSONFoldableValue, in attributedString: AttributedString) -> AttributedString {
        var attributedString = attributedString
        
        if jsonFoldableValue.isWholeStringTappable || jsonFoldableValue.isFolded {
            attributedString.jsonFoldableValue = jsonFoldableValue
        } else {
            let openRange = ..<attributedString.index(attributedString.startIndex, offsetByCharacters: 2)
            let closeRange = attributedString.index(beforeCharacter: attributedString.endIndex)...
            attributedString[openRange].jsonFoldableValue = jsonFoldableValue
            attributedString[closeRange].jsonFoldableValue = jsonFoldableValue
        }
        
        return attributedString
    }
    
    private func expandAttributedString(_ attributedString: inout AttributedString) -> AttributedString {
        // Create a copy of the string we want to expand
        var copyString = attributedString
        
        // Get an array of jsonFoldableValue runs that are currently folded (and remove duplicates, this is caused by the start and end being in different runs)
        let runs = copyString.runs[\.jsonFoldableValue].compactMap {
            ($0.0?.isFolded ?? false) ? $0.0 : nil
        }.uniqued()
        
        // Iterate through the runs
        for jsonFoldableValueRun in runs {
            var jsonFoldableValueRun = jsonFoldableValueRun
            
            // Grab the alternate attributed string
            var alternateAttributedString = jsonFoldableValueRun.attributedString
            
            // Check if the alternate attributed string needs to be reformated
            if jsonFoldableValueRun.fontSize != fontSize || jsonFoldableValueRun.spacePerIndent != spacePerIndent {
                alternateAttributedString = reformatAttributedString(alternateAttributedString)
                jsonFoldableValueRun.fontSize = fontSize
                jsonFoldableValueRun.spacePerIndent = spacePerIndent
            }
            
            // Recursively expand the alternateAttributedString. The return value is the expanded copy which is what we want to return. We also ask that alternateAttributedString be inout, more on that to come
//            var expandedAttributedString = copyAttributedString(&alternateAttributedString, in: fullRange)
            let expandedAttributedString = expandAttributedString(&alternateAttributedString)
            
            // Get the range of the json foldable value run in copyString
            guard let jsonFoldableValueRange = self.range(of: jsonFoldableValueRun, in: copyString) else {
                continue
            }
            
            // Insert the expanded string into copy string. At this point any foldable value ranges within the string have already been recursively expanded
            copyString.replaceSubrange(jsonFoldableValueRange, with: expandedAttributedString)
            
            // Get the range of the json foldable value run in the original (inout) attributedString
            guard let jsonFoldableValueRange = self.range(of: jsonFoldableValueRun, in: attributedString) else {
                continue
            }
            
            // Update the jsonFoldableValueRun attributed string with the new alternateAttributedString. This new value has the same unexpanded text, but it has new jsonFoldableValues within it that contain the cached alternate attributedStrings that we created while building expandedAttributedString
            jsonFoldableValueRun.attributedString = alternateAttributedString
            
            // Set the updated jsonFoldableValueRun on its substring and insert it back into the inout attributedString
            let updatedAttributedString = set(jsonFoldableValue: jsonFoldableValueRun, in: AttributedString(attributedString[jsonFoldableValueRange]))
            attributedString.replaceSubrange(jsonFoldableValueRange, with: updatedAttributedString)
        }
        
        return copyString
    }
    
    private func range(of jsonFoldableValue: JSONFoldableValue, in attributedString: AttributedString) -> Range<AttributedString.Index>? {
        var startIndex: AttributedString.Index?
        var endIndex: AttributedString.Index?
        let runs = attributedString.runs[\.jsonFoldableValue]
        for (jsonFoldableValueRun, range) in runs {
            if let jsonFoldableValueRun = jsonFoldableValueRun,
               jsonFoldableValueRun.id == jsonFoldableValue.id {
                if startIndex == nil {
                    startIndex = range.lowerBound
                }
                
                endIndex = range.upperBound
            }
        }
        
        guard let startIndex = startIndex,
              let endIndex = endIndex else {
            return nil
        }
        
        return startIndex..<endIndex
    }
}

// MARK: - Utility

extension JSONValueFormatter { // Utility
    /*
     When the line is too long to have any word breaks, it breaks after the initial spaces.
     This makes it look like there is a skipped line, and the item is also indented, which
     makes no sense visually. So somehow I have to get it to not break after the initial
     spaces. Tried the non breaking space 00A0, but it didn't seem to work.
     
     It seems any of the other Unicode space characters do make it work correctly...which is
     odd given they aren't supposed to represent non breaking spaces ¯\_(ツ)_/¯ So I went
     with 2008, which is the 'Punctuation Space'. Seems kind of appropriate.
     */
    
    static let jsonFormatSpace: Character = "\u{2008}"
    
    func whitespaceForDepth(depth: Int) -> String {
        return String(repeating: JSONValueFormatter.jsonFormatSpace, count: spacePerIndent * depth)
    }
    
    func whitespaceForDepth(depth: Int) -> AttributedString {
        var attributedString = AttributedString(whitespaceForDepth(depth: depth))
        attributedString.jsonVisualHelper = .formatSpace(depth: depth)
        // Set head indent directly in here, because this is always where it is needed (i.e. at
        // the beginning of a line). It doesn't matter if it is set on the end of the line, just
        // the beginning.
        attributedString = attributedString.setHeadIndent(indentForDepth(depth: depth))
        return attributedString
    }
    
    func indentForDepth(depth: Int) -> CGFloat {
        return characterWidth * CGFloat(spacePerIndent) * CGFloat(depth+1)
    }
    
    func wrapJsonAttributedString(_ attributedString: AttributedString,
                                  with chars: String,
                                  foldable: Bool,
                                  attributes: AttributeContainer = .init()
    ) -> AttributedString {
        guard let openChar = chars.first,
              let closeChar = chars.last else {
            return attributedString
        }
        
        let foldableString: AttributedString = foldable ? .sfMinusCircle(attributes: attributes.jsonVisualHelper(.foldOrExpand)) : .init()
        
        return foldableString +
               AttributedString(String(openChar), attributes: attributes) +
               attributedString +
               AttributedString(String(closeChar), attributes: attributes)
    }
    
    func replaceAttributedString(_ attributedString: AttributedString,
                                 jsonVisualHelper: JSONVisualHelper,
                                 with replacement: Character? = nil) -> AttributedString {
        let runs = attributedString.runs[\.jsonVisualHelper]
        let replaced = runs.compactMap { (run, range) in
            guard let run = run,
                  run.isSameCaseAs(jsonVisualHelper) else {
                return AttributedString(attributedString[range])
            }
            
            let runLength = attributedString.characters.distance(from: range.lowerBound, to: range.upperBound)
            return replacement.map { AttributedString(String(repeating: $0, count: runLength)) }
        }.joined()
        
        return replaced
    }
}

enum JSONVisualHelper: Hashable {
    case formatSpace(depth: Int = 0)
    case foldOrExpand
    case truncate
    
    func isSameCaseAs(_ other: JSONVisualHelper) -> Bool {
        switch (self, other) {
        case (.formatSpace(_), .formatSpace(_)),
             (.foldOrExpand, .foldOrExpand),
             (.truncate, .truncate):
            return true
        case (.truncate, .formatSpace(_)),
             (.truncate, .foldOrExpand),
             (.foldOrExpand, .formatSpace(_)),
             (.foldOrExpand, .truncate),
             (.formatSpace(_), .foldOrExpand),
             (.formatSpace(_), .truncate):
            return false
        }
    }
}

enum JSONVisualHelperAttribute: AttributedStringKey {
    typealias Value = JSONVisualHelper
    static let name = "JSONVisualHelper"
}

enum JSONFoldableValueAttribute: AttributedStringKey {
    typealias Value = JSONFoldableValue
    static let name = "JSONFoldableValue"
}

struct JSONAttributedStringAttributes: AttributeScope {
    let jsonVisualHelper: JSONVisualHelperAttribute
    let jsonFoldableValue: JSONFoldableValueAttribute
}

extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<JSONAttributedStringAttributes, T>) -> T {
        return self[T.self]
    }
}
