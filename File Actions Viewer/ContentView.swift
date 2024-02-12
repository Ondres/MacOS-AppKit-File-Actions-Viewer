import SwiftUI
import AppKit
import EndpointSecurity

class ViewModel: ObservableObject {
    @Published var logText: [String] = ["Initial Text"]
}

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var timer: Timer?
    @State var dataToSend: [[String:Any]] = []
    @State var blocker: Bool = false
    private let dataProcessor = DataProcessor(pathToWrite: Constants.pipeAppToDeamonPath, pathToRead: Constants.pipeDeamonToAppPath)
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                Button("Start Reading/Writing with 1 second repeating interval") {
                    startTimerForRead()
                    startTimerForWrite()
                }.onDisappear {
                    timer?.invalidate()
                }

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
                List(viewModel.logText, id: \.self) { logEntry in
                    Text(logEntry)
                }
                .padding()
                .frame(minWidth: 400, minHeight: 400)
            }
        }
        .frame(width: 800, height: 600)
        .padding()
    }
    
    private func callAddOrRemoveObserver(key: String) {
        while(blocker) {
            usleep(Constants.SLEEP_TIME_FOR_BLOCKER)
        }
        blocker = true
        addOrRemoveObserver(key: key, shouldBeSubscribedOnEvent: &Constants.configuration[key]!.1)
        blocker = false
    }
    
    private func addOrRemoveObserver(key: String, shouldBeSubscribedOnEvent: inout Bool) {
        shouldBeSubscribedOnEvent = !shouldBeSubscribedOnEvent
        dataProcessor.appendJsonArray(currentData: &dataToSend, key: key, shouldBeSubscribedOnEvent: shouldBeSubscribedOnEvent)
    }
    
    func startTimerForRead() {
        Logger.log(message: "Get new Messages")
        timer = Timer.scheduledTimer(withTimeInterval: Constants.SLEEP_TIME_FOR_UPDATING, repeats: true) { _ in
            dataProcessor.updateArrayIfNeeded(strings: &viewModel.logText)
        }
    }
    
    func startTimerForWrite() {
        Logger.log(message: "Send new Messages")
        timer = Timer.scheduledTimer(withTimeInterval: Constants.SLEEP_TIME_FOR_UPDATING, repeats: true) { _ in
            if !dataToSend.isEmpty {
                if let data = dataProcessor.createJsonDataFromArray(currentData: dataToSend) {
                    while(blocker) {
                        usleep(Constants.SLEEP_TIME_FOR_BLOCKER)
                    }
                    blocker = true
                    dataProcessor.sendMessageWithData(data: data)
                    dataToSend.removeAll()
                    blocker = false
                }
            }
        }
    }
}
