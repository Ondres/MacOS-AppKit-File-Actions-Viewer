import Foundation
import EndpointSecurity

class EndpointSecurityManager {
    private var client: OpaquePointer?
    
    private let events = [
        ES_EVENT_TYPE_NOTIFY_OPEN,
    ]

    private func initializeClient() {
        let eventHandler = HandleEventManager()
        let result = es_new_client(&client) { (client, message) in
            eventHandler.handleEventMessage(client, message)
        }
        if result != ES_NEW_CLIENT_RESULT_SUCCESS {
            Logger.log(message: "Failed to create new ES client: \(result)")
        }
    }

    private func subscribeToEvents() {
        guard let client = client else {
            Logger.log(message: "Client is nil")
            return
        }
        
        let cacheResult = es_clear_cache(client)
        if cacheResult != ES_CLEAR_CACHE_RESULT_SUCCESS {
            Logger.log(message: "Failed to clear cache")
        }
        
        let result = es_subscribe(client, events, UInt32(events.count))
        if result != ES_RETURN_SUCCESS {
            Logger.log(message: "Failed to subscribe events")
        }
    }
    
    private func unsubscribeFromEvents() {
        guard let client = client else {
            Logger.log(message: "Client is nil")
            return
        }
        let result = es_unsubscribe(client, events, UInt32(events.count))
        if result != ES_RETURN_SUCCESS {
            Logger.log(message: "Failed to unsubscribe events")
        }
    }
    
    func setup() {
        initializeClient()
        subscribeToEvents()
        Logger.log(message: "client installed")
    }
    
    deinit {
        unsubscribeFromEvents()
        es_delete_client(client)
        client = nil
    }
}
