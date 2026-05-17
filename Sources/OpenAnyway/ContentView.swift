import AppKit
import OpenAnywayCore
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                totalCount: viewModel.records.count,
                quarantinedCount: viewModel.quarantinedCount,
                onBrowse: viewModel.browseForApps,
                onRefresh: viewModel.refreshAll,
                onTrustAll: viewModel.trustAllQuarantined,
                onExportCSV: viewModel.exportCSV,
                onExportJSON: viewModel.exportJSON,
                canOperate: viewModel.canOperate
            )

            HSplitView {
                AppListView(
                    records: viewModel.records,
                    selectedRecordID: $viewModel.selectedRecordID
                )
                .frame(minWidth: 260, idealWidth: 310)

                DetailWorkspaceView(
                    selectedRecord: viewModel.selectedRecord,
                    isTargeted: viewModel.isDropTargeted,
                    statusText: viewModel.statusText,
                    statusKind: viewModel.statusKind,
                    onBrowse: viewModel.browseForApps,
                    onOpen: viewModel.openSelectedApp,
                    onReveal: viewModel.revealSelectedInFinder,
                    onTrust: viewModel.trustSelectedApp,
                    onDropTargetChanged: viewModel.setDropTargeted,
                    onDrop: viewModel.handleDrop
                )
                .frame(minWidth: 470)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("OpenAnyway", isPresented: $viewModel.isShowingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

private struct HeaderView: View {
    let totalCount: Int
    let quarantinedCount: Int
    let onBrowse: () -> Void
    let onRefresh: () -> Void
    let onTrustAll: () -> Void
    let onExportCSV: () -> Void
    let onExportJSON: () -> Void
    let canOperate: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text("OpenAnyway")
                    .font(.title2.weight(.semibold))
                Text("\(totalCount) apps loaded · \(quarantinedCount) quarantined")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onBrowse) {
                Label("Add Apps", systemImage: "plus.app")
            }

            Button(action: onRefresh) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(!canOperate)

            Button(action: onTrustAll) {
                Label("Trust All", systemImage: "checkmark.shield")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canOperate || quarantinedCount == 0)

            Menu {
                Button("CSV", action: onExportCSV)
                Button("JSON", action: onExportJSON)
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(!canOperate)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.regularMaterial)
    }
}

private struct AppListView: View {
    let records: [AppRecord]
    @Binding var selectedRecordID: AppRecord.ID?

    var body: some View {
        List(selection: $selectedRecordID) {
            ForEach(records) { record in
                HStack(spacing: 10) {
                    Image(systemName: record.isQuarantined ? "exclamationmark.shield" : "checkmark.shield")
                        .foregroundStyle(record.isQuarantined ? .orange : .green)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.name)
                            .font(.callout.weight(.semibold))
                            .lineLimit(1)
                        Text(record.result.inspection?.metadata.bundleIdentifier ?? record.url.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 4)
                .tag(record.id)
            }
        }
        .overlay {
            if records.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No apps loaded")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct DetailWorkspaceView: View {
    let selectedRecord: AppRecord?
    let isTargeted: Bool
    let statusText: String
    let statusKind: StatusKind
    let onBrowse: () -> Void
    let onOpen: () -> Void
    let onReveal: () -> Void
    let onTrust: () -> Void
    let onDropTargetChanged: (Bool) -> Void
    let onDrop: ([NSItemProvider]) -> Bool

    var body: some View {
        VStack(spacing: 18) {
            DropTargetHeader(
                selectedRecord: selectedRecord,
                isTargeted: isTargeted,
                statusText: statusText,
                statusKind: statusKind,
                onBrowse: onBrowse
            )

            if let selectedRecord {
                MetadataGrid(record: selectedRecord)

                HStack(spacing: 10) {
                    Button(action: onTrust) {
                        Label("Remove Quarantine", systemImage: "checkmark.shield")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!selectedRecord.isQuarantined)

                    Button(action: onOpen) {
                        Label("Open", systemImage: "arrow.up.forward.app")
                    }

                    Button(action: onReveal) {
                        Label("Reveal", systemImage: "finder")
                    }

                    Spacer()
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onDrop(
            of: [.fileURL],
            isTargeted: Binding(
                get: { isTargeted },
                set: { newValue in onDropTargetChanged(newValue) }
            ),
            perform: onDrop
        )
    }
}

private struct DropTargetHeader: View {
    let selectedRecord: AppRecord?
    let isTargeted: Bool
    let statusText: String
    let statusKind: StatusKind
    let onBrowse: () -> Void

    var body: some View {
        VStack(spacing: 13) {
            Image(systemName: selectedRecord == nil ? "app.dashed" : "app.badge.checkmark")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(isTargeted ? Color.accentColor : statusKind.color)
                .frame(width: 72, height: 72)

            Text(selectedRecord?.name ?? "Drop one or more trusted .app files here")
                .font(.title3.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(statusText)
                .font(.callout)
                .foregroundStyle(statusKind.color)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: 560)

            if selectedRecord == nil {
                Button(action: onBrowse) {
                    Label("Choose Apps", systemImage: "folder")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isTargeted ? Color.accentColor.opacity(0.10) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
        )
    }
}

private struct MetadataGrid: View {
    let record: AppRecord

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
            metadataRow("Status", record.result.inspection?.quarantine.label ?? record.status)
            metadataRow("Bundle ID", record.result.inspection?.metadata.bundleIdentifier ?? "Unknown")
            metadataRow("Version", record.result.inspection?.metadata.version ?? "Unknown")
            metadataRow("Build", record.result.inspection?.metadata.build ?? "Unknown")
            metadataRow("Executable", record.result.inspection?.metadata.executableName ?? "Unknown")
            metadataRow("Path", record.url.path)
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metadataRow(_ title: String, _ value: String) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
                .lineLimit(2)
        }
    }
}

enum StatusKind {
    case idle
    case success
    case warning
    case failure

    var color: Color {
        switch self {
        case .idle:
            .secondary
        case .success:
            .green
        case .warning:
            .orange
        case .failure:
            .red
        }
    }
}
