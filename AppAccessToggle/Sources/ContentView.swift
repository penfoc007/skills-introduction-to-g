import FamilyControls
import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var screenTimeManager: ScreenTimeManager
    @State private var isPickerPresented = false

    private var hasSelection: Bool {
        !screenTimeManager.selection.applicationTokens.isEmpty
            || !screenTimeManager.selection.categoryTokens.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    statusHeader
                }

                if screenTimeManager.isAuthorized {
                    accessSection
                    managedAppsSection
                } else {
                    permissionSection
                }
            }
            .navigationTitle("Access Toggle")
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $screenTimeManager.selection)
            .task {
                if screenTimeManager.authorizationStatus == .notDetermined {
                    await screenTimeManager.requestAuthorization()
                }
            }
        }
    }

    private var statusHeader: some View {
        HStack {
            Image(systemName: screenTimeManager.isAccessEnabled ? "checkmark.shield.fill" : "hand.raised.fill")
                .foregroundStyle(screenTimeManager.isAccessEnabled ? .green : .red)
                .font(.title2)
            VStack(alignment: .leading) {
                Text(screenTimeManager.isAccessEnabled ? "Access is ON" : "Access is OFF")
                    .font(.headline)
                Text(authorizationDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var accessSection: some View {
        Section("Access") {
            Toggle(isOn: Binding(
                get: { screenTimeManager.isAccessEnabled },
                set: { screenTimeManager.setAccessEnabled($0) }
            )) {
                Text(screenTimeManager.isAccessEnabled ? "Access Allowed" : "Access Blocked")
            }
            .tint(.green)
        }
    }

    private var managedAppsSection: some View {
        Section("Managed Apps") {
            Button {
                isPickerPresented = true
            } label: {
                Label("Choose Apps & Categories", systemImage: "square.grid.2x2")
            }

            if hasSelection {
                ForEach(Array(screenTimeManager.selection.applicationTokens), id: \.self) { token in
                    Label(token)
                }
                ForEach(Array(screenTimeManager.selection.categoryTokens), id: \.self) { token in
                    Label(token)
                }
            } else {
                Text("No apps selected yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var permissionSection: some View {
        Section {
            if screenTimeManager.authorizationStatus == .denied {
                Text("Screen Time permission was denied. Enable it in Settings to use this app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } else {
                Button("Grant Screen Time Permission") {
                    Task { await screenTimeManager.requestAuthorization() }
                }
                Text("This app uses Apple's Screen Time API to manage access to other apps. Approve the system prompt to continue.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var authorizationDescription: String {
        switch screenTimeManager.authorizationStatus {
        case .notDetermined: return "Screen Time permission not yet requested"
        case .denied: return "Screen Time permission denied"
        case .approved: return "Screen Time permission granted"
        @unknown default: return "Unknown permission state"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ScreenTimeManager())
}
