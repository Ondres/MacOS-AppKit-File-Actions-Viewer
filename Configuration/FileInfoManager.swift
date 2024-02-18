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
    static let pipeDeamonToAppPath = "/Users/user/Documents/pipeDeamonToApp"
    static let pipeAppToDeamonPath = "/Users/user/Documents/pipeAppToDeamon"

    static var configuration: [String: (es_event_type_t, Bool)] = [
        OPEN_KEY: (ES_EVENT_TYPE_NOTIFY_OPEN, false),
        MOVE_KEY: (ES_EVENT_TYPE_NOTIFY_RENAME, false),
        UNLINK_KEY: (ES_EVENT_TYPE_NOTIFY_UNLINK, false)
    ]
}

class JsonKeys {
    static let eventKey = "event"
    static let shouldBeSubscribedOnEventKey = "shouldBeSubscribedOnEvent"
    
    static let eventNameKey = "eventName"
    static let processPidKey = "processPid"
    static let processNameKey = "processName"
    static let filePathKey = "filePath"
}
