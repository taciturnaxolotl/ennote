import SwiftUI
import UIKit

struct StyledTextEditor: UIViewRepresentable {
    @Binding var text: String
    var onCommit: () -> Void
    var cursorPosition: CursorPosition = .start

    enum CursorPosition {
        case start
        case end
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 17)
        textView.backgroundColor = .clear
        textView.textColor = .label // Adapts to dark/light mode
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)

        // Set initial typing attributes for first line style
        textView.typingAttributes = [
            .font: UIFont.boldSystemFont(ofSize: 28),
            .foregroundColor: UIColor.label
        ]

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        guard textView.text != text else { return }

        let selectedRange = textView.selectedRange
        textView.attributedText = styledAttributedString(from: text)

        // Only set cursor position on initial load
        if !context.coordinator.hasSetInitialCursor {
            context.coordinator.hasSetInitialCursor = true
            switch cursorPosition {
            case .start:
                textView.selectedRange = NSRange(location: 0, length: 0)
            case .end:
                let endPosition = text.count
                textView.selectedRange = NSRange(location: endPosition, length: 0)
            }
        } else {
            textView.selectedRange = selectedRange
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func styledAttributedString(from text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)

        // Find the first line
        let lines = text.components(separatedBy: .newlines)
        guard let firstLine = lines.first, !firstLine.isEmpty else {
            // Apply default body style to everything
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 17), range: NSRange(location: 0, length: text.count))
            attributedString.addAttribute(.foregroundColor, value: UIColor.label.withAlphaComponent(0.75), range: NSRange(location: 0, length: text.count))
            return attributedString
        }

        let firstLineRange = NSRange(location: 0, length: firstLine.count)

        // Style first line as title (bold, larger, full brightness)
        attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 28), range: firstLineRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: firstLineRange)

        // Add spacing after title
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 8
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: firstLineRange)

        // Style rest as body (regular, smaller, slightly dimmed)
        if text.count > firstLine.count {
            let bodyRange = NSRange(location: firstLine.count, length: text.count - firstLine.count)
            attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 17), range: bodyRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor.label.withAlphaComponent(0.75), range: bodyRange)
        }

        return attributedString
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: StyledTextEditor
        var hasSetInitialCursor = false

        init(_ parent: StyledTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text

            // Reapply styling
            let selectedRange = textView.selectedRange
            textView.attributedText = parent.styledAttributedString(from: textView.text)
            textView.selectedRange = selectedRange

            // Update typing attributes based on cursor position
            let lines = textView.text.components(separatedBy: .newlines)
            let firstLineLength = lines.first?.count ?? 0

            if selectedRange.location <= firstLineLength && !textView.text.contains("\n") {
                // On first line - use title style (full brightness)
                textView.typingAttributes = [
                    .font: UIFont.boldSystemFont(ofSize: 28),
                    .foregroundColor: UIColor.label
                ]
            } else {
                // On body lines - use body style (slightly dimmed)
                textView.typingAttributes = [
                    .font: UIFont.systemFont(ofSize: 17),
                    .foregroundColor: UIColor.label.withAlphaComponent(0.75)
                ]
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" && range.location == 0 && textView.text.isEmpty {
                // If pressing return on empty first line, just add newline
                return true
            }
            return true
        }
    }
}
