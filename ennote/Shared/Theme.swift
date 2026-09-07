import SwiftUI

extension Color {
    /// The app's single brand color, defined per appearance in each target's asset catalog.
    static let themeAccent = Color("AccentColor")

    /// The ground the widgets stand on: one flat near-black, the same in both
    /// appearances, so the amber always lands the same way.
    static let themeInk = Color(red: 0.07, green: 0.068, blue: 0.062)
}
