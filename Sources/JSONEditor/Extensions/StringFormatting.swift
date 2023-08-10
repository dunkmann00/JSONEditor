//
//  StringFormatting.swift
//  
//
//  Created by George Waters on 7/19/23.
//

import Foundation

extension String {
     internal init (_ value: CGFloat) {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 1
        self.init(numberFormatter.string(for: value) ?? "")
    }
}
