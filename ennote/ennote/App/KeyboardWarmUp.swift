import UIKit

/// The keyboard's very first appearance costs the system the better part of a
/// second, and that bill lands on whichever tap opens the editor first. Paying
/// it at launch, off screen, makes the first New Note feel like the rest.
@MainActor
enum KeyboardWarmUp {
    static func run() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        else { return }

        let field = UITextField(frame: .zero)
        window.addSubview(field)
        field.becomeFirstResponder()
        field.resignFirstResponder()
        field.removeFromSuperview()
    }
}
