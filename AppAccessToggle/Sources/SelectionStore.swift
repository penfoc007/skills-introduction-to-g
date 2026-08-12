import Foundation
import FamilyControls

/// Persists which apps/categories are managed and whether access is
/// currently switched on, so both survive an app relaunch.
enum SelectionStore {
    private static let defaults = UserDefaults.standard
    private static let selectionKey = "com.appaccesstoggle.selection"
    private static let accessEnabledKey = "com.appaccesstoggle.isAccessEnabled"

    static func saveSelection(_ selection: FamilyActivitySelection) {
        guard let data = try? PropertyListEncoder().encode(selection) else { return }
        defaults.set(data, forKey: selectionKey)
    }

    static func loadSelection() -> FamilyActivitySelection {
        guard
            let data = defaults.data(forKey: selectionKey),
            let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        else {
            return FamilyActivitySelection()
        }
        return selection
    }

    static func saveAccessEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: accessEnabledKey)
    }

    static func loadAccessEnabled() -> Bool {
        // Default to true (access allowed) the first time the app ever runs.
        defaults.object(forKey: accessEnabledKey) == nil ? true : defaults.bool(forKey: accessEnabledKey)
    }
}
