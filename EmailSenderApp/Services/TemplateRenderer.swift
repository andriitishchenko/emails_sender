// TemplateRenderer.swift
// EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import Foundation

struct TemplateRenderer {
    static func render(template: String, with data: [String: String]) -> String {
        var result = template
        for (key, value) in data {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return result
    }
}
