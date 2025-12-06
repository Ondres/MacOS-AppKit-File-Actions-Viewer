import SwiftUI
import AppKit
import EndpointSecurity

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var timer: Timer?
    @State private var dataToSend: [[String: Any]] = []

    @State private var isOn: [Bool] = [false, false, false]
    @State private var isShowingSettings: Bool = false

    @State private var blocker = NSLock()

    @State public var currentMonitoredFiles: [String: Monitors] = [:]
    @State public var oldMonitoredFiles: [String: Monitors] = [:]

    @State private var combinedTextWidgetsAll: [CombinedTextWidget] = []
    @State private var combinedTextWidgetsOnlyNew: [CombinedTextWidget] = []
    @State private var combinedTextWidgets: [CombinedTextWidget] = []
    @State private var files: [FileTextWidget] = []
    @State private var currentIndexForFile = -1
    @State private var currentIndexForMessages = -1
    @State private var currentFileKey = ""

    private let dataProcessor = AppDataProcessor(pathToWrite: Constants.pipeAppToDeamonPath, pathToRead: Constants.pipeDeamonToAppPath)
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(spacing: 0) {
                CombinedTextWidget(currentIndex: $currentIndexForMessages, index: -2, model: Model(eventName: "Event name", processPid: "pid", processName: "Process name", filePath: "Path to file"))
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if combinedTextWidgets.isEmpty {
                            Spacer(minLength: 280)
                            Text("No messages received")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        } else {
                            ForEach(combinedTextWidgets.indices, id: \.self) { index in
                                combinedTextWidgets[index]
                            }
                        }
                    }
                }
                .frame(width: 780, height: 600)
                .foregroundColor(.white)
                .background(
                    UnevenRoundedRectangle(cornerRadii: .init(
                        topLeading: 0,
                        bottomLeading: 10.0,
                        bottomTrailing: 10.0,
                        topTrailing: 0),
                        style: .continuous)
                    .fill(Color.white)
                )
            }
            Spacer()
            
            GeometryReader { geometry in
                VStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Button(action: {
                                clearBoardLogs()
                            }) {
                                Text("Clear")
                            }
                            .buttonStyle(CustomButtonStyle(width: 110, height: 30))
                            
                            Spacer().frame(width: 2)
                            
                            Button(action: {
                                showAllLogs()
                            }) {
                                Text("View All")
                            }
                            .buttonStyle(CustomButtonStyle(width: 100, height: 30))
                        }
                        .cornerRadius(5)
                        
                        Spacer().frame(width: 15)
                        
                        Button(action: {
                            addMonitoredFile()
                        }) {
                            Text("Add file \(currentIndexForFile)")
                        }
                        .buttonStyle(CustomButtonStyle(width: 100, height: 30))
                        .cornerRadius(5)
                    }
                    .frame(width: 320, height: 30)
                    .cornerRadius(5)
                    
                    ScrollView {
                        if files.isEmpty {
                            Spacer(minLength: 80)
                            Text("Add file and setup events to monitor")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(width: 320)
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(files.indices, id: \.self) { index in
                                    files[index]
                                }
                            }
                        }
                    }
                    .background(Color.white)
                    .frame(width: 320, height: 200)
                    .cornerRadius(5)
                    
                    
                    HStack(spacing: 0) {
                        Button(action: {
                            removeMonitoredFile()
                        }) {
                            Text("Remove file")
                        }
                        .buttonStyle(CustomButtonStyle(width: 160, height: 30))
                        
                        Spacer().frame(width: 2)
                        
                        Button(action: {
                            editSettingsForFile()
                        }) {
                            Text("Edit settings")
                        }
                        .buttonStyle(CustomButtonStyle(width: 160, height: 30))
                        
                    }
                    .frame(width: 320, height: 30)
                    .cornerRadius(5)
                    
                    ScrollView {
                        if currentIndexForMessages == -1 || combinedTextWidgets.count < currentIndexForMessages {
                            Spacer(minLength: 40)
                            Text("Select message to see more")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        } else {
                            VStack(spacing: 2) {
                                CustomTextWidget(title: "Event name:", text: combinedTextWidgets[currentIndexForMessages].model.eventName)
                                CustomTextWidget(title: "Pid:", text: combinedTextWidgets[currentIndexForMessages].model.processPid)
                                CustomTextWidget(title: "Process name:", text: combinedTextWidgets[currentIndexForMessages].model.processName)
                                CustomTextWidget(title: "Path to file:", text: combinedTextWidgets[currentIndexForMessages].model.filePath)
                            }
                            .frame(minWidth: geometry.size.width, maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(width: 320, height: 100)
                    .background(Color.white)
                    .cornerRadius(5)
                }
            }
            .frame(width: 320, height: 620)
        }
        .frame(width: 1200, height: 650)
        .padding()
        .background(Color(red: 0.6, green: 0.8, blue: 0.9))
        .fixedSize()
        .onAppear(perform: {
            startTimerForRead()
            startTimerForWrite()
        })
        .sheet(isPresented: $isShowingSettings) {
            if currentIndexForFile != -1 {
                SettingsView(file: files[currentIndexForFile].text, blocker: $blocker, currentMonitoredFiles: $currentMonitoredFiles, configCopy: currentMonitoredFiles)
            }
        }
    }
    
    private func editSettingsForFile() {
        if currentIndexForFile != -1 {
            isShowingSettings.toggle()
        }
    }
    
    private func removeMonitoredFile() {
        if currentIndexForFile != -1 {
            currentMonitoredFiles[files[currentIndexForFile].text] = nil
            files.remove(at: currentIndexForFile)
            for i in files.indices {
                if i > currentIndexForFile - 1 {
                    files[i].index -= 1
                }
            }
            currentIndexForFile = -1
        }
    }
    
    private func addMonitoredFile() {
        if let file = openFilePicker() {
            if currentMonitoredFiles[file] == nil {
                while true {
                    if blocker.try() {
                        currentMonitoredFiles[file] = Monitors()
                        blocker.unlock()
                        break
                    } else {
                        usleep(Constants.SLEEP_TIME_FOR_BLOCKER)
                    }
                }
                files.append(FileTextWidget(currentIndex: $currentIndexForFile, index: files.count, width: 320, text: file))
            }
        }
    }
    
    private func showAllLogs() {
        if !combinedTextWidgetsAll.isEmpty {
            combinedTextWidgetsAll = combinedTextWidgetsAll + combinedTextWidgetsOnlyNew
            combinedTextWidgetsOnlyNew.removeAll()
            combinedTextWidgets = combinedTextWidgetsAll
            currentIndexForMessages = -1
            for i in combinedTextWidgets.indices {
                combinedTextWidgets[i].index = i
            }
        }
    }
    
    private func clearBoardLogs() {
        currentIndexForMessages = -1
        for i in combinedTextWidgets.indices {
            combinedTextWidgets[i].index = i
        }
        combinedTextWidgetsAll = combinedTextWidgetsAll + combinedTextWidgetsOnlyNew
        combinedTextWidgetsOnlyNew.removeAll()
        combinedTextWidgets.removeAll()
    }
    
    private func startTimerForRead() {
        Logger.log(message: "Get new Messages")
        timer = Timer.scheduledTimer(withTimeInterval: Constants.SLEEP_TIME_FOR_UPDATING, repeats: true) { _ in
            let models = dataProcessor.newModelsFromPipe()
            for model in models {
                combinedTextWidgets.append(CombinedTextWidget(currentIndex: $currentIndexForMessages, index: combinedTextWidgets.count, model: model))
                combinedTextWidgetsOnlyNew.append(CombinedTextWidget(currentIndex: $currentIndexForMessages, index: combinedTextWidgetsOnlyNew.count, model: model))
            }
        }
    }
    
    private func startTimerForWrite() {
        Logger.log(message: "Send new Messages")
        timer = Timer.scheduledTimer(withTimeInterval: Constants.SLEEP_TIME_FOR_UPDATING, repeats: true) { _ in
            while true {
                if blocker.try() {
                    if !(oldMonitoredFiles == currentMonitoredFiles) {
                        dataProcessor.appendJsonArray(currentData: &dataToSend, configuration: currentMonitoredFiles)
                        Logger.log(message: "new Message is \(dataToSend)")
                        if let data = dataProcessor.createJsonDataFromArray(currentData: dataToSend) {
                            dataProcessor.sendMessageWithData(data: data)
                            dataToSend.removeAll()
                        }
                        oldMonitoredFiles = currentMonitoredFiles
                    }
                    blocker.unlock()
                    break
                } else {
                    usleep(Constants.SLEEP_TIME_FOR_BLOCKER)
                }
            }
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
}
