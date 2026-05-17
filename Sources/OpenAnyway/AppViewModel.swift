import AppKit
import Foundation
import OpenAnywayCore
import SwiftUI
import UniformTypeIdentifiers

struct AppRecord: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    var result: BatchOperationResult
    var lastUpdated: Date

    var name: String {
        result.inspection?.metadata.name ?? url.lastPathComponent
    }

    var status: String {
        result.message
    }

    var isQuarantined: Bool {
        if case .quarantined = result.inspection?.quarantine {
            return true
        }
        return false
    }
}

private actor DroppedURLStore {
    private var urls: [URL] = []

    func append(_ url: URL) {
        urls.append(url)
    }

    func all() -> [URL] {
        urls
    }
}

@MainActor
final class AppViewModel: ObservableObject {
    @Published var records: [AppRecord] = []
    @Published var selectedRecordID: AppRecord.ID?
    @Published var statusText = "Drop apps here, choose apps, or use the CLI for scripted workflows."
    @Published var statusKind: StatusKind = .idle
    @Published var isDropTargeted = false
    @Published var isShowingAlert = false
    @Published var alertMessage = ""

    private let workflow = TrustedAppWorkflow()

    var selectedRecord: AppRecord? {
        guard let selectedRecordID else { return records.first }
        return records.first { $0.id == selectedRecordID }
    }

    var selectedApp: URL? {
        selectedRecord?.url
    }

    var canOperate: Bool {
        !records.isEmpty
    }

    var quarantinedCount: Int {
        records.filter(\.isQuarantined).count
    }

    func setDropTargeted(_ value: Bool) {
        isDropTargeted = value
    }

    func browseForApps() {
        let panel = NSOpenPanel()
        panel.title = "Choose applications"
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK else {
            return
        }

        addApps(panel.urls)
    }

    func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        let fileProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !fileProviders.isEmpty else {
            showFailure("Drop one or more macOS .app bundles.")
            return false
        }

        let group = DispatchGroup()
        let store = DroppedURLStore()

        for provider in fileProviders {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                let url = Self.fileURL(from: item)
                Task {
                    if let url {
                        await store.append(url)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                let urls = await store.all()
                if urls.isEmpty {
                    self.showFailure("The dropped items did not include readable file URLs.")
                } else {
                    self.addApps(urls)
                }
            }
        }

        return true
    }

    func refreshAll() {
        guard canOperate else { return }
        addApps(records.map(\.url), replacingExisting: true)
    }

    func trustSelectedApp() {
        guard let selectedRecord else { return }
        updateRecords(with: workflow.trustBatch([selectedRecord.url]))
        statusText = "Processed \(selectedRecord.name)."
        statusKind = .success
    }

    func trustAllQuarantined() {
        let targets = records.filter(\.isQuarantined).map(\.url)
        guard !targets.isEmpty else {
            statusText = "No quarantined apps found."
            statusKind = .success
            return
        }

        updateRecords(with: workflow.trustBatch(targets))
        statusText = "Processed \(targets.count) quarantined app\(targets.count == 1 ? "" : "s")."
        statusKind = .success
    }

    func openSelectedApp() {
        guard let selectedApp else { return }

        NSWorkspace.shared.openApplication(
            at: selectedApp,
            configuration: NSWorkspace.OpenConfiguration()
        ) { [weak self] _, error in
            guard let error else { return }
            Task { @MainActor in
                self?.showFailure(error.localizedDescription)
            }
        }
    }

    func revealSelectedInFinder() {
        guard let selectedApp else { return }
        NSWorkspace.shared.activateFileViewerSelecting([selectedApp])
    }

    func exportCSV() {
        export(extension: "csv", contentType: .commaSeparatedText) { results in
            Data(ReportExporter.csvString(for: results).utf8)
        }
    }

    func exportJSON() {
        export(extension: "json", contentType: .json) { results in
            try ReportExporter.jsonData(for: results)
        }
    }

    private func addApps(_ urls: [URL], replacingExisting: Bool = false) {
        let appURLs = uniqueAppURLs(urls)
        guard !appURLs.isEmpty else {
            showFailure("Select one or more paths ending in .app.")
            return
        }

        let results = workflow.inspectBatch(appURLs)
        if replacingExisting {
            records.removeAll()
        }
        updateRecords(with: results)

        let failures = results.filter { !$0.success }.count
        statusText = failures == 0
            ? "Loaded \(results.count) app\(results.count == 1 ? "" : "s"). \(quarantinedCount) quarantined."
            : "Loaded \(results.count - failures) app\(results.count - failures == 1 ? "" : "s"); \(failures) failed validation."
        statusKind = failures == 0 ? .success : .warning
    }

    private func updateRecords(with results: [BatchOperationResult]) {
        for result in results {
            let url = URL(fileURLWithPath: result.path)
            if let index = records.firstIndex(where: { $0.url.path == url.path }) {
                records[index].result = result
                records[index].lastUpdated = Date()
            } else {
                records.append(AppRecord(url: url, result: result, lastUpdated: Date()))
            }
        }

        if selectedRecordID == nil || records.first(where: { $0.id == selectedRecordID }) == nil {
            selectedRecordID = records.first?.id
        }
    }

    private func uniqueAppURLs(_ urls: [URL]) -> [URL] {
        var seen = Set<String>()
        return urls.compactMap { url in
            guard url.pathExtension.lowercased() == "app", !seen.contains(url.path) else {
                return nil
            }
            seen.insert(url.path)
            return url
        }
    }

    private func export(
        extension fileExtension: String,
        contentType: UTType,
        makeData: ([BatchOperationResult]) throws -> Data
    ) {
        guard !records.isEmpty else {
            showFailure("There are no apps to export.")
            return
        }

        let panel = NSSavePanel()
        panel.title = "Export OpenAnyway Report"
        panel.allowedContentTypes = [contentType]
        panel.nameFieldStringValue = "OpenAnyway-Report.\(fileExtension)"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let data = try makeData(records.map(\.result))
            try data.write(to: url, options: .atomic)
            statusText = "Exported report to \(url.lastPathComponent)."
            statusKind = .success
        } catch {
            showFailure(error.localizedDescription)
        }
    }

    private func showFailure(_ message: String) {
        statusText = message
        statusKind = .failure
        alertMessage = message
        isShowingAlert = true
    }

    nonisolated private static func fileURL(from item: NSSecureCoding?) -> URL? {
        if let url = item as? URL {
            return url
        }

        if let data = item as? Data,
           let string = String(data: data, encoding: .utf8) {
            return URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        if let string = item as? String {
            return URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return nil
    }
}
