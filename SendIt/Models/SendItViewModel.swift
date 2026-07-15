import UIKit

@MainActor
final class SendItViewModel: ObservableObject {
    @Published private(set) var document: ScannedDocument?
    @Published private(set) var isCreatingPDF = false
    @Published var errorMessage: String?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        if arguments.contains("-ui-testing-ready") {
            document = Self.makeUITestDocument()
        }
    }

    func createDocument(from images: [UIImage]) {
        guard let previewImage = images.first else {
            errorMessage = PDFBuilderError.emptyScan.localizedDescription
            return
        }

        isCreatingPDF = true
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async { [images] in
            let result: Result<URL, Error> = Result {
                try PDFBuilder.createPDF(from: images)
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }

                self.isCreatingPDF = false

                switch result {
                case .success(let fileURL):
                    self.document = ScannedDocument(
                        fileURL: fileURL,
                        pageCount: images.count,
                        previewImage: previewImage,
                        createdAt: Date()
                    )
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func clearDocument() {
        document = nil
    }

    func showError(_ message: String) {
        errorMessage = message
    }

    private static func makeUITestDocument() -> ScannedDocument {
        let size = CGSize(width: 850, height: 1_100)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.systemBlue.withAlphaComponent(0.14).setStroke()
            let path = UIBezierPath()
            stride(from: CGFloat(120), through: size.height - 80, by: 90).forEach { y in
                path.move(to: CGPoint(x: 70, y: y))
                path.addLine(to: CGPoint(x: size.width - 70, y: y))
            }
            path.lineWidth = 3
            path.stroke()

            UIColor.label.setStroke()
            let writing = UIBezierPath()
            writing.move(to: CGPoint(x: 120, y: 205))
            writing.addCurve(
                to: CGPoint(x: 650, y: 220),
                controlPoint1: CGPoint(x: 260, y: 165),
                controlPoint2: CGPoint(x: 470, y: 255)
            )
            writing.move(to: CGPoint(x: 120, y: 390))
            writing.addCurve(
                to: CGPoint(x: 560, y: 405),
                controlPoint1: CGPoint(x: 260, y: 350),
                controlPoint2: CGPoint(x: 410, y: 450)
            )
            writing.lineWidth = 8
            writing.lineCapStyle = .round
            writing.stroke()
        }

        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Send It UI Tests", isDirectory: true)
        let fileURL = (try? PDFBuilder.createPDF(
            from: [image, image],
            outputDirectory: outputDirectory
        )) ?? outputDirectory.appendingPathComponent("Send-It-Preview.pdf")

        return ScannedDocument(
            fileURL: fileURL,
            pageCount: 2,
            previewImage: image,
            createdAt: Date()
        )
    }
}
