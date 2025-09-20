//
//  Item.swift
//  PersonalFeedApp
//
//  Created by francis on 9/18/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
