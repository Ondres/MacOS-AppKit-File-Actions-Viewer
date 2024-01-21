import Foundation
import EndpointSecurity


class EndpointSecurityManager {
    static public var messagesArray: String = ""
    private var client: OpaquePointer?
    
    private var events = [
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

    private func subscribeToEvents(eventsToSubscribe: [es_event_type_t]) {
        Logger.log(message: "Subscribe on events: \(eventsToSubscribe)")
        
        guard let client = client else {
            Logger.log(message: "Client is nil")
            return
        }
        
        let cacheResult = es_clear_cache(client)
        if cacheResult != ES_CLEAR_CACHE_RESULT_SUCCESS {
            Logger.log(message: "Failed to clear cache")
        }
        
        let result = es_subscribe(client, eventsToSubscribe, UInt32(events.count))
        if result != ES_RETURN_SUCCESS {
            Logger.log(message: "Failed to subscribe events")
        }
    }
    
    private func unsubscribeFromEvents(eventsToUnsubscribe: [es_event_type_t]) {
        Logger.log(message: "UnsubScribe from events: \(eventsToUnsubscribe)")
        
        guard let client = client else {
            Logger.log(message: "Client is nil")
            return
        }
        let result = es_unsubscribe(client, eventsToUnsubscribe, UInt32(events.count))
        if result != ES_RETURN_SUCCESS {
            Logger.log(message: "Failed to unsubscribe events")
        }
    }
    
    func subscribeNewConfigurationIfNeeded(newEvents: [es_event_type_t]) {
        let eventsToUnsubscribe = events.filter { !newEvents.contains($0) }
        let eventsToSubscribe = newEvents.filter { !events.contains($0) }
        if (!eventsToUnsubscribe.isEmpty) {
            unsubscribeFromEvents(eventsToUnsubscribe: eventsToUnsubscribe)
        }
        if (!eventsToSubscribe.isEmpty) {
            subscribeToEvents(eventsToSubscribe: eventsToSubscribe)
        }
        if (eventsToSubscribe.isEmpty && eventsToUnsubscribe.isEmpty) {
            Logger.log(message: "Nothing to update")
        }
        else {
            events = newEvents
            Logger.log(message: "Events were updated")
        }
    }
    
    func setup() {
        initializeClient()
        subscribeToEvents(eventsToSubscribe: events)
        Logger.log(message: "Client installed")
    }
    
    func sendMessages() {
        while true {
            sleep(3)
            if EndpointSecurityManager.messagesArray != "" {
                Logger.log(message: "Try Send")
                EndpointSecurityManagerApp.dataProcessor.sendMessageWithSeparator(message: EndpointSecurityManager.messagesArray, pathToPipe: Constants.pipeDeamonToAppPath)
                EndpointSecurityManager.messagesArray = ""
            }
        }
    }
    
    func updateEvents() {
        while true {
            sleep(3)
            EndpointSecurityManagerApp.dataProcessor.updateArrayIfNeeded(events: &EndpointSecurityManagerApp.events, pathToPipe: Constants.pipeAppToDeamonPath)
            subscribeNewConfigurationIfNeeded(newEvents: EndpointSecurityManagerApp.events)
        }
    }
    
    deinit {
        unsubscribeFromEvents(eventsToUnsubscribe: events)
        es_delete_client(client)
        client = nil
    }
}


class HandleEventManager {
    func handleEventMessage(_ client: OpaquePointer, _ msg: UnsafePointer<es_message_t>) {
       switch msg.pointee.event_type {
        case ES_EVENT_TYPE_NOTIFY_OPEN:
           if let path = msg.pointee.event.open.file.pointee.path.data {
               let str = String(cString: path)
               if (str.contains("microsoft") && !str.contains("private") && !str.contains("png") && !str.contains("db")) {
                   let processPath = String(cString: msg.pointee.process.pointee.executable.pointee.path.data)
                   let processPid = msg.pointee.process.pointee.ppid
                   EndpointSecurityManager.messagesArray += "\nProcess pid: \(processPid) \nPath to process: \(processPath) \nPath to file: \(str)\(Constants.messagesSeparator)"
               }
           }
           else {
               Logger.log(message: "Can't get file path from message")
           }
        default:
            Logger.log(message: "Unexpected event type encountered: \(msg.pointee.event_type.rawValue)")
        }
    }
}



