import Foundation
import Testing
@testable import OpenAnywayCore

@Suite("App metadata reader")
struct AppMetadataReaderTests {
    @Test("reads useful Info.plist fields")
    func readsInfoPlistFields() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let appURL = root.appendingPathComponent("Example.app", isDirectory: true)
        let contentsURL = appURL.appendingPathComponent("Contents", isDirectory: true)
        let infoURL = contentsURL.appendingPathComponent("Info.plist")
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        let plist: [String: String] = [
            "CFBundleName": "Example",
            "CFBundleIdentifier": "dev.openanyway.example",
            "CFBundleShortVersionString": "1.2.3",
            "CFBundleVersion": "123",
            "CFBundleExecutable": "Example"
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: infoURL)

        let metadata = AppMetadataReader().read(from: appURL)

        #expect(metadata.name == "Example")
        #expect(metadata.bundleIdentifier == "dev.openanyway.example")
        #expect(metadata.version == "1.2.3")
        #expect(metadata.build == "123")
        #expect(metadata.executableName == "Example")
    }
}
