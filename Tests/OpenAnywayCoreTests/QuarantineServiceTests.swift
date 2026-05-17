import Foundation
import Testing
@testable import OpenAnywayCore

@Suite("Quarantine service")
struct QuarantineServiceTests {
    @Test("reports quarantined apps")
    func reportsQuarantinedApps() throws {
        let runner = StubRunner(result: CommandResult(status: 0, output: "0081;Safari;example;"))
        let service = QuarantineService(runner: runner)

        let status = try service.status(for: URL(fileURLWithPath: "/Applications/Example.app"))

        #expect(status == .quarantined("0081;Safari;example;"))
        #expect(runner.calls == [
            ["-p", "com.apple.quarantine", "/Applications/Example.app"]
        ])
    }

    @Test("reports apps without quarantine attribute")
    func reportsNotQuarantinedApps() throws {
        let runner = StubRunner(result: CommandResult(status: 1, output: "No such xattr: com.apple.quarantine"))
        let service = QuarantineService(runner: runner)

        let status = try service.status(for: URL(fileURLWithPath: "/Applications/Example.app"))

        #expect(status == .notQuarantined)
    }

    @Test("removes quarantine recursively")
    func removesQuarantineRecursively() throws {
        let runner = StubRunner(result: CommandResult(status: 0, output: ""))
        let service = QuarantineService(runner: runner)

        try service.removeQuarantine(from: URL(fileURLWithPath: "/Applications/Example.app"))

        #expect(runner.calls == [
            ["-dr", "com.apple.quarantine", "/Applications/Example.app"]
        ])
    }
}

private final class StubRunner: CommandRunning, @unchecked Sendable {
    private(set) var calls: [[String]] = []
    private let result: CommandResult

    init(result: CommandResult) {
        self.result = result
    }

    func run(_ executable: URL, arguments: [String]) throws -> CommandResult {
        calls.append(arguments)
        return result
    }
}
