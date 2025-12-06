import Foundation
import EndpointSecurity

class ESManagerDataProcessor: DataProcessor {
    func updateArrayIfNeeded(events: inout [es_event_type_t], filesArray: inout [String: Monitors]) {
        if let data = ipcManager.dataFromPipe() {
            parseDataArrayToVariables(data: data, events: &events, filesArray: &filesArray)
        }
    }
    
    func updateArray(events: inout [es_event_type_t], array: [String: Monitors]) {
        Logger.log(message: "Events Before Update: \(events)")
        var newEventsArray: [es_event_type_t] = []
        if array.contains(where: {$0.value.monitorMoveEvent}) {
            newEventsArray.append(ES_EVENT_TYPE_NOTIFY_RENAME)
        }
        if array.contains(where: {$0.value.monitorOpenEvent}) {
            newEventsArray.append(ES_EVENT_TYPE_NOTIFY_OPEN)
        }
        if array.contains(where: {$0.value.monitorUnlinkEvent}) {
            newEventsArray.append(ES_EVENT_TYPE_NOTIFY_UNLINK)
        }
        if array.contains(where: {$0.value.monitorDeleteEvent}) {
            newEventsArray.append(ES_EVENT_TYPE_NOTIFY_DELETEEXTATTR)
        }
        if array.contains(where: {$0.value.monitorLinkEvent}) {
            newEventsArray.append(ES_EVENT_TYPE_NOTIFY_LINK)
        }
        if array.contains(where: {$0.value.monitorExchangeEvent}) {
            newEventsArray.append(ES_EVENT_TYPE_NOTIFY_EXCHANGEDATA)
        }
        if array.contains(where: {$0.value.monitorWriteEvent}) {
            newEventsArray.append(ES_EVENT_TYPE_NOTIFY_WRITE)
        }
        if array.contains(where: {$0.value.monitorCloseEvent}) {
            newEventsArray.append(ES_EVENT_TYPE_NOTIFY_CLOSE)
        }
        
        events = newEventsArray
        Logger.log(message: "Events After Update: \(events)")
    }
    
    override func parseDataArrayToVariables(data: Data, events: inout [es_event_type_t], filesArray: inout [String: Monitors]) {
        if let message = String(data: data, encoding: .utf8) {
            Logger.log(message: "Received Message (esm from app): \(message)")
        }
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: data, options: [])
            var array: [String: Monitors] = [:]
            if let jsonArrayOfDicts = jsonArray as? [[String: Any]] {
                for jsonDict in jsonArrayOfDicts {
                    if let filePath = jsonDict[JsonKeys.filePathKey] as? String,
                       let unlinking = jsonDict[JsonKeys.monitorUnlinkEventKey] as? Bool,
                       let opening = jsonDict[JsonKeys.monitorOpenEventKey] as? Bool,
                       let moving = jsonDict[JsonKeys.monitorMoveEventKey] as? Bool,
                       let deleting = jsonDict[JsonKeys.monitorDeleteEventKey] as? Bool,
                       let linking = jsonDict[JsonKeys.monitorLinkEventKey] as? Bool,
                       let exchanging = jsonDict[JsonKeys.monitorExchangeEventKey] as? Bool,
                       let writing = jsonDict[JsonKeys.monitorWriteEventKey] as? Bool,
                       let closing = jsonDict[JsonKeys.monitorCloseEventKey] as? Bool,
                       let renaming = jsonDict[JsonKeys.monitorRenameEventKey] as? Bool {
                        array[filePath] = Monitors(
                            monitorMoveEvent: moving,
                            monitorUnlinkEvent: unlinking,
                            monitorLinkEvent: linking,
                            monitorOpenEvent: opening,
                            monitorRenameEvent: renaming,
                            monitorDeleteEvent: deleting,
                            monitorExchangeEvent: exchanging,
                            monitorWriteEvent: writing,
                            monitorCloseEvent: closing)
                    }
                }
                updateArray(events: &events, array: array)
                filesArray = array
                Logger.log(message: "Updated success")
            }
        } catch {
            Logger.log(message: "Error parsing JSON: \(error)")
        }
    }
    
    override func appendJsonArray(currentData: inout [[String: Any]], eventName: String, processPid: Int, processName: String, filaPath: String) {
        let newElement: [String: Any] = [
            JsonKeys.eventNameKey: eventName,
            JsonKeys.processPidKey: processPid,
            JsonKeys.processNameKey: processName,
            JsonKeys.filePathKey: filaPath,
        ]
        currentData.append(newElement)
    }
}
