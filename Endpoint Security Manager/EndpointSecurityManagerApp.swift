import Foundation
import EndpointSecurity

@main
struct EndpointSecurityManagerApp {
    static var events: [es_event_type_t] = [ES_EVENT_TYPE_NOTIFY_OPEN]
    static let ipcManager = IPCManager()
    public static func main() {
        
        let endpointSecurityManager = EndpointSecurityManager()
        endpointSecurityManager.setup()

        DispatchQueue.global(qos: .background).async {
            ipcManager.startListening(events: &EndpointSecurityManagerApp.events)
        }

        endpointSecurityManager.updateEvents()
        dispatchMain()
    }
}
