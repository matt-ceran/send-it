import UIKit

enum PDFBuilderError: LocalizedError, Equatable {
    case emptyScan
    case invalidImage
    case writingFailed

    var errorDescription: String? {
        switch self {
        case .emptyScan:
            return "No scanned pages were available to create the PDF."
        case .invalidImage:
            return "One of the scanned pages could not be prepared."
        case .writingFailed:
            return "The PDF could not be created. Please scan the assignment again."
        }
    }
}

enum PDFBuilder {
    private static let portraitPage = CGRect(x: 0, y: 0, width: 612, height: 792)
    private static let landscapePage = CGRect(x: 0, y: 0, width: 792, height: 612)
    private static let contentMargin: CGFloat = 18
    private static let maximumImageDimension: CGFloat = 2_400

    static func createPDF(
        from images: [UIImage],
        date: Date = Date(),
        outputDirectory: URL? = nil
    ) throws -> URL {
        guard !images.isEmpty else {
            throw PDFBuilderError.emptyScan
        }

        let fileManager = FileManager.default
        let directory = outputDirectory ?? defaultOutputDirectory(fileManager: fileManager)

        do {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        } catch {
            throw PDFBuilderError.writingFailed
        }

        let fileURL = uniqueFileURL(in: directory, date: date, fileManager: fileManager)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Send It Assignment",
            kCGPDFContextCreator as String: "Send It"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: portraitPage, format: format)

        do {
            try renderer.writePDF(to: fileURL) { context in
                for image in images {
                    autoreleasepool {
                        let preparedImage = prepare(image: image)
                        let pageBounds = preparedImage.size.width > preparedImage.size.height
                            ? landscapePage
                            : portraitPage

                        context.beginPage(withBounds: pageBounds, pageInfo: [:])
                        UIColor.white.setFill()
                        context.cgContext.fill(pageBounds)

                        let contentBounds = pageBounds.insetBy(
                            dx: contentMargin,
                            dy: contentMargin
                        )
                        preparedImage.draw(in: aspectFit(preparedImage.size, inside: contentBounds))
                    }
                }
            }
        } catch {
            try? fileManager.removeItem(at: fileURL)
            throw PDFBuilderError.writingFailed
        }

        guard
            let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
            let fileSize = attributes[.size] as? NSNumber,
            fileSize.intValue > 0
        else {
            try? fileManager.removeItem(at: fileURL)
            throw PDFBuilderError.writingFailed
        }

        if outputDirectory == nil {
            removeOlderGeneratedPDFs(in: directory, keeping: fileURL, fileManager: fileManager)
        }

        return fileURL
    }

    private static func defaultOutputDirectory(fileManager: FileManager) -> URL {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return cachesDirectory.appendingPathComponent("Generated PDFs", isDirectory: true)
    }

    private static func uniqueFileURL(
        in directory: URL,
        date: Date,
        fileManager: FileManager
    ) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"

        let baseName = "Send-It-\(formatter.string(from: date))"
        var candidate = directory.appendingPathComponent(baseName).appendingPathExtension("pdf")
        var suffix = 2

        while fileManager.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(baseName)-\(suffix)")
                .appendingPathExtension("pdf")
            suffix += 1
        }

        return candidate
    }

    private static func prepare(image: UIImage) -> UIImage {
        let sourceSize = image.size
        let longestSide = max(sourceSize.width, sourceSize.height)
        let scale = min(1, maximumImageDimension / max(longestSide, 1))
        let targetSize = CGSize(
            width: max(1, sourceSize.width * scale),
            height: max(1, sourceSize.height * scale)
        )

        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = 1

        let normalizedImage = UIGraphicsImageRenderer(size: targetSize, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }

        guard
            let jpegData = normalizedImage.jpegData(compressionQuality: 0.86),
            let compressedImage = UIImage(data: jpegData)
        else {
            return normalizedImage
        }

        return compressedImage
    }

    private static func aspectFit(_ imageSize: CGSize, inside bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return bounds
        }

        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        return CGRect(
            x: bounds.midX - fittedSize.width / 2,
            y: bounds.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    private static func removeOlderGeneratedPDFs(
        in directory: URL,
        keeping currentFileURL: URL,
        fileManager: FileManager
    ) {
        guard let files = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        for fileURL in files where fileURL != currentFileURL {
            guard
                fileURL.pathExtension.lowercased() == "pdf",
                fileURL.lastPathComponent.hasPrefix("Send-It-")
            else {
                continue
            }

            try? fileManager.removeItem(at: fileURL)
        }
    }
}
