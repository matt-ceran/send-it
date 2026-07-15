import XCTest

final class SendItUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsOnePrimaryScanAction() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["app-title"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["scan-assignment-button"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["scan-card"].exists)
        XCTAssertFalse(app.buttons["airdrop-pdf-button"].exists)
    }

    func testReadyStateReplacesScanActionWithAirDropAction() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-ready")
        app.launch()

        XCTAssertTrue(
            app.descendants(matching: .any)["pdf-ready-card"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(app.buttons["airdrop-pdf-button"].exists)
        XCTAssertTrue(app.buttons["scan-another-button"].exists)
        XCTAssertFalse(app.buttons["scan-assignment-button"].exists)
    }

    func testAirDropActionPresentsTheSystemShareSheet() {
        let app = XCUIApplication()
        app.launchArguments.append("-ui-testing-ready")
        app.launch()

        let airDropButton = app.buttons["airdrop-pdf-button"]
        XCTAssertTrue(airDropButton.waitForExistence(timeout: 5))
        airDropButton.tap()

        let shareSheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 5))

        let sharedPDFMetadata = app.otherElements["LP.CaptionBar.BottomCaption"]
        XCTAssertTrue(sharedPDFMetadata.waitForExistence(timeout: 5))
        XCTAssertTrue(
            sharedPDFMetadata.label.contains("PDF Document"),
            "Expected a PDF attachment, got: \(String(reflecting: sharedPDFMetadata.label))"
        )
    }
}
