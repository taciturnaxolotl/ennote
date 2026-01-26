import SwiftUI
import AVFoundation

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var isScanning = true
    @State private var scannedCode: String?
    @State private var importedNotes: [String]?
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                if isScanning {
                    CameraPreview(onCodeScanned: handleScannedCode)
                        .ignoresSafeArea()

                    // Scanning overlay
                    VStack {
                        Spacer()

                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.themeAccent, lineWidth: 3)
                            .frame(width: 250, height: 250)
                            .background(Color.clear)

                        Spacer()

                        Text("Point at QR code")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(.bottom, 50)
                    }
                } else if let notes = importedNotes {
                    // Import confirmation
                    importConfirmationView(notes: notes)
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            })
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    isScanning = true
                }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func importConfirmationView(notes: [String]) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.themeAccent)

            Text("Found \(notes.count) notes")
                .font(.title2)
                .fontWeight(.semibold)

            List {
                ForEach(notes, id: \.self) { note in
                    HStack {
                        Image(systemName: "circle")
                            .foregroundStyle(.secondary)
                        Text(note)
                            .lineLimit(1)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .frame(maxHeight: 300)

            Button {
                importNotes(notes)
            } label: {
                Text("Import Notes")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.themeAccent)
            .padding(.horizontal)

            Button("Scan Again") {
                importedNotes = nil
                isScanning = true
            }
            .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func handleScannedCode(_ code: String) {
        isScanning = false

        // Parse the deep link
        guard let url = URL(string: code),
              let stackId = Stack.parseDeepLink(url) else {
            errorMessage = "Invalid QR code. Please scan an enɳoté QR code."
            showError = true
            return
        }

        // TODO: Fetch from CloudKit
        // For now, simulate with sample data
        fetchStack(id: stackId)
    }

    private func fetchStack(id: String) {
        // TODO: Implement CloudKit fetch
        // For now, show sample notes as placeholder
        Task {
            // Simulate network delay
            try? await Task.sleep(for: .seconds(0.5))

            await MainActor.run {
                // Placeholder - in real app, fetch from CloudKit
                importedNotes = [
                    "Review PR for auth flow",
                    "Update dependencies",
                    "Write tests for sync"
                ]
            }
        }
    }

    private func importNotes(_ notes: [String]) {
        for (index, content) in notes.enumerated() {
            let note = Note(content: content, order: index)
            modelContext.insert(note)
        }
        dismiss()
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCodeScanned: (String) -> Void
        private var hasScanned = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput,
                           didOutput metadataObjects: [AVMetadataObject],
                           from connection: AVCaptureConnection) {
            guard !hasScanned,
                  let metadataObject = metadataObjects.first,
                  let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let stringValue = readableObject.stringValue else {
                return
            }

            hasScanned = true
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            DispatchQueue.main.async {
                self.onCodeScanned(stringValue)
            }
        }
    }
}

class CameraPreviewUIView: UIView {
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?

    private var captureSession: AVCaptureSession?

    override func layoutSubviews() {
        super.layoutSubviews()
        setupCaptureSession()
    }

    private func setupCaptureSession() {
        guard captureSession == nil else { return }

        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              session.canAddInput(videoInput) else {
            return
        }

        session.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()

        guard session.canAddOutput(metadataOutput) else { return }

        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)

        captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    deinit {
        captureSession?.stopRunning()
    }
}

#Preview {
    ScannerView()
        .modelContainer(for: Note.self, inMemory: true)
}
