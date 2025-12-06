import SwiftUI

@main
struct FileActionsViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var showMainWindow: Bool = false

    var body: some Scene {
        WindowGroup {
            SwitchedWindow(showMainWindow: $showMainWindow)
        }
        .windowResizability(.contentSize)
    }
}

