import Foundation
import EndpointSecurity

@main
struct EndpointSecurityManagerApp {
    static var events: [es_event_type_t] = [ES_EVENT_TYPE_NOTIFY_OPEN]
    static let dataProcessor = DataProcessor(pathToPipe: Constants.pipeDeamonToAppPath)
    public static func main() {
        
        let endpointSecurityManager = EndpointSecurityManager()
        endpointSecurityManager.setup()
        
        DispatchQueue.global(qos: .background).async {
            endpointSecurityManager.sendMessages()
        }
        endpointSecurityManager.updateEvents()

        dispatchMain()
    }
}
