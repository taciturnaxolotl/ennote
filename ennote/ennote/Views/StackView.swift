import SwiftUI
import SwiftData

struct StackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Note> { !$0.isCompleted },
           sort: \Note.order)
    private var activeNotes: [Note]

    @Binding var isPresented: Bool

    @State private var completedInSession = 0
    @State private var initialCount: Int?
    @State private var offset: CGFloat = 0
    @State private var timerEnd: Date?
    @State private var showTimerPicker = false

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    header

                    Spacer()

                    // Current Note Card
                    if let currentNote = currentNote {
                        noteCard(currentNote, width: geometry.size.width - 48)
                            .offset(x: offset)
                            .gesture(swipeGesture)
                    } else {
                        completedView
                    }

                    Spacer()

                    // Instructions
                    if currentNote != nil {
                        instructions
                    }
                }
                .padding()
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
        VStack(spacing: 12) {
            // Close button and timer
            HStack {
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let timerEnd {
                    TimerDisplay(endTime: timerEnd)
                } else {
                    Button {
                        showTimerPicker = true
                    } label: {
                        Image(systemName: "timer")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Progress bar
            ProgressBar(
                completed: completedCount,
                total: totalCount
            )
        }
        .sheet(isPresented: $showTimerPicker) {
            TimerPickerSheet(timerEnd: $timerEnd)
                .presentationDetents([.height(300)])
        }
    }

    private func noteCard(_ note: Note, width: CGFloat) -> some View {
        VStack {
            Text(note.content)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
        .padding(32)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
    }

    private var completedView: some View {
        VStack(spacing: 20) {
            Text("\(totalCount) notes cleared")
                .font(.title3)
                .foregroundStyle(.secondary)

            Button("Done") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.themeAccent)
        }
    }

    private var instructions: some View {
        Text("Swipe right to complete")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.bottom, 32)
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

    // MARK: - Gestures

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation.width
            }
            .onEnded { value in
                let swipeDistance = value.translation.width

                if swipeDistance > swipeThreshold {
                    // Swipe right - complete
                    completeCurrentNote()
                } else if swipeDistance < -swipeThreshold {
                    // Swipe left - skip (optional)
                    withAnimation(.spring()) {
                        offset = 0
                    }
                } else {
                    withAnimation(.spring()) {
                        offset = 0
                    }
                }
            }
    }

    // MARK: - Actions

    private func completeCurrentNote() {
        guard let note = currentNote else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            offset = 500
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            note.complete()
            completedInSession += 1
            offset = -500

            withAnimation(.spring()) {
                offset = 0
            }
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.surface)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.themeAccent)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(completed)/\(total) notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}

// MARK: - Timer Display

struct TimerDisplay: View {
    let endTime: Date
    @State private var timeRemaining: TimeInterval = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(formatTime(timeRemaining))
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(timeRemaining < 60 ? Color.red : .secondary)
            .onAppear {
                updateTime()
            }
            .onReceive(timer) { _ in
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

    let durations: [(String, TimeInterval)] = [
        ("5 min", 5 * 60),
        ("10 min", 10 * 60),
        ("15 min", 15 * 60),
        ("25 min", 25 * 60), // Pomodoro
        ("30 min", 30 * 60)
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(durations, id: \.1) { name, duration in
                    Button {
                        timerEnd = Date().addingTimeInterval(duration)
                        dismiss()
                    } label: {
                        HStack {
                            Text(name)
                            Spacer()
                            if name == "25 min" {
                                Text("Pomodoro")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if timerEnd != nil {
                    Button("Clear timer", role: .destructive) {
                        timerEnd = nil
                        dismiss()
                    }
                }
            }
            .navigationTitle("Set Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    StackView(isPresented: .constant(true))
        .modelContainer(for: Note.self, inMemory: true)
}
