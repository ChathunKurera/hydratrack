//
//  Item.swift
//  HydraTrack
//
//  Created by Chathun Kurera on 1/25/26.
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
