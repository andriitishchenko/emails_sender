// ItemRepository.swift
// EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import Foundation
import SwiftData

// MARK: - 
protocol ItemRepositoryProtocol: AnyObject {
    var items: [Item] { get }
    var selectedItem: Item? { get set }
    func addItem() -> Item
    func deleteItem(_ item: Item)
    func updateItem(_ item: Item)
}

// MARK: -
final class ItemRepository: ItemRepositoryProtocol {
    private let modelContext: ModelContext
    @Published private(set) var items: [Item] = []
    var selectedItem: Item?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reloadItems()
    }

    private func reloadItems() {
        let fetchDescriptor = FetchDescriptor<Item>()
        self.items = (try? modelContext.fetch(fetchDescriptor)) ?? []
    }

    func addItem() -> Item {
        let newItem = Item(timestamp: Date(), subject: "")
        modelContext.insert(newItem)
        try? modelContext.save()
        reloadItems()
        selectedItem = newItem
        return newItem
    }

    func deleteItem(_ item: Item) {
        modelContext.delete(item)
        try? modelContext.save()
        reloadItems()
        if selectedItem == item {
            selectedItem = nil
        }
    }

    func updateItem(_ item: Item) {
        try? modelContext.save()
        reloadItems()
    }
}
