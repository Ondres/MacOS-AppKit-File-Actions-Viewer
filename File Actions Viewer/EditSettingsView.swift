import SwiftUI
import AppKit

struct EditSettingsView: View {
    @Binding var isOpen: Bool
    @ObservedObject var settings: SettingsModel
    var ipcManager: IPCManager
    var body: some View {
        VStack {
            Text("Monitor settings")
                .font(.title)
                .padding(.bottom, 20)

            Toggle("Monitor file opening/closing", isOn: $settings.trackOpenClose)
                .padding(.bottom, 10)

            Toggle("Monitor file moving/renaming", isOn: $settings.trackRenameEdit)
                .padding(.bottom, 10)

            Toggle("Monitor file unlinking", isOn: $settings.trackMoveDelete)
                .padding(.bottom, 20)

            Button("Ok") {
                isOpen = false
            }
            .buttonStyle(MainButtonStyle())
        }
        .padding(20)
        .background(Color.blue)
        .cornerRadius(10)
    }
}
