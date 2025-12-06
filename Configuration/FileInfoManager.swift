import Foundation
import SwiftUI
import EndpointSecurity

class Constants {
    static let MAX_DATA_BYTES = 7168 // Enough for ~30 arrays with information about events
    static let CHUNK_SIZE = 20
    static let SLEEP_TIME_FOR_BLOCKER: useconds_t = 500000
    static let SLEEP_TIME_FOR_ESM: useconds_t = 3
    static let SLEEP_TIME_FOR_UPDATING: Double = 1
    static let OPEN_KEY: String = "OPEN"
    static let MOVE_KEY: String = "MOVE"
    static let UNLINK_KEY: String = "UNLINK"
    static let RENAME_KEY: String = "RENAME"
    static let DELETE_KEY: String = "DELETE"
    static let LINK_KEY: String = "LINK"
    static let EXCHANGE_KEY: String = "EXCHANGE"
    static let WRITE_KEY: String = "WRITE"
    static let CLOSE_KEY: String = "CLOSE"
    static let pipeDeamonToAppPath = "/Users/user/Documents/pipeDeamonToApp"
    static let pipeAppToDeamonPath = "/Users/user/Documents/pipeAppToDeamon"
    
    static let loadCommand = "load"
    static let unloadCommand = "unload"
}

struct Monitors: Equatable {
    var monitorMoveEvent = false
    var monitorUnlinkEvent = false
    var monitorLinkEvent = false
    var monitorOpenEvent = false
    var monitorRenameEvent = false
    var monitorDeleteEvent = false
    var monitorExchangeEvent = false
    var monitorWriteEvent = false
    var monitorCloseEvent = false
    
    static func == (lhs: Monitors, rhs: Monitors) -> Bool {
        return lhs.monitorMoveEvent == rhs.monitorMoveEvent &&
               lhs.monitorUnlinkEvent == rhs.monitorUnlinkEvent &&
               lhs.monitorLinkEvent == rhs.monitorLinkEvent &&
               lhs.monitorOpenEvent == rhs.monitorOpenEvent &&
               lhs.monitorRenameEvent == rhs.monitorRenameEvent &&
               lhs.monitorDeleteEvent == rhs.monitorDeleteEvent &&
               lhs.monitorExchangeEvent == rhs.monitorExchangeEvent &&
               lhs.monitorWriteEvent == rhs.monitorWriteEvent &&
               lhs.monitorCloseEvent == rhs.monitorCloseEvent
    }
}

class JsonKeys {
    static let eventKey = "event"
    static var monitorMoveEventKey = "monitorMoveEvent"
    static var monitorRenameEventKey = "monitorRenameEvent"
    static var monitorLinkEventKey = "monitorLinkEvent"
    static var monitorUnlinkEventKey = "monitorUnlinkEvent"
    static var monitorOpenEventKey = "monitorOpenEvent"
    static var monitorCloseEventKey = "monitorCloseEvent"
    static var monitorWriteEventKey = "monitorWriteEvent"
    static var monitorExchangeEventKey = "monitorExchangeEvent"
    static var monitorDeleteEventKey = "monitorDeleteEvent"
    
    static let eventNameKey = "eventName"
    static let processPidKey = "processPid"
    static let processNameKey = "processName"
    static let filePathKey = "filePath"
}

class Model : ObservableObject {
    init(eventName: String, processPid: String, processName: String, filePath: String) {
        self.eventName = eventName
        self.processPid = processPid
        self.processName = processName
        self.filePath = filePath
    }
    
    init() {
        self.eventName = ""
        self.processPid = ""
        self.processName = ""
        self.filePath = ""
    }
    
    var eventName: String
    var processPid: String
    var processName: String
    var filePath: String
}

enum CommandStatus {
    case success
    case wrongPassword
    case alreadyDone
    case unknownError
}
