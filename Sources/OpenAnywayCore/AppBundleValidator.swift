import Foundation

public enum AppBundleValidationError: LocalizedError, Equatable {
    case pathIsNotAppBundle
    case itemDoesNotExist
    case itemIsNotDirectory
    case missingInfoPlist

    public var errorDescription: String? {
        switch self {
        case .pathIsNotAppBundle:
            "Select a macOS application bundle ending in .app."
        case .itemDoesNotExist:
            "The selected item does not exist."
        case .itemIsNotDirectory:
            "The selected item is not an application bundle."
        case .missingInfoPlist:
            "The selected .app bundle is missing Contents/Info.plist."
        }
    }
}

public struct AppBundleValidator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func validate(_ url: URL) throws {
        guard url.pathExtension.lowercased() == "app" else {
            throw AppBundleValidationError.pathIsNotAppBundle
        }

        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw AppBundleValidationError.itemDoesNotExist
        }

        guard isDirectory.boolValue else {
            throw AppBundleValidationError.itemIsNotDirectory
        }

        let infoPlistURL = url
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Info.plist", isDirectory: false)

        guard fileManager.fileExists(atPath: infoPlistURL.path) else {
            throw AppBundleValidationError.missingInfoPlist
        }
    }
}
