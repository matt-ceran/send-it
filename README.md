<p align="center">
  <img src="Design/SendIt-AppIcon.svg" alt="Send It Signal S app icon" width="128">
</p>

# Send It

Send It is a focused iPhone app for scanning handwritten notebook work and sharing it as a PDF through AirDrop.

The experience is intentionally limited to two primary stages: scan the assignment, then send the generated PDF.

All document processing happens locally on the iPhone.
The app does not require an account, backend, analytics service, or cloud storage.

## How it works

1. Tap **Scan Assignment** and capture one or more notebook pages with Apple's document scanner.
2. Tap **AirDrop PDF** and select the destination Mac from Apple's system share sheet.

Apple requires the recipient to be selected in the system share sheet.
Send It prepares the PDF and opens that sheet with the file already attached.

## Features

- Automatic page detection, cropping, perspective correction, and straightening through VisionKit.
- Multi-page scanning with every captured page combined into one PDF.
- Portrait and landscape PDF pages selected independently for each scan.
- Image normalization and compression to keep assignment PDFs practical to share.
- Timestamped filenames such as `Send-It-2026-07-15-121548.pdf`.
- A native iOS share sheet that supports AirDrop, Files, Mail, Messages, printing, and other installed destinations.
- A simple two-stage SwiftUI interface with accessibility identifiers and clear error states.
- No third-party runtime dependencies.

## Privacy

Scanned pages and generated PDFs remain inside the app's local storage unless the user explicitly shares them.

Send It does not upload documents, collect personal information, or contact a remote server.

The current generated PDF is kept in the app's cache, and older Send It PDFs are removed when a new one is created.

## Requirements

- An iPhone running iOS 17 or later.
- A supported iPhone camera for Apple's document-scanning interface.
- Xcode 26.4 or later for the verified development setup.
- XcodeGen 2.45 or later only when regenerating the Xcode project from `project.yml`.

The scanner cannot capture real camera input in the iOS Simulator.
Use a physical iPhone to verify document capture and nearby AirDrop recipients.

## Getting started

Clone the repository and open the committed Xcode project:

```bash
git clone https://github.com/matt-ceran/send-it.git
cd send-it
open SendIt.xcodeproj
```

In Xcode:

1. Select the `SendIt` target.
2. Open **Signing & Capabilities** and choose your Apple development team.
3. Change the bundle identifier in `project.yml` if your account requires a unique identifier.
4. Select a connected iPhone as the run destination.
5. Press **Run**.

No paid backend or external API configuration is needed.

## Regenerating the project

The committed `SendIt.xcodeproj` is generated from `project.yml` with XcodeGen.

Install XcodeGen and regenerate the project after changing its definition:

```bash
brew install xcodegen
xcodegen generate
```

Application source changes do not require regeneration.

## Project structure

```text
SendIt/
├── Design/
│   └── SendIt-AppIcon.svg
├── SendIt/
│   ├── Assets.xcassets/
│   ├── Models/
│   │   ├── ScannedDocument.swift
│   │   └── SendItViewModel.swift
│   ├── Services/
│   │   └── PDFBuilder.swift
│   ├── Views/
│   │   ├── DocumentScannerView.swift
│   │   └── ShareSheet.swift
│   ├── ContentView.swift
│   └── SendItApp.swift
├── SendItTests/
│   └── PDFBuilderTests.swift
├── SendItUITests/
│   └── SendItUITests.swift
├── SendIt.xcodeproj/
├── project.yml
└── README.md
```

## Architecture

| Component | Responsibility |
| --- | --- |
| `ContentView` | Presents the scan and ready-to-send stages. |
| `DocumentScannerView` | Bridges SwiftUI to `VNDocumentCameraViewController`. |
| `SendItViewModel` | Coordinates PDF creation, document state, and user-facing errors. |
| `PDFBuilder` | Normalizes scanned images and writes the multi-page PDF. |
| `ScannedDocument` | Stores the PDF URL, page count, preview, and creation date. |
| `ShareSheet` | Bridges SwiftUI to Apple's `UIActivityViewController`. |

## Testing

The test suite contains three PDF unit tests and three end-to-end UI tests.

The PDF tests verify multi-page output, landscape page bounds, and empty-scan rejection.
The UI tests verify the initial scan action, the ready-to-send state, and presentation of Apple's share sheet with a PDF attached.

Run the suite from Xcode with **Product > Test**, or from the command line with an installed simulator:

```bash
xcodebuild \
  -project SendIt.xcodeproj \
  -scheme SendIt \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

The current version has been built and all six tests have passed on an iPhone 17 Pro simulator running iOS 26.4.1.

## Current status

Send It is a functional first release with its complete scan-to-PDF-to-share workflow implemented.

The interface, PDF output, and system share-sheet handoff have been verified in the simulator.
Final camera capture and AirDrop transfer should be verified on a physical iPhone before App Store distribution.
