import Foundation
import Testing
@testable import OpenAnywayCore

@Suite("App bundle validation")
struct AppBundleValidatorTests {
    @Test("rejects paths without .app extension")
    func rejectsNonAppExtension() throws {
        let validator = AppBundleValidator()
        let url = URL(fileURLWithPath: "/tmp/Example.txt")

        #expect(throws: AppBundleValidationError.pathIsNotAppBundle) {
            try validator.validate(url)
        }
    }

    @Test("accepts minimal app bundle shape")
    func acceptsMinimalAppBundle() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appURL = root.appendingPathComponent("Example.app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        let infoURL = contentsURL.appendingPathComponent("Info.plist")

        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        try Data().write(to: infoURL)
        defer { try? FileManager.default.removeItem(at: root) }

        let validator = AppBundleValidator()
        try validator.validate(appURL)
    }
}
