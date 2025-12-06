import Foundation
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ aNotification: Notification) {
        CmdRunner.runShellCommand(command: Constants.unloadCommand)
    }
}
