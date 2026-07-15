import PDFKit
import XCTest
@testable import SendIt

final class PDFBuilderTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: temporaryDirectory)
        temporaryDirectory = nil
    }

    func testCreatesOnePDFContainingEveryScannedPage() throws {
        let images = [
            makeImage(size: CGSize(width: 850, height: 1_100), color: .white),
            makeImage(size: CGSize(width: 1_100, height: 850), color: .systemYellow)
        ]

        let fileURL = try PDFBuilder.createPDF(
            from: images,
            date: Date(timeIntervalSince1970: 1_700_000_000),
            outputDirectory: temporaryDirectory
        )

        let document = try XCTUnwrap(PDFDocument(url: fileURL))
        XCTAssertEqual(document.pageCount, 2)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertTrue(fileURL.lastPathComponent.hasPrefix("Send-It-"))
        XCTAssertEqual(fileURL.pathExtension, "pdf")
    }

    func testUsesLandscapePDFBoundsForLandscapeScan() throws {
        let image = makeImage(
            size: CGSize(width: 1_200, height: 700),
            color: .systemBlue
        )

        let fileURL = try PDFBuilder.createPDF(
            from: [image],
            outputDirectory: temporaryDirectory
        )

        let document = try XCTUnwrap(PDFDocument(url: fileURL))
        let page = try XCTUnwrap(document.page(at: 0))
        let bounds = page.bounds(for: .mediaBox)
        XCTAssertGreaterThan(bounds.width, bounds.height)
    }

    func testRejectsAnEmptyScan() {
        XCTAssertThrowsError(
            try PDFBuilder.createPDF(
                from: [],
                outputDirectory: temporaryDirectory
            )
        ) { error in
            XCTAssertEqual(error as? PDFBuilderError, .emptyScan)
        }
    }

    private func makeImage(size: CGSize, color: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
