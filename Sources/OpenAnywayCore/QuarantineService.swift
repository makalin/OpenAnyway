import Foundation

public enum QuarantineStatus: Equatable, Sendable {
    case quarantined(String)
    case notQuarantined
}

public enum QuarantineServiceError: LocalizedError, Equatable {
    case commandFailed(command: String, status: Int32, output: String)
    case invalidOutput

    public var errorDescription: String? {
        switch self {
        case let .commandFailed(command, status, output):
            let detail = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return detail.isEmpty
                ? "\(command) failed with exit status \(status)."
                : "\(command) failed with exit status \(status): \(detail)"
        case .invalidOutput:
            return "The system command returned unreadable output."
        }
    }
}

public protocol CommandRunning {
    func run(_ executable: URL, arguments: [String]) throws -> CommandResult
}

public struct CommandResult: Equatable {
    public let status: Int32
    public let output: String

    public init(status: Int32, output: String) {
        self.status = status
        self.output = output
    }
}

public struct ProcessCommandRunner: CommandRunning {
    public init() {}

    public func run(_ executable: URL, arguments: [String]) throws -> CommandResult {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            throw QuarantineServiceError.invalidOutput
        }

        return CommandResult(status: process.terminationStatus, output: output)
    }
}

public struct QuarantineService {
    public static let xattrURL = URL(fileURLWithPath: "/usr/bin/xattr")

    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func status(for appURL: URL) throws -> QuarantineStatus {
        let result = try runner.run(Self.xattrURL, arguments: ["-p", "com.apple.quarantine", appURL.path])

        if result.status == 0 {
            return .quarantined(result.output.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let output = result.output.lowercased()
        if result.status == 1,
           output.contains("no such xattr") || output.contains("no such file") {
            return .notQuarantined
        }

        throw QuarantineServiceError.commandFailed(
            command: "xattr -p com.apple.quarantine",
            status: result.status,
            output: result.output
        )
    }

    public func removeQuarantine(from appURL: URL) throws {
        let result = try runner.run(Self.xattrURL, arguments: ["-dr", "com.apple.quarantine", appURL.path])
        guard result.status == 0 else {
            throw QuarantineServiceError.commandFailed(
                command: "xattr -dr com.apple.quarantine",
                status: result.status,
                output: result.output
            )
        }
    }
}
