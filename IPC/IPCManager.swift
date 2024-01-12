import Foundation
import EndpointSecurity

class IPCManager {
    var event: es_event_type_t?
    let pipePath = "/Users/user/Documents/myPipe"
    //FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("myPipe").path()
    
    func startListening(events: inout [es_event_type_t]) {
        Logger.log(message: "Start listening \(pipePath)")
        cretePipeIfNeeded()
        
        let fileDescriptor = open(pipePath, O_RDONLY | O_NONBLOCK)
        defer {
            close(fileDescriptor)
        }
        
        while true {
            sleep(3)
            readFromPipe(fileDescriptor: fileDescriptor, events: &events)
        }
    }

    func sendMessage(_ message: String) {
        Logger.log(message: "Start sending \(pipePath)")
        cretePipeIfNeeded()
        let fileDescriptor = open(pipePath, O_WRONLY | O_NONBLOCK)
        let bytesWritten = write(fileDescriptor, message, strlen(message))
        if bytesWritten == -1 {
            perror("Error writing to the pipe")
        } else {
            Logger.log(message: "Write successful. Bytes written: \(bytesWritten)")
        }
        close(fileDescriptor)
    }
    
    func readFromPipe(fileDescriptor: Int32, events: inout [es_event_type_t]) {
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = read(fileDescriptor, &buffer, buffer.count)
        switch bytesRead {
        case _ where bytesRead > 0:
            decodeAndReadMessage(buffer: buffer, bytesRead: bytesRead, events: &events)
        case 0:
            Logger.log(message: "No data read from pipe")
        default:
            Logger.log(message: "Error reading from pipe")
        }
    }
    
    func decodeAndReadMessage(buffer: [UInt8], bytesRead: Int, events: inout [es_event_type_t]) {
        let messageData = Data(bytes: buffer, count: bytesRead)
        if let message = String(data: messageData, encoding: .utf8) {
            Logger.log(message: "Received Message: \(message)")
            if let eventInfo = getNewEventFromMessage(message: message) {
                if !events.contains(eventInfo.event) && eventInfo.shouldBeSubscribedOnEvent {
                    events.append(eventInfo.event)
                }
                if events.contains(eventInfo.event) && !eventInfo.shouldBeSubscribedOnEvent {
                    events.removeAll {$0 == eventInfo.event}
                }
            }
        } else {
            Logger.log(message: "Error decoding message")
        }
    }
    
    func getNewEventFromMessage(message: String) -> Tuple? {
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
    
    func cretePipeIfNeeded() {
        if !FileManager.default.fileExists(atPath: pipePath) {
            if mkfifo(pipePath, 0666) != 0 {
                perror("Error creating pipe")
                return
            }
        }
    }
}


