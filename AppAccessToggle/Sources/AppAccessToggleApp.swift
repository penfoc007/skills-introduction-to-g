import SwiftUI

@main
struct AppAccessToggleApp: App {
    @StateObject private var screenTimeManager = ScreenTimeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(screenTimeManager)
        }
    }
}
