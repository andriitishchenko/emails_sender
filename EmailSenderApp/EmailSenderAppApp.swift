//
//  EmailSenderAppApp.swift
//  EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import SwiftUI
import SwiftData

@main
struct EmailSenderAppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    
    static var sharedContainer: ModelContainer!

    
    static var repositoryFactory: () -> ItemRepositoryProtocol = {
        let modelContext = ModelContext(EmailSenderAppApp.sharedContainer)
        return ItemRepository(modelContext: modelContext)
    }

    init() {
        Self.sharedContainer = sharedModelContainer
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            Self.requestAppleScriptPermission()
        }
    }

    static func requestAppleScriptPermission() {
        let script = "tell application \"Mail\" to get name"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            _ = appleScript.executeAndReturnError(&error)
            if error != nil {
                print(error!.description(withLocale: nil))
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ContentViewModel(repository: Self.repositoryFactory()))
        }
        .modelContainer(sharedModelContainer)
    }
}
