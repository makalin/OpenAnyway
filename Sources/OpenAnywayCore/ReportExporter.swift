import Foundation

public enum ReportExporter {
    public static func jsonData(for results: [BatchOperationResult]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(results)
    }

    public static func csvString(for results: [BatchOperationResult]) -> String {
        var rows = [
            ["name", "bundle_id", "version", "build", "status", "success", "message", "path"]
        ]

        rows += results.map { result in
            [
                result.inspection?.metadata.name ?? "",
                result.inspection?.metadata.bundleIdentifier ?? "",
                result.inspection?.metadata.version ?? "",
                result.inspection?.metadata.build ?? "",
                result.inspection?.quarantine.label ?? "",
                result.success ? "true" : "false",
                result.message,
                result.path
            ]
        }

        return rows.map { row in
            row.map(escapeCSVField).joined(separator: ",")
        }
        .joined(separator: "\n") + "\n"
    }

    private static func escapeCSVField(_ value: String) -> String {
        let needsQuoting = value.contains(",") || value.contains("\"") || value.contains("\n")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuoting ? "\"\(escaped)\"" : escaped
    }
}
