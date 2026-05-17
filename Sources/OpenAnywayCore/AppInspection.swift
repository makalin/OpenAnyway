import Foundation

public struct AppInspection: Codable, Equatable, Sendable {
    public let metadata: AppMetadata
    public let quarantine: QuarantineSummary
    public let inspectedAt: Date

    public init(metadata: AppMetadata, quarantine: QuarantineSummary, inspectedAt: Date = Date()) {
        self.metadata = metadata
        self.quarantine = quarantine
        self.inspectedAt = inspectedAt
    }
}

public enum QuarantineSummary: Codable, Equatable, Sendable {
    case quarantined(String)
    case notQuarantined

    public var label: String {
        switch self {
        case .quarantined:
            "Quarantined"
        case .notQuarantined:
            "Not quarantined"
        }
    }

    public var rawValue: String {
        switch self {
        case let .quarantined(value):
            value
        case .notQuarantined:
            ""
        }
    }

    public init(_ status: QuarantineStatus) {
        switch status {
        case let .quarantined(value):
            self = .quarantined(value)
        case .notQuarantined:
            self = .notQuarantined
        }
    }
}

public struct BatchOperationResult: Codable, Equatable, Sendable {
    public let path: String
    public let success: Bool
    public let message: String
    public let inspection: AppInspection?

    public init(path: String, success: Bool, message: String, inspection: AppInspection?) {
        self.path = path
        self.success = success
        self.message = message
        self.inspection = inspection
    }
}
