//
//  Item.swift
//  rise
//
//  Created by Piyush Bhutoria on 08/08/25.
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
