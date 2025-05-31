// EmailSender.swift
// EmailSenderApp
//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import Foundation

protocol EmailSenderProtocol {
    func sendEmail(subject: String, body: String, recipient: String) async throws
}

// MARK: - AppleScript Email Sender
final class AppleScriptEmailSender: EmailSenderProtocol {
    
        enum AppleScriptEmailError: LocalizedError {
            case mailAppNotFound
            case failedToCreateScript
            case scriptExecutionError(description: String)
    
            var errorDescription: String? {
                switch self {
                case .mailAppNotFound:
                    return "Failed to launch the Mail app."
                case .failedToCreateScript:
                    return "Failed to create AppleScript."
                case .scriptExecutionError(let description):
                    return "AppleScript execution error: \(description)"
                }
            }
        }

    func sendEmail(subject: String, body: String, recipient: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let appleScript = """
                tell application \"Mail\"
                    set newMessage to make new outgoing message with properties {subject:\"#SUBJECT\", content:\"#BODY\", visible:true}
                    tell newMessage
                        make new to recipient at end of to recipients with properties {address:\"#EMAIL\"}
                        send
                    end tell
                end tell
                """
                .replacingOccurrences(of: "#SUBJECT", with: subject)
                .replacingOccurrences(of: "#BODY", with: body)
                .replacingOccurrences(of: "#EMAIL", with: recipient)
                
                guard let script = NSAppleScript(source: appleScript) else {
                    continuation.resume(throwing:AppleScriptEmailError.failedToCreateScript)
                    return
                }
                
                var errorDict: NSDictionary?
                script.executeAndReturnError(&errorDict)
        
                if let error = errorDict {
                    let description = (error as NSDictionary).description(withLocale: nil)
                    continuation.resume(throwing: AppleScriptEmailError.scriptExecutionError(description: description))
                    return
                }
                
                // need some time to complete applescript
              Thread.sleep(forTimeInterval: 1.0)

              continuation.resume()
            }
        }
    }
}

// MARK: - SMTP Email Sender (Stub)
class SMTPEmailSender: EmailSenderProtocol {
    func sendEmail(subject: String, body: String, recipient: String) async throws {
        // TODO: Implement real SMTP logic
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
