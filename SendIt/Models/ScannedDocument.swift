import UIKit

struct ScannedDocument: Identifiable {
    let id = UUID()
    let fileURL: URL
    let pageCount: Int
    let previewImage: UIImage
    let createdAt: Date
}
