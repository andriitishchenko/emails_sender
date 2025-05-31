// ContentViewModel.swift
// EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import Foundation
import SwiftData
import AppKit
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    @Published var logs: [String] = []
    @Published var csvParameters: [String] = []
    @Published var isDropTargeted = false

    @Published var items: [Item] = []
    @Published var selectedItem: Item? = nil

    // Черновики для редактирования
    @Published var draftSubject: String = ""
    @Published var draftBodyText: String = ""
    @Published var draftCsvContent: String = ""
    @Published var isMarkdownPreview: Bool = false
    @Published var isSending: Bool = false
    @Published var sendProgress: Double = 0

    private let sendQueue = EmailSendQueue()

    let repository: ItemRepositoryProtocol
    let logger: EmailLogger
    let emailSender: EmailSenderProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: ItemRepositoryProtocol, logger: EmailLogger = EmailLogger(), emailSender: EmailSenderProtocol = AppleScriptEmailSender()) {
        self.repository = repository
        self.logger = logger
        self.emailSender = emailSender
        self.items = repository.items
        self.selectedItem = repository.selectedItem

        // Синхронизация черновиков при изменении selectedItem
        $selectedItem
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.syncDraftsWithSelectedItem()
                }
            }
            .store(in: &cancellables)

        // Привязка обновлений из репозитория (если поддерживает)
        if let repo = repository as? ItemRepository {
            repo.$items
                .receive(on: DispatchQueue.main)
                .assign(to: &$items)
        }

        // Прокидываем логи из logger в @Published logs для UI
        logger.$logs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] logs in
                self?.logs = logs
            }
            .store(in: &cancellables)

        // Подписка на состояние очереди отправки
        sendQueue.$isSending
            .assign(to: &$isSending)
        sendQueue.$progress
            .assign(to: &$sendProgress)

        // Первичная синхронизация
        Task { @MainActor in
            self.syncDraftsWithSelectedItem()
        }
    }

    private func syncDraftsWithSelectedItem() {
        draftSubject = selectedItem?.subject ?? ""
        draftBodyText = selectedItem?.bodyText ?? ""
        draftCsvContent = selectedItem?.csvContent ?? ""
        csvParameters = []

        if !draftCsvContent.isEmpty {
            let lines = draftCsvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            if let header = lines.first {
                csvParameters = header.components(separatedBy: ",")
            }
        }
    }

    func commitDrafts() {
        guard let item = selectedItem else { return }
        item.subject = draftSubject
        item.bodyText = draftBodyText
        item.csvContent = draftCsvContent
        repository.updateItem(item)
        self.items = repository.items
    }

    var sampleData: [String: String] {
        if !draftCsvContent.isEmpty {
            let lines = draftCsvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            if lines.count > 1 {
                let header = lines[0].components(separatedBy: ",")
                let values = lines[1].components(separatedBy: ",")
                var dict: [String: String] = [:]
                for (i, key) in header.enumerated() where i < values.count {
                    dict[key] = values[i]
                }
                return dict
            }
        }
        return [
            "name": "Alice",
            "email": "alice@example.com",
            "date": "2024-05-30",
            "company": "Abcd Corp"
        ]
    }

    var renderedText: String {
        TemplateRenderer.render(template: draftBodyText, with: sampleData)
    }

    var renderedSubject: String {
        TemplateRenderer.render(template: draftSubject, with: sampleData)
    }

    func addItem() {
        let newItem = repository.addItem()
        selectedItem = newItem
        self.items = repository.items
        syncDraftsWithSelectedItem()
    }

    func deleteItem(_ item: Item) {
        repository.deleteItem(item)
        if selectedItem == item {
            selectedItem = nil
        }
        self.items = repository.items
        syncDraftsWithSelectedItem()
    }

    func updateDraftSubject(_ value: String) {
        draftSubject = value
    }

    func updateDraftBodyText(_ value: String) {
        draftBodyText = value
    }

    func handleCSV(url: URL) {
        guard url.pathExtension.lowercased() == "csv" else {
            logger.log("[ERROR] Invalid file format")
            return
        }
        do {
            let csvText = try String(contentsOf: url, encoding: .utf8)
            let lines = csvText.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard let header = lines.first else { return }
            let headers = header.components(separatedBy: ",")
            guard headers.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "email" }) else {
                logger.log("[ERROR] CSV must contain 'email' column")
                return
            }
            self.csvParameters = headers
            self.draftCsvContent = csvText
            logger.log("[INFO] CSV loaded: \(url.lastPathComponent), params: \(headers.joined(separator: ", "))")
            commitDrafts()
        } catch {
            logger.log("[ERROR] Can not read CSV: \(error.localizedDescription)")
        }
    }

    func loadCSVButtonTapped() {
        logger.log("[ACTION] Load CSV button tapped")
        // TODO: Реализовать открытие диалога выбора файла и загрузку CSV
    }

    func sendButtonTapped() {
        if isSending {
            sendQueue.cancel()
            logger.log("[INFO] Sending cancelled.")
        } else {
            sendQueue.send(
                csvContent: draftCsvContent,
                subjectTemplate: draftSubject,
                bodyTemplate: draftBodyText,
                emailSender: emailSender,
                logger: logger
            )
        }
    }

    func clearLogs() {
        logger.clear()
    }
}
