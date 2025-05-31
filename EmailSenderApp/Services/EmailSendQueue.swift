//
//  Created by Andrii Tishchenko on 2025-05-30.
//

import Foundation

@MainActor
final class EmailSendQueue: ObservableObject {
    @Published private(set) var isSending: Bool = false
    @Published private(set) var progress: Double = 0
    private var sendTask: Task<Void, Never>? = nil
    private var cancelRequested = false

    func send(
        csvContent: String,
        subjectTemplate: String,
        bodyTemplate: String,
        emailSender: EmailSenderProtocol,
        logger: EmailLogger,
        onComplete: (() -> Void)? = nil
    ) {
        guard !isSending else { return }
        isSending = true
        cancelRequested = false
        sendTask = Task {
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else {
                logger.log("[ERROR] No recipients in CSV")
                await MainActor.run {
                    self.isSending = false
                    self.progress = 0
                    onComplete?()
                }
                return
            }
            let header = lines[0].components(separatedBy: ",")
            guard let emailIdx = header.firstIndex(where: { $0.lowercased().trimmingCharacters(in: .whitespaces) == "email" }) else {
                logger.log("[ERROR] No 'email' column in CSV header")
                await MainActor.run {
                    self.isSending = false
                    self.progress = 0
                    onComplete?()
                }
                return
            }
            let total = Double(lines.count - 1)
            for (i, line) in lines.dropFirst().enumerated() {
                if Task.isCancelled || cancelRequested {
                    logger.log("[INFO] Sending interrupted by user")
                    break
                }
                let values = line.components(separatedBy: ",")
                guard values.count == header.count else {
                    logger.log("[WARN] Skipping row \(i+1): column count mismatch")
                    continue
                }
                let dict = Dictionary(uniqueKeysWithValues: zip(header, values))
                let rawEmail = dict[header[emailIdx]]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !rawEmail.isEmpty else {
                    logger.log("[WARN] Skipping row \(i+1): empty email")
                    continue
                }
                let subject = TemplateRenderer.render(template: subjectTemplate, with: dict)
                let body = TemplateRenderer.render(template: bodyTemplate, with: dict)
                await MainActor.run {
                    logger.log("[INFO] Sending to \(rawEmail)...")
                }
                do {
                    try await emailSender.sendEmail(subject: subject, body: body, recipient: rawEmail)
                    logger.log("[SUCCESS] Sent to \(rawEmail)")
                } catch {
                    logger.log("[ERROR] Failed to send to \(rawEmail): \(error.localizedDescription)")
                }
                await MainActor.run {
                    self.progress = Double(i+1)/total
                }
            }
            logger.log("[INFO] Sending complete.")
            await MainActor.run {
                self.isSending = false
                self.progress = 0
                onComplete?()
            }
        }
    }

    func cancel() {
        cancelRequested = true
        sendTask?.cancel()
        sendTask = nil
        isSending = false
    }
}
