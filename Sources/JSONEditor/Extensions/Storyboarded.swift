//
//  Storyboarded.swift
//
//
//  Created by George Waters on 5/30/21.
//

import UIKit

protocol PackageStoryboarded {
    static func instantiate(creator: ((NSCoder) -> Self?)?) -> Self
}
