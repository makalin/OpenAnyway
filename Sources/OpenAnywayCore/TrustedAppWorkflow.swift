import Foundation

public enum TrustedAppWorkflowError: LocalizedError {
    case validation(AppBundleValidationError)
    case quarantine(Error)

    public var errorDescription: String? {
        switch self {
        case let .validation(error):
            error.errorDescription
        case let .quarantine(error):
            error.localizedDescription
        }
    }
}

public struct TrustedAppWorkflow {
    private let validator: AppBundleValidator
    private let quarantineService: QuarantineService
    private let metadataReader: AppMetadataReader

    public init(
        validator: AppBundleValidator = AppBundleValidator(),
        quarantineService: QuarantineService = QuarantineService(),
        metadataReader: AppMetadataReader = AppMetadataReader()
    ) {
        self.validator = validator
        self.quarantineService = quarantineService
        self.metadataReader = metadataReader
    }

    public func inspect(_ appURL: URL) throws -> QuarantineStatus {
        do {
            try validator.validate(appURL)
            return try quarantineService.status(for: appURL)
        } catch let error as AppBundleValidationError {
            throw TrustedAppWorkflowError.validation(error)
        } catch {
            throw TrustedAppWorkflowError.quarantine(error)
        }
    }

    public func trust(_ appURL: URL) throws {
        do {
            try validator.validate(appURL)
            try quarantineService.removeQuarantine(from: appURL)
        } catch let error as AppBundleValidationError {
            throw TrustedAppWorkflowError.validation(error)
        } catch {
            throw TrustedAppWorkflowError.quarantine(error)
        }
    }

    public func inspectDetails(_ appURL: URL) throws -> AppInspection {
        do {
            try validator.validate(appURL)
            let status = try quarantineService.status(for: appURL)
            return AppInspection(
                metadata: metadataReader.read(from: appURL),
                quarantine: QuarantineSummary(status)
            )
        } catch let error as AppBundleValidationError {
            throw TrustedAppWorkflowError.validation(error)
        } catch {
            throw TrustedAppWorkflowError.quarantine(error)
        }
    }

    public func inspectBatch(_ appURLs: [URL]) -> [BatchOperationResult] {
        appURLs.map { url in
            do {
                let inspection = try inspectDetails(url)
                return BatchOperationResult(
                    path: url.path,
                    success: true,
                    message: inspection.quarantine.label,
                    inspection: inspection
                )
            } catch {
                return BatchOperationResult(
                    path: url.path,
                    success: false,
                    message: error.localizedDescription,
                    inspection: nil
                )
            }
        }
    }

    public func trustBatch(_ appURLs: [URL]) -> [BatchOperationResult] {
        appURLs.map { url in
            do {
                try trust(url)
                let inspection = try inspectDetails(url)
                return BatchOperationResult(
                    path: url.path,
                    success: true,
                    message: "Quarantine removed",
                    inspection: inspection
                )
            } catch {
                return BatchOperationResult(
                    path: url.path,
                    success: false,
                    message: error.localizedDescription,
                    inspection: nil
                )
            }
        }
    }
}
