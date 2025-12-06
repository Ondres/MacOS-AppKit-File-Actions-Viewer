import Foundation
import EndpointSecurity

protocol DataProcessorProtocol {
    func sendMessageWithData(data: Data)
    func parseDataArrayToVariables(data: Data) -> [Model]
    func parseDataArrayToVariables(data: Data, events: inout [es_event_type_t], filesArray: inout [String: Monitors])
    func appendJsonArray(currentData: inout [[String: Any]], configuration: [String: Monitors])
    func appendJsonArray(currentData: inout [[String: Any]], eventName: String, processPid: Int, processName: String, filaPath: String)
    func createJsonDataFromArray(currentData: [[String: Any]]) -> Data?
}
