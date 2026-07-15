import SwiftUI
import VisionKit

struct ContentView: View {
    @StateObject private var viewModel = SendItViewModel()
    @State private var isScannerPresented = false
    @State private var isShareSheetPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        header

                        if let document = viewModel.document {
                            readyCard(document: document)
                        } else {
                            scanCard
                        }
                    }
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 128)
                    .frame(maxWidth: .infinity)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomActionArea
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .fullScreenCover(isPresented: $isScannerPresented) {
            DocumentScannerView(
                onScan: { images in
                    isScannerPresented = false
                    viewModel.createDocument(from: images)
                },
                onCancel: {
                    isScannerPresented = false
                },
                onError: { error in
                    isScannerPresented = false
                    viewModel.showError(error.localizedDescription)
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let fileURL = viewModel.document?.fileURL {
                ShareSheet(activityItems: [fileURL])
            }
        }
        .alert(
            "Couldn’t Complete That",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(uiColor: .systemGroupedBackground),
                Color.accentColor.opacity(0.10),
                Color(uiColor: .systemGroupedBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.accentColor.opacity(0.28), radius: 18, y: 10)

                Image(systemName: "paperplane.fill")
                    .font(.system(size: 31, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(x: -1, y: 1)
            }
            .frame(width: 76, height: 76)
            .accessibilityHidden(true)

            Text("Send It")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .accessibilityIdentifier("app-title")

            Text("Scan your work. Send the PDF.")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var scanCard: some View {
        VStack(spacing: 22) {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.accentColor.opacity(0.09))

                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 58, weight: .regular))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(height: 170)
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Ready when you are")
                    .font(.title2.bold())

                Text("Point your camera at a notebook page. Send It automatically crops, straightens, and combines every page into one PDF.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                FeaturePill(icon: "wand.and.stars", label: "Auto crop")
                FeaturePill(icon: "square.stack.3d.up", label: "Multi-page")
            }

            Label("Your scans stay on this iPhone", systemImage: "lock.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(22)
        .sendItCard()
        .accessibilityIdentifier("scan-card")
    }

    private func readyCard(document: ScannedDocument) -> some View {
        VStack(spacing: 18) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: document.previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 280)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.10), radius: 14, y: 7)

                Label("PDF READY", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color.green)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(12)
            }

            VStack(spacing: 7) {
                Text(document.fileURL.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("\(document.pageCount) \(document.pageCount == 1 ? "page" : "pages") • PDF created automatically")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(22)
        .sendItCard()
        .accessibilityIdentifier("pdf-ready-card")
    }

    @ViewBuilder
    private var bottomActionArea: some View {
        VStack(spacing: 10) {
            if viewModel.isCreatingPDF {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)

                    Text("Creating your PDF…")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityIdentifier("creating-pdf-indicator")
            } else if viewModel.document != nil {
                PrimaryActionButton(
                    title: "AirDrop PDF",
                    systemImage: "paperplane.fill",
                    accessibilityIdentifier: "airdrop-pdf-button"
                ) {
                    isShareSheetPresented = true
                }

                Button {
                    viewModel.clearDocument()
                    startScanning()
                } label: {
                    Text("Scan another assignment")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("scan-another-button")
            } else {
                PrimaryActionButton(
                    title: "Scan Assignment",
                    systemImage: "camera.viewfinder",
                    accessibilityIdentifier: "scan-assignment-button"
                ) {
                    startScanning()
                }
            }
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider().opacity(0.55)
        }
    }

    private func startScanning() {
        guard VNDocumentCameraViewController.isSupported else {
            viewModel.showError("Document scanning requires a supported iPhone camera. Connect your iPhone to test the scanner.")
            return
        }

        isScannerPresented = true
    }
}

private struct FeaturePill: View {
    let icon: String
    let label: String

    var body: some View {
        Label(label, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.accentColor.opacity(0.09), in: Capsule())
    }
}

private struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.indigo],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .shadow(color: Color.accentColor.opacity(0.26), radius: 12, y: 7)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private extension View {
    func sendItCard() -> some View {
        background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.07), radius: 20, y: 10)
    }
}

#Preview {
    ContentView()
}
