import SwiftUI
import AppKit

struct ContentView: View {
    private let ipcManager = IPCManager()
    @State private var logText: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                Button("Add/Remove Files Opening event observer") {
                    callAddOrRemoveObserver(key: Constants.OPEN_KEY)
                }
                
                Button("Add/Remove Files Moving event observer") {
                    callAddOrRemoveObserver(key: Constants.MOVE_KEY)
                }
                
                Button("Add/Remove Files Unlinking event observer") {
                    callAddOrRemoveObserver(key: Constants.UNLINK_KEY)
                }
            }
            .padding()
            
            VStack {
                TextEditor(text: $logText)
                    .padding()
                    .frame(minWidth: 400, minHeight: 400)
            }
        }
        .frame(width: 800, height: 600)
        .padding()
    }
    
    private func callAddOrRemoveObserver(key: String) {
        addOrRemoveObserver(key: key, shouldBeSubscribedOnEvent: &Constants.configuration[key]!.1)
    }
    
    private func addOrRemoveObserver(key: String, shouldBeSubscribedOnEvent: inout Bool) {
        shouldBeSubscribedOnEvent = !shouldBeSubscribedOnEvent
        ipcManager.sendMessage("\(key) \(shouldBeSubscribedOnEvent)")
    }
}
