//
//  UniqueSequence.swift
//  
//
//  Created by George Waters on 7/11/23.
//

import Foundation

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
