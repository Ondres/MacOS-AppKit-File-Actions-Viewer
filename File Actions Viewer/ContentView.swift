import SwiftUI
import AppKit

struct ContentView: View {
    @State public var files:[FullFileInfo] = []
    @State private var isEditSettingsViewPresented = false
    @State public var settings = SettingsModel(trackOpenClose: false, trackRenameEdit: false, trackMoveDelete: false)
    private let ipcManager = IPCManager()
    

    var body: some View {
        ZStack {
            Color(.white)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Spacer()
                
                HStack(spacing: 200) {
                    VStack(spacing: 400) {
                        Button("Add file") {
                            if let filePath = openFilePicker() {
                                files.append(FullFileInfo(settings: SettingsModel(trackOpenClose: false, trackRenameEdit: false,trackMoveDelete: false), pathToFile: filePath))
                                
                                ipcManager.sendMessage("\(filePath) \(false) \(false) \(false)")
                            }
                        }
                        .buttonStyle(MainButtonStyle())
                        .frame(width: 100)
                        
                        Spacer()
                    }.sheet(isPresented: $isEditSettingsViewPresented) {
                        EditSettingsView(isOpen: $isEditSettingsViewPresented, settings: settings, ipcManager: ipcManager)
                    }
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(files.indices, id: \.self) { index in
                                FileWidgetView(
                                filePath: files[index].pathToFile,
                                onDelete: { deleteFile(at: index) },
                                onEdit: { editFile(at: index) })
                            .frame(width: 500)
                            .onTapGesture {
                            }
                            }
                        }
                    }
                    .frame(maxWidth: 800)
                }
                
                Spacer()
            }
            .frame(width: 800, height: 600)
        }
    }
    
    private func openFilePicker() -> String? {
        let dialog = NSOpenPanel()
        
        dialog.title = "Choose file or directory"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = true
        dialog.allowsMultipleSelection = false
        
        if dialog.runModal() == .OK {
            let result = dialog.url
            return result?.path
        } else {
            return nil
        }
    }
    
    private func deleteFile(at index: Int) {
        files.remove(at: index)
    }
    
    private func editFile(at index: Int) {
        settings = files[index].settings
        isEditSettingsViewPresented.toggle()
    }
}
