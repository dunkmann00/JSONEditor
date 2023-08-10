//
//  AttributedString.swift
//  
//
//  Created by George Waters on 7/12/23.
//

import Foundation

extension BidirectionalCollection where Element : AttributedStringProtocol {
    func joined(separator: AttributedString = AttributedString()) -> AttributedString {
        var result = AttributedString()
        var iter = makeIterator()
        if let first = iter.next() {
            result.append(first)
            while let next = iter.next() {
                result.append(separator)
                result.append(next)
            }
        }
        return result
    }
}

extension AttributedStringProtocol {
    func split(separator: Character, maxSplits: Int = Int.max, omittingEmptySubsequences: Bool = true) -> [AttributedSubstring] {
        let characterViewLines = self.characters.split(separator: separator, maxSplits: maxSplits, omittingEmptySubsequences: omittingEmptySubsequences)
        return characterViewLines.map { characterViewLine in
            self[characterViewLine.startIndex..<characterViewLine.endIndex]
        }
    }
}
