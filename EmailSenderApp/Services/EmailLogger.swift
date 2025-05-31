// EmailLogger.swift
// EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import Foundation
import Combine

@MainActor
class EmailLogger: ObservableObject {
    @Published var logs: [String] = []
    func log(_ message: String) {
        objectWillChange.send()
        logs.append(message)
    }
    func clear() {
        objectWillChange.send()
        logs.removeAll()
    }
}
