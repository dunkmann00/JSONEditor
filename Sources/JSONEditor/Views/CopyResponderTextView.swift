//
//  CopyResponderTextView.swift
//  
//
//  Created by George Waters on 6/28/23.
//

import UIKit

protocol CopyResponderDelegate {
    func textView(_ textView: UITextView, copyTextIn range: NSRange) -> String?
}

class CopyResponderTextView: UITextView {
    
    var copyResponderDelegate: CopyResponderDelegate?
    
    override func copy(_ sender: Any?) {
        print("Copied Text")
        guard let copyResponderDelegate = copyResponderDelegate,
              let copyString = copyResponderDelegate.textView(self, copyTextIn: self.selectedRange) else {
            super.copy(sender)
            return
        }
        
        UIPasteboard.general.string = copyString
    }

}
