import Foundation
import OpenAnywayCore

enum CLIError: LocalizedError {
    case missingCommand
    case missingPath
    case unknownCommand(String)
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingCommand:
            "Missing command."
        case .missingPath:
            "Provide at least one .app path."
        case let .unknownCommand(command):
            "Unknown command: \(command)"
        case let .exportFailed(message):
            message
        }
    }
}

struct OpenAnywayCLI {
    private let workflow = TrustedAppWorkflow()

    func run(arguments: [String]) -> Int32 {
        do {
            try execute(arguments: Array(arguments.dropFirst()))
            return 0
        } catch {
            fputs("Error: \(error.localizedDescription)\n\n", stderr)
            printUsage()
            return 1
        }
    }

    private func execute(arguments: [String]) throws {
        guard let command = arguments.first else {
            throw CLIError.missingCommand
        }

        let rest = Array(arguments.dropFirst())

        switch command {
        case "inspect":
            let paths = try appPaths(from: rest)
            printResults(workflow.inspectBatch(paths))
        case "trust":
            let paths = try appPaths(from: rest)
            printResults(workflow.trustBatch(paths))
        case "export-json":
            let paths = try appPaths(from: rest)
            let data = try ReportExporter.jsonData(for: workflow.inspectBatch(paths))
            guard let output = String(data: data, encoding: .utf8) else {
                throw CLIError.exportFailed("Could not encode JSON output.")
            }
            print(output)
        case "export-csv":
            let paths = try appPaths(from: rest)
            print(ReportExporter.csvString(for: workflow.inspectBatch(paths)), terminator: "")
        case "help", "--help", "-h":
            printUsage()
        default:
            throw CLIError.unknownCommand(command)
        }
    }

    private func appPaths(from arguments: [String]) throws -> [URL] {
        let paths = arguments.filter { !$0.hasPrefix("-") }
        guard !paths.isEmpty else {
            throw CLIError.missingPath
        }

        return paths.map { URL(fileURLWithPath: $0) }
    }

    private func printResults(_ results: [BatchOperationResult]) {
        for result in results {
            let marker = result.success ? "OK" : "FAIL"
            let name = result.inspection?.metadata.name ?? URL(fileURLWithPath: result.path).lastPathComponent
            print("[\(marker)] \(name)")
            print("  Path: \(result.path)")
            print("  Status: \(result.message)")

            if let metadata = result.inspection?.metadata {
                if let bundleIdentifier = metadata.bundleIdentifier {
                    print("  Bundle ID: \(bundleIdentifier)")
                }
                if let version = metadata.version {
                    print("  Version: \(version)")
                }
                if let build = metadata.build {
                    print("  Build: \(build)")
                }
            }
        }
    }

    private func printUsage() {
        print(
            """
            OpenAnyway CLI

            Usage:
              openanyway inspect /path/to/App.app [...]
              openanyway trust /path/to/App.app [...]
              openanyway export-json /path/to/App.app [...]
              openanyway export-csv /path/to/App.app [...]

            Commands:
              inspect      Validate apps and show quarantine metadata
              trust        Remove quarantine recursively, then inspect again
              export-json  Print inspection results as JSON
              export-csv   Print inspection results as CSV
            """
        )
    }
}

exit(OpenAnywayCLI().run(arguments: CommandLine.arguments))
