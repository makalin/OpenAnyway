import Foundation

public struct AppMetadata: Codable, Equatable, Sendable {
    public let name: String
    public let bundleIdentifier: String?
    public let version: String?
    public let build: String?
    public let executableName: String?
    public let path: String

    public init(
        name: String,
        bundleIdentifier: String?,
        version: String?,
        build: String?,
        executableName: String?,
        path: String
    ) {
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.build = build
        self.executableName = executableName
        self.path = path
    }
}

public struct AppMetadataReader {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func read(from appURL: URL) -> AppMetadata {
        let infoURL = appURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Info.plist", isDirectory: false)

        let dictionary = NSDictionary(contentsOf: infoURL) as? [String: Any] ?? [:]
        let displayName = stringValue(dictionary, keys: ["CFBundleDisplayName", "CFBundleName"])

        return AppMetadata(
            name: displayName ?? appURL.deletingPathExtension().lastPathComponent,
            bundleIdentifier: stringValue(dictionary, keys: ["CFBundleIdentifier"]),
            version: stringValue(dictionary, keys: ["CFBundleShortVersionString"]),
            build: stringValue(dictionary, keys: ["CFBundleVersion"]),
            executableName: stringValue(dictionary, keys: ["CFBundleExecutable"]),
            path: appURL.path
        )
    }

    private func stringValue(_ dictionary: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dictionary[key] as? String, !value.isEmpty {
                return value
            }
        }

        return nil
    }
}
