import Combine
import FamilyControls
import ManagedSettings

/// Owns the Screen Time authorization flow and drives the shield that
/// blocks/restores access to the selected apps and categories.
@MainActor
final class ScreenTimeManager: ObservableObject {

    @Published private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    @Published var selection: FamilyActivitySelection {
        didSet {
            SelectionStore.saveSelection(selection)
            applyShieldState()
        }
    }

    @Published private(set) var isAccessEnabled: Bool {
        didSet { SelectionStore.saveAccessEnabled(isAccessEnabled) }
    }

    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared

    var isAuthorized: Bool { authorizationStatus == .approved }

    init() {
        selection = SelectionStore.loadSelection()
        isAccessEnabled = SelectionStore.loadAccessEnabled()
        authorizationStatus = center.authorizationStatus
        applyShieldState()
    }

    /// Presents the system's Screen Time consent sheet. Access can only be
    /// toggled once this succeeds and `authorizationStatus` becomes `.approved`.
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(for: .individual)
        } catch {
            // User declined or authorization otherwise failed; fall through
            // and pick up whatever status the system reports below.
        }
        authorizationStatus = center.authorizationStatus
        applyShieldState()
    }

    func setAccessEnabled(_ enabled: Bool) {
        isAccessEnabled = enabled
        applyShieldState()
    }

    /// Applies or lifts the shield to match `isAccessEnabled` and the
    /// current selection. Safe to call repeatedly.
    private func applyShieldState() {
        guard isAuthorized else { return }

        guard !isAccessEnabled else {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            return
        }

        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        // NOTE: verify `.specific(_:except:)` against the current SDK in Xcode —
        // Apple has adjusted this API's shape across iOS releases.
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens, except: [])
    }
}
