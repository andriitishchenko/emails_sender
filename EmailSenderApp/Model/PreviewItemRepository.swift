// PreviewItemRepository.swift
// EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import Foundation
import SwiftData

final class PreviewItemRepository: ItemRepositoryProtocol {
    var items: [Item] = [
        Item(timestamp: Date(), subject: "Demo 1"),
        Item(timestamp: Date(), subject: "Demo 2")
    ]
    var selectedItem: Item? = nil
    func addItem() -> Item {
        let newItem = Item(timestamp: Date(), subject: "Preview")
        items.append(newItem)
        selectedItem = newItem
        return newItem
    }
    func deleteItem(_ item: Item) {
        items.removeAll { $0 === item }
        if selectedItem === item {
            selectedItem = nil
        }
    }
    func updateItem(_ item: Item) {}
}
