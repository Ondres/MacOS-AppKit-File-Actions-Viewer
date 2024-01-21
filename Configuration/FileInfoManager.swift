import Foundation
import SwiftUI
import EndpointSecurity

class Constants {
    static let OPEN_KEY: String = "OPEN"
    static let MOVE_KEY: String = "MOVE"
    static let UNLINK_KEY: String = "UNLINK"
    static let messagesSeparator = " End Message. "
    static let pipeDeamonToAppPath = "/Users/user/Documents/pipeDeamonToApp"
    static let pipeAppToDeamonPath = "/Users/user/Documents/pipeAppToDeamon"

    static var configuration: [String: (es_event_type_t, Bool)] = [
        OPEN_KEY: (ES_EVENT_TYPE_NOTIFY_OPEN, false),
        MOVE_KEY: (ES_EVENT_TYPE_NOTIFY_UNLINK, false),
        UNLINK_KEY: (ES_EVENT_TYPE_NOTIFY_RENAME, false)
    ]
}

struct Tuple {
    var event: es_event_type_t
    var shouldBeSubscribedOnEvent: Bool
}

enum pipeOwner {
    case eventsViewerApp
    case esmDeamon
}
