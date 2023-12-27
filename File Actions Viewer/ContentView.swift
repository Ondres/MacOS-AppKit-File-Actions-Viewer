import SwiftUI
import AppKit

class SettingsModel: ObservableObject {
    @Published var trackOpenClose: Bool
    @Published var trackRenameEdit: Bool
    @Published var trackMoveDelete: Bool

    init(trackOpenClose: Bool, trackRenameEdit: Bool, trackMoveDelete: Bool) {
        self.trackOpenClose = trackOpenClose
        self.trackRenameEdit = trackRenameEdit
        self.trackMoveDelete = trackMoveDelete
    }
}

class FullFileInfo: ObservableObject {
    @Published var settings: SettingsModel
    @Published var pathToFile: String

    init(settings: SettingsModel, pathToFile: String) {
        self.settings = settings
        self.pathToFile = pathToFile
    }
}

struct EditSettingsView: View {
    @Binding var isOpen: Bool
    @ObservedObject var settings: SettingsModel

    var body: some View {
        VStack {
            Text("Настройки отслеживания")
                .font(.title)
                .padding(.bottom, 20)

            Toggle("Отслеживать открытие/закрытие файла", isOn: $settings.trackOpenClose)
                .padding(.bottom, 10)

            Toggle("Отслеживать переименование/редактирование файла", isOn: $settings.trackRenameEdit)
                .padding(.bottom, 10)

            Toggle("Отслеживать перемещение/удаление файла", isOn: $settings.trackMoveDelete)
                .padding(.bottom, 20)

            Button("Окей") {
                isOpen = false
            }
            .buttonStyle(MainButtonStyle())
        }
        .padding(20)
        .background(Color.blue)
        .cornerRadius(10)
    }
}

struct ContentView: View {
    @State private var selectedFilePaths: [FullFileInfo] = []
    @State private var selectedFileIndex: Int?
    @State private var isEditSettingsViewPresented = false
    @State private var settings = SettingsModel(trackOpenClose: false, trackRenameEdit: false, trackMoveDelete: false)
    private let ipcManager = IPCManager()


    var body: some View {
        ZStack {
            Color(.white)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()

                HStack(spacing: 200) {
                    VStack(spacing: 400) {
                        Button("Добавить файл") {
                            if let filePath = openFilePicker() {
                                selectedFilePaths.append(FullFileInfo(settings: SettingsModel(trackOpenClose: false,trackRenameEdit: false,trackMoveDelete: false), pathToFile: filePath))
                            }
                        }
                        .buttonStyle(MainButtonStyle())
                        .frame(width: 100)
                        
                        Spacer()
                    }.sheet(isPresented: $isEditSettingsViewPresented) {
                        EditSettingsView(isOpen: $isEditSettingsViewPresented, settings: settings)
                    }
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(selectedFilePaths.indices, id: \.self) { index in
                                FileWidgetView(
                                    filePath: selectedFilePaths[index].pathToFile,
                                    onDelete: { deleteFile(at: index) },
                                    onEdit: { editFile(at: index) }
                                )
                                .frame(width: 500)
                                .onTapGesture {
                                    selectedFileIndex = index
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

        dialog.title = "Выберите файл или папку"
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
        selectedFilePaths.remove(at: index)
        selectedFileIndex = nil
        ipcManager.sendMessage("Привет, демон!")
    }

    private func editFile(at index: Int) {
        isEditSettingsViewPresented.toggle()
        settings = selectedFilePaths[index].settings
        print("qwe \(settings)")
    }
}

struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .frame(minWidth: 110)
            .background(Color(.blue))
            .foregroundColor(Color(.white))
            .cornerRadius(5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct FileWidgetView: View {
    var filePath: String
    var onDelete: () -> Void
    var onEdit: () -> Void

    var body: some View {
        HStack {
            Text(filePath.components(separatedBy: "/").last ?? filePath)
                .foregroundColor(Color(.white))
            Spacer()

            Button("Удалить") {
                onDelete()
            }
            .buttonStyle(FileButtonStyle())

            Button("Редактировать") {
                onEdit()
            }
            .buttonStyle(FileButtonStyle())
        }
        .padding(10)
        .background(Color(.blue))
        .cornerRadius(10)
    }
}

struct FileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .frame(width: 110) 
            .background(Color(.white))
            .foregroundColor(Color(.blue))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
