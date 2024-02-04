import Foundation
import EndpointSecurity


class EndpointSecurityManager {
    var events: [es_event_type_t] = [ES_EVENT_TYPE_NOTIFY_OPEN]
    var dataToSend: [[String: Any]] = []
    let dataProcessor = DataProcessor(pathToWrite: Constants.pipeDeamonToAppPath, pathToRead: Constants.pipeAppToDeamonPath)
    static public var messagesArray: String = ""
    static public var blocker = false
    private var client: OpaquePointer?
    
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
            return
        }
        Logger.log(message: "Successfully subscribed on \(eventsToSubscribe), result = \(result)")
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
            sleep(Constants.SLEEP_TIME_FOR_ESM)
            // Wait if we update dataToSend now
            while EndpointSecurityManager.blocker {
                usleep(Constants.SLEEP_TIME_FOR_BLOCKER)
            }
            
            if !EndpointSecurityManagerApp.endpointSecurityManager.dataToSend.isEmpty {
                EndpointSecurityManager.blocker = true
                let dataToSend = EndpointSecurityManagerApp.endpointSecurityManager.dataToSend
                Logger.log(message: "Try to Send")
                // Split message, we need this to avoid message truncation due to memory constraints
                let chunks = stride(from: 0, to: dataToSend.count, by: Constants.CHUNK_SIZE).map {
                    Array(dataToSend[$0 ..< min($0 + Constants.CHUNK_SIZE, dataToSend.count)])
                }
                
                for chunk in chunks {
                    if let data = dataProcessor.createJsonDataFromArray(currentData: chunk) {
                        dataProcessor.sendMessageWithData(data: data)
                    }
                    sleep(1)
                }
                
                EndpointSecurityManagerApp.endpointSecurityManager.dataToSend.removeAll()
                EndpointSecurityManager.blocker = false
            }
        }
    }
    
    func updateEvents() {
        while true {
            sleep(Constants.SLEEP_TIME_FOR_ESM)
            var newEvents = events
            dataProcessor.updateArrayIfNeeded(events: &newEvents)
            subscribeNewConfigurationIfNeeded(newEvents: newEvents)
        }
    }
    
    deinit {
        unsubscribeFromEvents(eventsToUnsubscribe: events)
        es_delete_client(client)
        client = nil
    }
}


class HandleEventManager {
    func handleEventMessage(_ client: OpaquePointer, _ message: UnsafePointer<es_message_t>) {
        let processPid = Int(message.pointee.process.pointee.ppid)
        let processPath = String(cString: message.pointee.process.pointee.executable.pointee.path.data)
        switch message.pointee.event_type {
        case ES_EVENT_TYPE_NOTIFY_OPEN:
            handleOpenEvent(message: message, processPid: processPid, processPath: processPath)
        case ES_EVENT_TYPE_NOTIFY_UNLINK:
            handleUnlinkEvent(message: message, processPid: processPid, processPath: processPath)
        case ES_EVENT_TYPE_NOTIFY_RENAME:
            handleRenameEvent(message: message, processPid: processPid, processPath: processPath)
        default:
            Logger.log(message: "Unexpected event type encountered: \(message.pointee.event_type.rawValue)")
        }
    }
    
    func handleUnlinkEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let pathData = message.pointee.event.unlink.target.pointee.path.data {
            let pathToFile = String(cString: pathData)
            addData(eventName: Constants.UNLINK_KEY, processPid: processPid, processName: processPath, filaPath: pathToFile)
        }
        else {
            Logger.log(message: "Can't get file path from message")
        }
    }
    
    func handleRenameEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let sourceData = message.pointee.event.rename.source.pointee.path.data, let destinationData = message.pointee.event.rename.destination.existing_file.pointee.path.data {
            let sourcePath = String(cString: sourceData)
            let destinationPath = String(cString: destinationData)
            let pathToFile = "Source path: \(sourcePath), Destination path: \(destinationPath)"
            addData(eventName: Constants.MOVE_KEY, processPid: processPid, processName: processPath, filaPath: pathToFile)
        }
        else {
            Logger.log(message: "Can't get file path from message")
        }
    }
    func handleOpenEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let pathData = message.pointee.event.open.file.pointee.path.data {
            let pathToFile = String(cString: pathData)
            if (pathToFile.contains("microsoft") && !pathToFile.contains("private") && !pathToFile.contains("png") && !pathToFile.contains("db") || pathToFile == "/Library/Application Support/Dmn/123") {
                addData(eventName: Constants.OPEN_KEY, processPid: processPid, processName: processPath, filaPath: pathToFile)
            }
        }
        else {
            Logger.log(message: "Can't get file path from message")
        }
    }
    
    func addData(eventName: String, processPid: Int, processName: String, filaPath: String) {
        while EndpointSecurityManager.blocker {
            usleep(Constants.SLEEP_TIME_FOR_BLOCKER)
        }
        EndpointSecurityManager.blocker = true
        Logger.log(message: "Add data")
        EndpointSecurityManagerApp.endpointSecurityManager.dataProcessor.appendJsonArray(currentData: &EndpointSecurityManagerApp.endpointSecurityManager.dataToSend, eventName: eventName, processPid: processPid, processName: processName, filaPath: filaPath)
        EndpointSecurityManager.blocker = false
    }
}



