// MarkdownTextView.swift
// EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import SwiftUI
import AppKit

struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    var onContentHeightChange: ((CGFloat) -> Void)? = nil

    func makeNSView(context: Context) -> NSTextView {
        let textView = NSTextView()
        textView.isEditable = true
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = .labelColor
        textView.delegate = context.coordinator
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.backgroundColor = .clear
        context.coordinator.onContentHeightChange = onContentHeightChange
        return textView
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        if nsView.string != text {
            nsView.string = text
        }
        if let layoutManager = nsView.layoutManager, let textContainer = nsView.textContainer {
            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            let fittingHeight = max(100, usedRect.height + 16)
            context.coordinator.onContentHeightChange?(fittingHeight)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onContentHeightChange: onContentHeightChange)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var onContentHeightChange: ((CGFloat) -> Void)?
        init(text: Binding<String>, onContentHeightChange: ((CGFloat) -> Void)?) {
            _text = text
            self.onContentHeightChange = onContentHeightChange
        }
        func textDidChange(_ notification: Notification) {
            if let tv = notification.object as? NSTextView {
                self.text = tv.string
                if let layoutManager = tv.layoutManager, let textContainer = tv.textContainer {
                    layoutManager.ensureLayout(for: textContainer)
                    let usedRect = layoutManager.usedRect(for: textContainer)
                    let fittingHeight = max(100, usedRect.height + 16)
                    onContentHeightChange?(fittingHeight)
                }
            }
        }
    }
}
