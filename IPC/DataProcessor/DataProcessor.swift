import Foundation
import EndpointSecurity

class DataProcessor: DataProcessorProtocol {
    let ipcManager: IPCManager
    
    init(pathToWrite: String, pathToRead: String) {
        self.ipcManager = IPCManager(pathToWrite: pathToWrite, pathToRead: pathToRead)
    }
    
    func sendMessageWithData(data: Data) {
        ipcManager.sendMessage(data: data)
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
    
    func parseDataArrayToVariables(data: Data, events: inout [es_event_type_t], filesArray: inout [String : Monitors]) { }
    func parseDataArrayToVariables(data: Data) -> [Model] { return [] }
    func appendJsonArray(currentData: inout [[String : Any]], eventName: String, processPid: Int, processName: String, filaPath: String) { }
    func appendJsonArray(currentData: inout [[String: Any]], configuration: [String: Monitors]) { }

}
