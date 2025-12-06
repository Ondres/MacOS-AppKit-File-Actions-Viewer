import Foundation
import EndpointSecurity

class AppDataProcessor: DataProcessor {
    func newModelsFromPipe() -> [Model] {
        if let data = ipcManager.dataFromPipe() {
            return parseDataArrayToVariables(data: data)
        }
        return []
    }
    
    override func parseDataArrayToVariables(data: Data) -> [Model] {
        var models: [Model] = []
        if let message = String(data: data, encoding: .utf8) {
            Logger.log(message: "Received Message (app from esm): \(message)")
        }
        do {
            let jsonArray = try JSONSerialization.jsonObject(with: data, options: [])
            if let jsonArrayOfDicts = jsonArray as? [[String: Any]] {
                for jsonDict in jsonArrayOfDicts {
                    if let eventName = jsonDict[JsonKeys.eventNameKey] as? String,
                       let processPid = jsonDict[JsonKeys.processPidKey] as? Int,
                       let processName = jsonDict[JsonKeys.processNameKey] as? String,
                       let filePath = jsonDict[JsonKeys.filePathKey] as? String {
                        models.append(Model(eventName: eventName, processPid: String(processPid), processName: processName, filePath: filePath))
                    }
                }
                Logger.log(message: "Updated success")
            }
        } catch {
            Logger.log(message: "Error parsing JSON: \(error), \(data)")
        }
        return models
    }
    
    override func appendJsonArray(currentData: inout [[String: Any]], configuration: [String: Monitors]) {
        for (filePath, monitors) in configuration {
            let newElement: [String: Any] = [
                JsonKeys.filePathKey: filePath,
                JsonKeys.monitorMoveEventKey: monitors.monitorMoveEvent,
                JsonKeys.monitorUnlinkEventKey: monitors.monitorUnlinkEvent,
                JsonKeys.monitorOpenEventKey: monitors.monitorOpenEvent,
                JsonKeys.monitorRenameEventKey: monitors.monitorRenameEvent,
                JsonKeys.monitorDeleteEventKey: monitors.monitorDeleteEvent,
                JsonKeys.monitorExchangeEventKey: monitors.monitorExchangeEvent,
                JsonKeys.monitorWriteEventKey: monitors.monitorWriteEvent,
                JsonKeys.monitorCloseEventKey: monitors.monitorCloseEvent,
                JsonKeys.monitorLinkEventKey: monitors.monitorLinkEvent
            ]
            currentData.append(newElement)
        }
    }
}
