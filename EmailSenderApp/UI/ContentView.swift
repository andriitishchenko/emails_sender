//
//  ContentView.swift
//  EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//


import SwiftUI
import SwiftData
import AppKit

struct ContentView: View {
    @StateObject var viewModel: ContentViewModel
    @State private var logHeight: CGFloat = 120
    @State private var markdownContentHeight: CGFloat = 400

    init(viewModel: ContentViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $viewModel.selectedItem) {
                ForEach(viewModel.items, id: \.self) { item in
                    Text(item.subject.isEmpty ? item.timestamp.formatted() : item.subject)
                        .lineLimit(1)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedItem = item
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.deleteItem(item)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .toolbar {
                ToolbarItem {
                    Button(action: viewModel.addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            VStack(spacing: 0) {
                if let _ = viewModel.selectedItem {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject")
                                .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 0))
                            if viewModel.isMarkdownPreview {
                                Text(viewModel.renderedSubject)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)

                                ScrollView {
                                    Text(viewModel.renderedText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding()
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(8)
                                        .font(.system(size: 13, design: .monospaced))
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxHeight: .infinity)
                            } else {
                                TextField("Subject (placeholders allowed)", text: $viewModel.draftSubject)
                                    .padding(.vertical, 8)
                                    .background(Color.clear)
                                    .overlay(
                                        Rectangle()
                                            .fill(Color.clear), alignment: .center
                                    )
                                   .onSubmit {
                                       viewModel.commitDrafts()
                                   }

                                ScrollView {
                                    MarkdownTextView(
                                        text: $viewModel.draftBodyText,
                                        onContentHeightChange: { newHeight in
                                            Task { @MainActor in
                                                    markdownContentHeight = newHeight
                                            }
                                        }
                                    )
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity, minHeight: markdownContentHeight, alignment: .topLeading)
                                    .onDisappear {
                                        viewModel.commitDrafts()
                                    }
                                    .onChange(of: viewModel.draftBodyText) { _, _ in
                                        viewModel.commitDrafts()
                                    }
                                }
                            }

                            ResizableLogPanel(height: $logHeight) {
                                VStack(spacing: 0) {
                                ScrollView(.vertical) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(viewModel.logs.indices, id: \.self) { i in
                                            Text(viewModel.logs[i])
                                                .font(.system(size: 12, design: .monospaced))
                                                .foregroundColor(.secondary)
                                                .padding(.vertical, 2)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                }
                                .background(Color.black.opacity(0.05))
                                
                                HStack {
                                    Spacer()
                                    Button(action: { viewModel.clearLogs() }) {
                                        Image(systemName: "trash")
                                            .imageScale(.small)
                                            .help("Clear logs")
                                    }.buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.bottom, 4)
                                }
                            }
                            
                        }
                        .padding(.top, 8)

                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Parameters (CSV)")
                                .font(.headline)

                            if viewModel.csvParameters.isEmpty {
                                Text("Drag and drop CSV file here.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(viewModel.csvParameters, id: \.self) { param in
                                    DragParameterLabel(parameter: param)
                                }
                            }

                            Spacer()
                        }
                        .padding()
                        .frame(width: 200)
                        .background(viewModel.isDropTargeted ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        .onDrop(of: [.fileURL], isTargeted: $viewModel.isDropTargeted) { providers in
                            guard let provider = providers.first else { return false }
                            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                                if let url = url {
                                    DispatchQueue.main.async {
                                        viewModel.handleCSV(url: url)
                                    }
                                }
                            }
                            return true
                        }
                    }
                } else {
                    Text("Select an item from the list")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
//            .padding()
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button(action: { viewModel.isMarkdownPreview.toggle() }) {
                        Image(systemName: viewModel.isMarkdownPreview ? "eye.slash" : "eye")
                            .imageScale(.large)
                            .help(viewModel.isMarkdownPreview ? "Switch to edit mode" : "Switch to preview mode")
                    }
                    Button(action: {
                        viewModel.sendButtonTapped()
                    }) {
                        Image(systemName: viewModel.isSending ? "stop.circle.fill" : "paperplane.fill")
                            .imageScale(.large)
                        Text(viewModel.isSending ? "Cancel" : "Send")
                    }
                    .keyboardShortcut(.defaultAction)
                    .help(viewModel.isSending ? "Cancel sending" : "Send emails")
                    .disabled(viewModel.isSending && !viewModel.isSending)
                }
            }
        }
    }
}
