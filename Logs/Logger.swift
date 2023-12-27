import Foundation
import OSLog

class Logger {
    static func log(message: String) {
        os_log("%{public}s", log: .default, message)
    }
}
