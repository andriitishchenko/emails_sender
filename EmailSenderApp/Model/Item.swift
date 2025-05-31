//
//  Item.swift
//  EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var subject: String
    var bodyText: String
    var csvContent: String  // весь CSV как текст

    init(
        timestamp: Date,
        subject: String = "",
        bodyText: String = "",
        csvContent: String = ""
    ) {
        self.timestamp = timestamp
        self.subject = subject
        self.bodyText = bodyText
        self.csvContent = csvContent
    }
}
