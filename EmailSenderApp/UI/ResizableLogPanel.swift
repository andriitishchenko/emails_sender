// ResizableLogPanel.swift
// EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import SwiftUI
import AppKit

struct ResizableLogPanel<Content: View>: View {
    @Binding var height: CGFloat
    let content: () -> Content
    @State private var hovering = false
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(hovering ? 0.7 : 0.4))
                .frame(height: 3)
                .onHover { isHovering in
                    hovering = isHovering
                    if isHovering {
                        NSCursor.resizeUpDown.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            height -= value.translation.height
                            height = max(80, min(height, 400))
                        }
                )
            content()
                .frame(height: height)
        }
    }
}
