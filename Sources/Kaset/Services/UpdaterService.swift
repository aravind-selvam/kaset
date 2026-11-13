import Foundation
import Sparkle

// MARK: - UpdaterService

/// Manages application updates via Sparkle framework.
///
/// This service wraps Sparkle's `SPUStandardUpdaterController` to provide
/// a SwiftUI-friendly interface for checking and installing updates.
///
/// Usage:
/// ```swift
/// @State private var updaterService = UpdaterService()
///
/// Button(String(localized: "Check for Updates")) {
///     updaterService.checkForUpdates()
/// }
/// .disabled(!updaterService.canCheckForUpdates)
/// ```
@MainActor
@Observable
final class UpdaterService {
    /// The Sparkle updater controller that manages the update lifecycle.
    private let updaterController: SPUStandardUpdaterController
    private let isPersonalBuild: Bool

    /// Whether automatic update checks are enabled.
    ///
    /// When enabled, the app checks for updates on launch and periodically thereafter
    /// (default: every 24 hours, configurable via `SUScheduledCheckInterval` in Info.plist).
    var automaticChecksEnabled: Bool {
        get { !self.isPersonalBuild && self.updaterController.updater.automaticallyChecksForUpdates }
        set {
            if !self.isPersonalBuild {
                self.updaterController.updater.automaticallyChecksForUpdates = newValue
            }
        }
    }

    /// Whether the updater can currently check for updates.
    ///
    /// This is `false` while an update check is already in progress or during installation.
    var canCheckForUpdates: Bool {
        !self.isPersonalBuild && self.updaterController.updater.canCheckForUpdates
    }

    /// The date of the last update check, or `nil` if never checked.
    var lastUpdateCheckDate: Date? {
        self.updaterController.updater.lastUpdateCheckDate
    }

    /// Initializes the updater service and starts the Sparkle updater.
    ///
    /// The updater will automatically check for updates on launch if
    /// `SUEnableAutomaticChecks` is `true` in Info.plist.
    init() {
        let isPersonalBuild = Bundle.main.object(forInfoDictionaryKey: "KasetPersonalBuild") as? Bool == true
        self.isPersonalBuild = isPersonalBuild
        // Initialize Sparkle with default UI and start the updater
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: !isPersonalBuild,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        DiagnosticsLogger.updater.info("UpdaterService initialized")
    }

    /// Manually triggers an update check.
    ///
    /// This shows Sparkle's standard update UI, including:
    /// - "Checking for updates..." progress indicator
    /// - "A new version is available" dialog if an update exists
    /// - "You're up to date" message if no update is available
    func checkForUpdates() {
        guard !self.isPersonalBuild else { return }
        DiagnosticsLogger.updater.info("Manually checking for updates")
        self.updaterController.checkForUpdates(nil)
    }
}
