import SwiftUI
import SwiftData
import WidgetKit
import DurationPicker

struct StackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Note> { !$0.isCompleted },
           sort: \Note.order)
    private var activeNotes: [Note]
    
    @Binding var isPresented: Bool
    
    @State private var completedInSession = 0
    @State private var initialCount: Int?
    @State private var timerEnd: Date?
    @State private var timerStart: Date?
    @State private var showTimerPicker = false
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.background, Color.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Compact header
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Timer progress bar
                if timerStart != nil {
                    timerProgressBar
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }
                
                Spacer()
                
                // Main content
                if let currentNote = currentNote {
                    noteStack(currentNote)
                        .padding(.horizontal, 24)
                } else {
                    completedView
                }
                
                Spacer()
                
                // Bottom controls
                if currentNote != nil {
                    bottomControls
                }
            }
            
            // Confetti effect
            if showConfetti {
                ConfettiView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if initialCount == nil {
                initialCount = activeNotes.count
            }
        }
    }
    
    // MARK: - Subviews
    
    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            // Close button
            Button {
                isPresented = false
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
            
            Spacer()
            
            // Title
            Text("enɳoté")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Timer
            Button {
                showTimerPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(timerEnd != nil ? Color.themeAccent : .primary)
                }
            }
            .sheet(isPresented: $showTimerPicker) {
                TimerPickerSheet(timerEnd: $timerEnd, timerStart: $timerStart)
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var timerProgressBar: some View {
        TimelineView(.animation(minimumInterval: 1.0)) { context in
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.surface)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(Color.themeAccent)
                        .frame(width: geometry.size.width * timerProgress, height: 6)
                }
                .padding(.horizontal, geometry.size.width * 0.125)
            }
            .frame(height: 6)
        }
    }
    
    private func noteStack(_ note: Note) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Title/first line
            if let firstLine = note.content.components(separatedBy: .newlines).first {
                Text(firstLine)
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Body if multiline
            if note.content.contains("\n") {
                let body = note.content.components(separatedBy: .newlines).dropFirst().joined(separator: "\n")
                if !body.isEmpty {
                    Text(body)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var bottomControls: some View {
        HStack(alignment: .bottom) {
            // Progress dots
            if totalCount > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<min(totalCount, 8), id: \.self) { index in
                        Circle()
                            .fill(index < completedCount ? Color.themeAccent : Color.white.opacity(0.1))
                            .frame(width: 6, height: 6)
                            .scaleEffect(index == completedCount ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: completedCount)
                    }
                    
                    if totalCount > 8 {
                        Text("+\(totalCount - 8)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Complete button icon in bottom corner
            Button {
                completeCurrentNote()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.themeAccent)
                    .background(
                        Circle()
                            .fill(Color.background)
                            .padding(8)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    private var completedView: some View {
        VStack(spacing: 32) {
            // Success animation
            ZStack {
                Circle()
                    .fill(Color.themeAccent.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .fill(Color.themeAccent.opacity(0.4))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.themeAccent)
            }
            .scaleEffect(showConfetti ? 1.0 : 0.5)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
            
            VStack(spacing: 8) {
                Text("All done!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("\(totalCount) notes completed")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                isPresented = false
            } label: {
                Text("Finish")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 48)
            .padding(.top, 16)
        }
        .onAppear {
            showConfetti = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentNote: Note? {
        activeNotes.first
    }
    
    private var completedCount: Int {
        completedInSession
    }
    
    private var totalCount: Int {
        initialCount ?? activeNotes.count
    }
    
    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    private var timerProgress: Double {
        guard let start = timerStart, let end = timerEnd else { return 0 }
        let totalDuration = end.timeIntervalSince(start)
        let elapsed = Date().timeIntervalSince(start)
        return min(max(elapsed / totalDuration, 0), 1)
    }
    
    // MARK: - Actions
    
    private func setTimer(duration: TimeInterval) {
        timerStart = Date()
        timerEnd = Date().addingTimeInterval(duration)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func completeCurrentNote() {
        guard let note = currentNote else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        note.complete()
        completedInSession += 1
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Timer Chip

struct TimerChip: View {
    let endTime: Date
    @State private var timeRemaining: TimeInterval = 0
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            
            Text(formatTime(timeRemaining))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(timeRemaining < 60 ? Color.red : Color.themeAccent)
        }
        .frame(height: 36)
        .padding(.horizontal, 12)
        .onAppear {
            updateTime()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateTime()
        }
    }
    
    private func updateTime() {
        timeRemaining = max(0, endTime.timeIntervalSince(Date()))
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Timer Picker Sheet

struct TimerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var timerEnd: Date?
    @Binding var timerStart: Date?
    
    @State private var duration: TimeInterval = 15 * 60
    
    var body: some View {
        VStack(spacing: 24) {
            DurationPickerView(duration: $duration)
                .frame(height: 180)
            
            VStack(spacing: 12) {
                Button {
                    timerStart = Date()
                    timerEnd = Date().addingTimeInterval(duration)
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    dismiss()
                } label: {
                    Text("Start Timer")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if timerEnd != nil {
                    Button(role: .destructive) {
                        timerEnd = nil
                        timerStart = nil
                        dismiss()
                    } label: {
                        Text("Clear Timer")
                            .font(.headline)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            if let end = timerEnd, let start = timerStart {
                duration = end.timeIntervalSince(start)
            }
        }
    }
}

// MARK: - DurationPicker Wrapper

struct DurationPickerView: UIViewRepresentable {
    @Binding var duration: TimeInterval
    
    func makeUIView(context: Context) -> DurationPicker {
        let picker = DurationPicker()
        picker.pickerMode = .minuteSecond
        picker.duration = duration
        picker.addTarget(context.coordinator, action: #selector(Coordinator.durationChanged), for: .valueChanged)
        return picker
    }
    
    func updateUIView(_ picker: DurationPicker, context: Context) {
        if picker.duration != duration {
            picker.duration = duration
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(duration: $duration)
    }
    
    class Coordinator: NSObject {
        @Binding var duration: TimeInterval
        
        init(duration: Binding<TimeInterval>) {
            _duration = duration
        }
        
        @objc func durationChanged(_ picker: DurationPicker) {
            duration = picker.duration
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<30) { index in
                ConfettiPiece(index: index, animate: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    let animate: Bool
    
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    
    private let colors: [Color] = [.themeAccent, .success, .blue, .purple, .pink, .orange]
    
    var body: some View {
        Circle()
            .fill(colors[index % colors.count])
            .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
            .position(position)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                let startX = CGFloat.random(in: 100...300)
                let startY = CGFloat.random(in: 200...400)
                position = CGPoint(x: startX, y: startY)
                
                withAnimation(
                    .easeOut(duration: Double.random(in: 1...2))
                    .delay(Double.random(in: 0...0.5))
                ) {
                    position.y += CGFloat.random(in: 200...400)
                    position.x += CGFloat.random(in: -100...100)
                    opacity = 0
                    rotation = Double.random(in: -360...360)
                }
            }
    }
}

#Preview {
    StackView(isPresented: .constant(true))
        .modelContainer(for: Note.self, inMemory: true)
}
