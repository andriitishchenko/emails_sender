// DragParameterLabel.swift
// EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import SwiftUI
import AppKit

struct DragParameterLabel: View {
    let parameter: String
    var body: some View {
        Text("{{\(parameter)}}")
            .font(.system(size: 12, design: .monospaced))
            .padding(4)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(4)
            .onDrag {
                NSItemProvider(object: "{{\(parameter)}}" as NSString)
            }
    }
}
