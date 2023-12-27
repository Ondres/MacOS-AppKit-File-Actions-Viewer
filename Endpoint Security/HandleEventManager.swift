import Foundation
import EndpointSecurity

class HandleEventManager {
    func handleEventMessage(_ client: OpaquePointer, _ msg: UnsafePointer<es_message_t>) {
       switch msg.pointee.event_type {
        case ES_EVENT_TYPE_NOTIFY_OPEN:
           Logger.log(message: "xxx We are in open YO")
        default:
            Logger.log(message: "Unexpected event type encountered: \(msg.pointee.event_type.rawValue)")
        }
    }
}

