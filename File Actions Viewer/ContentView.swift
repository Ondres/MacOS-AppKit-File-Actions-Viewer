import SwiftUI
import AppKit
import EndpointSecurity

class ViewModel: ObservableObject {
    @Published var logText: [String] = ["Initial Text"]

    func addNewTextLine() {
        logText.append("\nNew Text Line")
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var timer: Timer?
    private let dataProcessor = DataProcessor(pathToPipe: Constants.pipeAppToDeamonPath)
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                Button("Start listening") {
                    startTimer()
                }.onDisappear {
                    timer?.invalidate()
                }

                Button("Add/Remove Files Opening event observer") {
                    viewModel.addNewTextLine()
                    //callAddOrRemoveObserver(key: Constants.OPEN_KEY)
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
        addOrRemoveObserver(key: key, shouldBeSubscribedOnEvent: &Constants.configuration[key]!.1)
    }
    
    private func addOrRemoveObserver(key: String, shouldBeSubscribedOnEvent: inout Bool) {
        shouldBeSubscribedOnEvent = !shouldBeSubscribedOnEvent
        let message = "\(key) \(shouldBeSubscribedOnEvent)"
        dataProcessor.sendMessageWithSeparator(message: message, pathToPipe: Constants.pipeAppToDeamonPath)
    }
    
    func startTimer() {
        Logger.log(message: "Get new Messages")
            timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                dataProcessor.updateArrayIfNeeded(strings: &viewModel.logText, pathToPipe: Constants.pipeDeamonToAppPath)
            }
        }
}
