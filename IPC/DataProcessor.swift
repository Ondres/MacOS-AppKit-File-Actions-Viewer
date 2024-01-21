import Foundation
import EndpointSecurity

class DataProcessor {
    let ipcManager: IPCManager

    init(pathToPipe: String) {
        self.ipcManager = IPCManager()
    }
    
    func updateArrayIfNeeded(events: inout [es_event_type_t], pathToPipe: String) {
        if let data = ipcManager.dataFromPipe(pathToPipe: pathToPipe) {
            decodeAndReadMessage(messageData: data, events: &events)
        }
    }
    
    func updateArrayIfNeeded(strings: inout [String], pathToPipe: String) {
        if let data = ipcManager.dataFromPipe(pathToPipe: pathToPipe) {
            decodeAndReadMessage(messageData: data, strings: &strings)
        }
    }
    
    func sendMessageWithSeparator(message: String, pathToPipe: String) {
        ipcManager.sendMessage(message: "\(message)\(Constants.messagesSeparator)", pathToPipe: pathToPipe)
    }
    
    private func decodeAndReadMessage(messageData: Data, events: inout [es_event_type_t]) {
        if let message = String(data: messageData, encoding: .utf8) {
            let messages = separatedMessages(message: message)
            for msg in messages {
                Logger.log(message: "Received Message (SEP): \(msg)")
                if let eventInfo = getNewEventFromMessage(message: msg) {
                    if !events.contains(eventInfo.event) && eventInfo.shouldBeSubscribedOnEvent {
                        events.append(eventInfo.event)
                    }
                    if events.contains(eventInfo.event) && !eventInfo.shouldBeSubscribedOnEvent {
                        events.removeAll {$0 == eventInfo.event}
                    }
                }
            }
        } else {
            Logger.log(message: "Error decoding message")
        }
    }
    
    private func decodeAndReadMessage(messageData: Data, strings: inout [String]) {
        if let message = String(data: messageData, encoding: .utf8) {
            Logger.log(message: "Received Message: \(message)")
            let messages = separatedMessages(message: message)
            strings += messages
        } else {
            Logger.log(message: "Error decoding message")
        }
    }
    
    private func getNewEventFromMessage(message: String) -> Tuple? {
        let messageSplited = message.split(separator: " ")
        if messageSplited.count < 1 {
            return nil
        }
        let eventName = String(messageSplited[0])
        guard let shouldBeSubscribedOnEvent = Bool(String(messageSplited[1])), let event = Constants.configuration[eventName]?.0 else {
            return nil
        }
        Constants.configuration[eventName]?.1 = shouldBeSubscribedOnEvent
        return Tuple(event: event, shouldBeSubscribedOnEvent: shouldBeSubscribedOnEvent)
    }
    
    private func separatedMessages(message: String) -> [String] {
        return message.components(separatedBy: Constants.messagesSeparator)
    }
}
