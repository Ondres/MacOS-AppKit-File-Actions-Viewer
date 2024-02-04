import Foundation
import EndpointSecurity

class DataProcessor {
    let ipcManager: IPCManager

    init(pathToPipe: String) {
        self.ipcManager = IPCManager()
    }
    
    func updateArrayIfNeeded(events: inout [es_event_type_t], pathToPipe: String) {
        if let data = ipcManager.dataFromPipe(pathToPipe: pathToPipe) {
            parseDataArrayToVariables(data: data, events: &events)
        }
    }
    
    func updateArrayIfNeeded(strings: inout [String], pathToPipe: String) {
        if let data = ipcManager.dataFromPipe(pathToPipe: pathToPipe) {
            parseDataArrayToVariables(data: data, strings: &strings)
        }
    }
    
    func sendMessageWithData(data: Data, pathToPipe: String) {
        ipcManager.sendMessage(data: data, pathToPipe: pathToPipe)
    }
    
    func updateArray(event: es_event_type_t, shouldBeSubscribedOnEvent: Bool, events: inout [es_event_type_t]) {
        if !events.contains(event) && shouldBeSubscribedOnEvent {
            events.append(event)
        }
        if events.contains(event) && !shouldBeSubscribedOnEvent {
            events.removeAll {$0 == event}
        }
    }

    func updateArray(strings: inout [String], message: String) {
        strings.append(message)
    }

    func createEventInfoMessage (eventName: String, processPid: Int, processName: String, filaPath: String) -> String {
        return "Event name: \(eventName)\nProcess pid: \(processPid)\nProcess name: \(processName)\nFila path: \(filaPath)\n"
    }

    func parseDataArrayToVariables(data: Data, strings: inout [String]) {
        if let message = String(data: data, encoding: .utf8) {
            Logger.log(message: "Received Message: \(message)")
        }
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: data, options: [])
            if let jsonArrayOfDicts = jsonArray as? [[String: Any]] {
                for jsonDict in jsonArrayOfDicts {
                    if let eventName = jsonDict[JsonKeys.eventNameKey] as? String,
                       let processPid = jsonDict[JsonKeys.processPidKey] as? Int,
                       let processName = jsonDict[JsonKeys.processNameKey] as? String,
                       let filePath = jsonDict[JsonKeys.filePathKey] as? String {
                        let message = createEventInfoMessage(eventName: eventName, processPid: processPid, processName: processName, filaPath: filePath)
                        updateArray(strings: &strings, message: message)
                    }
                }
                Logger.log(message: "Updated success")
            }
        } catch {
            Logger.log(message: "Error parsing JSON: \(error), \(data)")
        }
    }

    func parseDataArrayToVariables(data: Data, events: inout [es_event_type_t]) {
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: data, options: [])
            
            if let jsonArrayOfDicts = jsonArray as? [[String: Any]] {
                for jsonDict in jsonArrayOfDicts {
                    if let eventKey = jsonDict[JsonKeys.eventKey] as? String,
                       let shouldBeSubscribedOnEvent = jsonDict[JsonKeys.shouldBeSubscribedOnEventKey] as? Bool,
                       let event = Constants.configuration[eventKey]?.0 {
                        updateArray(event: event, shouldBeSubscribedOnEvent: shouldBeSubscribedOnEvent, events: &events)
                    }
                }
                Logger.log(message: "Updated success")
            }
        } catch {
            Logger.log(message: "Error parsing JSON: \(error)")
        }
    }
    // We can change this function if we have another json keys
    func appendJsonArray(currentData: inout [[String: Any]], key: String, shouldBeSubscribedOnEvent: Bool) {
        let newElement: [String: Any] = [
            JsonKeys.eventKey: key,
            JsonKeys.shouldBeSubscribedOnEventKey: shouldBeSubscribedOnEvent
        ]
        currentData.append(newElement)
    }

    func appendJsonArray(currentData: inout [[String: Any]], eventName: String, processPid: Int, processName: String, filaPath: String) {
        let newElement: [String: Any] = [
            JsonKeys.eventNameKey: eventName,
            JsonKeys.processPidKey: processPid,
            JsonKeys.processNameKey: processName,
            JsonKeys.filePathKey: filaPath,
        ]
        currentData.append(newElement)
    }

    func createJsonDataFromArray(currentData: [[String: Any]]) -> Data? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: currentData, options: [.prettyPrinted])
            return jsonData
        } catch {
            Logger.log(message: "Error creating JSON data: \(error)")
            return nil
        }
    }
}
