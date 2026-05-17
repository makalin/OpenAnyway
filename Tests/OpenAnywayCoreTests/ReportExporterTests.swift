import Foundation
import Testing
@testable import OpenAnywayCore

@Suite("Report exporter")
struct ReportExporterTests {
    @Test("exports CSV with quoted fields")
    func exportsCSV() {
        let result = BatchOperationResult(
            path: "/Applications/Example.app",
            success: false,
            message: "Failed, because \"quoted\"",
            inspection: AppInspection(
                metadata: AppMetadata(
                    name: "Example",
                    bundleIdentifier: "dev.openanyway.example",
                    version: "1.0",
                    build: "100",
                    executableName: "Example",
                    path: "/Applications/Example.app"
                ),
                quarantine: .quarantined("0081;Safari")
            )
        )

        let csv = ReportExporter.csvString(for: [result])

        #expect(csv.contains("\"Failed, because \"\"quoted\"\"\""))
        #expect(csv.contains("dev.openanyway.example"))
    }

    @Test("exports JSON")
    func exportsJSON() throws {
        let result = BatchOperationResult(
            path: "/Applications/Example.app",
            success: true,
            message: "Not quarantined",
            inspection: nil
        )

        let data = try ReportExporter.jsonData(for: [result])
        let text = try #require(String(data: data, encoding: .utf8))

        #expect(text.contains("\"success\" : true"))
        #expect(text.contains("/Applications/Example.app"))
    }
}
