import SwiftUI

struct FloatingAddButton: View {
    let action: () -> Void

    @AppStorage("isLeftHanded", store: AppGroup.sharedDefaults ?? .standard) 
    private var isLeftHanded = false
    
    @State private var isPressed = false

    var body: some View {
        VStack {
            Spacer()
            HStack {
                if !isLeftHanded {
                    Spacer()
                }

                Button(action: action) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(Color.themeAccent)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                .animation(.spring(response: 0.3), value: isPressed)
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.75)
                        .onChanged { _ in
                            isPressed = true
                        }
                        .onEnded { _ in
                            isPressed = false
                            toggleSide()
                        }
                )

                if isLeftHanded {
                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func toggleSide() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            isLeftHanded.toggle()
        }
    }
}

#Preview {
    ZStack {
        Color.background.ignoresSafeArea()
        FloatingAddButton(action: {})
    }
}
