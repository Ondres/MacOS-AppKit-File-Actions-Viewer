import Foundation
import EndpointSecurity
import Darwin.bsm.libbsm

class EndpointSecurityManager {
    static var filesArray: [String: Monitors] = [:]
    var events: [es_event_type_t] = []
    var dataToSend: [[String: Any]] = []
    let dataProcessor = ESManagerDataProcessor(pathToWrite: Constants.pipeDeamonToAppPath, pathToRead: Constants.pipeAppToDeamonPath)
    static public var messagesArray: String = ""
    static public var blocker = NSLock()
    private var client: OpaquePointer?
    
    private func initializeClient() {
        let eventHandler = HandleEventManager()
        let result = es_new_client(&client) { (client, message) in
            eventHandler.handleEventMessage(client, message)
        }
        if result != ES_NEW_CLIENT_RESULT_SUCCESS {
            Logger.log(message: "Failed to create new ES client: \(result)")
        } else {
            Logger.log(message: "Client installed")
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
        
        if events.isEmpty {
            deinitializeClient()
        }
    }
    
    func subscribeNewConfigurationIfNeeded(newEvents: [es_event_type_t]) {
        let eventsToUnsubscribe = events.filter { !newEvents.contains($0) }
        let eventsToSubscribe = newEvents.filter { !events.contains($0) }
        
        if (eventsToSubscribe.isEmpty && eventsToUnsubscribe.isEmpty) {
            Logger.log(message: "Nothing to update")
        }
        else {
            events = newEvents
            Logger.log(message: "Events were updated")
        }
        
        if (!eventsToUnsubscribe.isEmpty) {
            unsubscribeFromEvents(eventsToUnsubscribe: eventsToUnsubscribe)
        }
        
        if (!eventsToSubscribe.isEmpty) {
            if client == nil {
                setup()
            } else {
                subscribeToEvents(eventsToSubscribe: eventsToSubscribe)
            }
        }
    }
    
    func setup() {
        if !events.isEmpty {
            initializeClient()
            subscribeToEvents(eventsToSubscribe: events)
        }
    }
    
    func sendMessages() {
        while true {
            sleep(Constants.SLEEP_TIME_FOR_ESM)
            // Wait if we update dataToSend now
            while true {
                if EndpointSecurityManager.blocker.try() {
                    if !EndpointSecurityManagerApp.endpointSecurityManager.dataToSend.isEmpty {
                        let dataToSend = EndpointSecurityManagerApp.endpointSecurityManager.dataToSend
                        // Split message, we need this to avoid message truncation due to memory constraints
                        let chunks = stride(from: 0, to: dataToSend.count, by: Constants.CHUNK_SIZE).map {
                            Array(dataToSend[$0 ..< min($0 + Constants.CHUNK_SIZE, dataToSend.count)])
                        }
                        
                        for chunk in chunks {
                            if let data = dataProcessor.createJsonDataFromArray(currentData: chunk) {
                                dataProcessor.sendMessageWithData(data: data)
                            }
                            sleep(UInt32(Constants.SLEEP_TIME_FOR_UPDATING))
                        }
                        
                        EndpointSecurityManagerApp.endpointSecurityManager.dataToSend.removeAll()
                    }
                    EndpointSecurityManager.blocker.unlock()
                    break
                } else {
                    usleep(Constants.SLEEP_TIME_FOR_BLOCKER)
                }
            }
        }
    }
    
    func updateEvents() {
        while true {
            sleep(Constants.SLEEP_TIME_FOR_ESM)
            var newEvents = events
            dataProcessor.updateArrayIfNeeded(events: &newEvents, filesArray: &EndpointSecurityManager.filesArray)
            subscribeNewConfigurationIfNeeded(newEvents: newEvents)
        }
    }
    
    func deinitializeClient() {
        es_delete_client(client)
        client = nil
    }
    
    deinit {
        unsubscribeFromEvents(eventsToUnsubscribe: events)
        deinitializeClient()
    }
}


class HandleEventManager {
    func handleEventMessage(_ client: OpaquePointer, _ message: UnsafePointer<es_message_t>) {
        let auditToken = message.pointee.process.pointee.audit_token
        let processPid = Int(audit_token_to_pid(auditToken))
        let processPath = String(cString: message.pointee.process.pointee.executable.pointee.path.data)
        switch message.pointee.event_type {
        case ES_EVENT_TYPE_NOTIFY_OPEN:
            handleOpenEvent(message: message, processPid: processPid, processPath: processPath)
        case ES_EVENT_TYPE_NOTIFY_UNLINK:
            handleUnlinkEvent(message: message, processPid: processPid, processPath: processPath)
        case ES_EVENT_TYPE_NOTIFY_RENAME:
            handleRenameOrMoveEvent(message: message, processPid: processPid, processPath: processPath)
        case ES_EVENT_TYPE_NOTIFY_DELETEEXTATTR:
            handleDeleteEvent(message: message, processPid: processPid, processPath: processPath)
        case ES_EVENT_TYPE_NOTIFY_LINK:
            handleLinkEvent(message: message, processPid: processPid, processPath: processPath)
        case ES_EVENT_TYPE_NOTIFY_EXCHANGEDATA:
            handleExchangeEvent(message: message, processPid: processPid, processPath: processPath)
        case ES_EVENT_TYPE_NOTIFY_WRITE:
            handleWriteEvent(message: message, processPid: processPid, processPath: processPath)
        case ES_EVENT_TYPE_NOTIFY_CLOSE:
            handleCloseEvent(message: message, processPid: processPid, processPath: processPath)
        default:
            Logger.log(message: "Unexpected event type encountered: \(message.pointee.event_type.rawValue)")
        }
    }
    
    func handleUnlinkEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let pathData = message.pointee.event.unlink.target.pointee.path.data {
            let pathToFile = String(cString: pathData)
            if EndpointSecurityManager.filesArray.contains(where: { $0.key == pathToFile && $0.value.monitorUnlinkEvent }) {
                addData(eventName: Constants.UNLINK_KEY, processPid: processPid, processName: processPath, filaPath: pathToFile)
            }
        }
        else {
            Logger.log(message: "Can't get file path from message")
        }
    }
    
    func isRenameEvent(sourcePath: String, destinationPath: String) -> Bool {
        let sourceDirectory = (sourcePath as NSString).deletingLastPathComponent
        let destinationDirectory = (destinationPath as NSString).deletingLastPathComponent
        return sourceDirectory == destinationDirectory
    }
    
    func handleRenameOrMoveEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let sourceData = message.pointee.event.rename.source.pointee.path.data, let newDirectoryPathData = message.pointee.event.rename.destination.new_path.dir.pointee.path.data, let newFilenameData = message.pointee.event.rename.destination.new_path.filename.data {
            let newDirectoryPath =  String(cString: newDirectoryPathData)
            let newFilename =  String(cString: newFilenameData)
            let sourcePath = String(cString: sourceData)
            let newFullPath = "\(newDirectoryPath)/\(newFilename)"
            if isRenameEvent(sourcePath: sourcePath, destinationPath: newFullPath) && EndpointSecurityManager.filesArray.contains(where: { $0.key == sourcePath && $0.value.monitorRenameEvent }) {
                EndpointSecurityManager.filesArray[newFullPath] = EndpointSecurityManager.filesArray[sourcePath]
                EndpointSecurityManager.filesArray[sourcePath] = nil
                addData(eventName: Constants.RENAME_KEY, processPid: processPid, processName: processPath, filaPath: sourcePath)
            } 
            if !isRenameEvent(sourcePath: sourcePath, destinationPath: newFullPath) && EndpointSecurityManager.filesArray.contains(where: { $0.key == sourcePath && $0.value.monitorMoveEvent }) {
                EndpointSecurityManager.filesArray[newFullPath] = EndpointSecurityManager.filesArray[sourcePath]
                EndpointSecurityManager.filesArray[sourcePath] = nil
                addData(eventName: Constants.MOVE_KEY, processPid: processPid, processName: processPath, filaPath: newFullPath)
            }
        }
    }
    
    func handleDeleteEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let pathData = message.pointee.event.deleteextattr.target.pointee.path.data {
            let pathToFile = String(cString: pathData)
            if EndpointSecurityManager.filesArray.contains(where: { $0.key == pathToFile && $0.value.monitorDeleteEvent }) {
                addData(eventName: Constants.DELETE_KEY, processPid: processPid, processName: processPath, filaPath: pathToFile)
            }
        } else {
            Logger.log(message: "Can't get file path from message")
        }
    }
    
    func handleLinkEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let pathData = message.pointee.event.link.source.pointee.path.data {
            let pathToFile = String(cString: pathData)
            if EndpointSecurityManager.filesArray.contains(where: { $0.key == pathToFile && $0.value.monitorLinkEvent }) {
                addData(eventName: Constants.LINK_KEY, processPid: processPid, processName: processPath, filaPath: pathToFile)
            }
        } else {
            Logger.log(message: "Can't get file path from message")
        }
    }
    
    func handleExchangeEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let pathData = message.pointee.event.exchangedata.file1.pointee.path.data {
            let pathToFile = String(cString: pathData)
            if EndpointSecurityManager.filesArray.contains(where: { $0.key == pathToFile && $0.value.monitorExchangeEvent }) {
                addData(eventName: Constants.EXCHANGE_KEY, processPid: processPid, processName: processPath, filaPath: pathToFile)
            }
        } else {
            Logger.log(message: "Can't get file path from message")
        }
    }
    
    func handleWriteEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let pathData = message.pointee.event.write.target.pointee.path.data {
            let pathToFile = String(cString: pathData)
            if EndpointSecurityManager.filesArray.contains(where: { $0.key == pathToFile && $0.value.monitorWriteEvent }) {
                addData(eventName: Constants.WRITE_KEY, processPid: processPid, processName: processPath, filaPath: pathToFile)
            }
        } else {
            Logger.log(message: "Can't get file path from message")
        }
    }
    
    func handleCloseEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let pathData = message.pointee.event.close.target.pointee.path.data {
            let pathToFile = String(cString: pathData)
            if EndpointSecurityManager.filesArray.contains(where: { $0.key == pathToFile && $0.value.monitorCloseEvent }) {
                addData(eventName: Constants.CLOSE_KEY, processPid: processPid, processName: processPath, filaPath: pathToFile)
            }
        } else {
            Logger.log(message: "Can't get file path from message")
        }
    }
    
    func handleOpenEvent(message: UnsafePointer<es_message_t>, processPid: Int, processPath: String) {
        if let pathData = message.pointee.event.open.file.pointee.path.data {
            let pathToFile = String(cString: pathData)
            if EndpointSecurityManager.filesArray.contains(where: { $0.key == pathToFile && $0.value.monitorOpenEvent }) {
                addData(eventName: Constants.OPEN_KEY, processPid: processPid, processName: processPath, filaPath: pathToFile)
            }
        }
        else {
            Logger.log(message: "Can't get file path from message")
        }
    }
    
    func addData(eventName: String, processPid: Int, processName: String, filaPath: String) {
        while true {
            if EndpointSecurityManager.blocker.try() {
                EndpointSecurityManagerApp.endpointSecurityManager.dataProcessor.appendJsonArray(currentData: &EndpointSecurityManagerApp.endpointSecurityManager.dataToSend, eventName: eventName, processPid: processPid, processName: processName, filaPath: filaPath)
                EndpointSecurityManager.blocker.unlock()
                break
            } else {
                usleep(Constants.SLEEP_TIME_FOR_BLOCKER)
            }
        }
    }
}
