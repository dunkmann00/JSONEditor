//
//  Storyboarded.swift
//
//
//  Created by George Waters on 5/30/21.
//

import UIKit

protocol Storyboarded {
    static func instantiate(identifier: String?, creator: ((NSCoder) -> Self?)?) -> Self
}

extension Storyboarded where Self: UIViewController {
    static func instantiate(identifier: String? = nil, creator: ((NSCoder) -> Self?)? = nil) -> Self {
        let className = String(describing: self)
        let storyboard = UIStoryboard(name: "Storyboard", bundle: Bundle.module)
        return storyboard.instantiateViewController(identifier: identifier ?? className, creator: creator)
    }
}

extension UIViewController: Storyboarded {}
