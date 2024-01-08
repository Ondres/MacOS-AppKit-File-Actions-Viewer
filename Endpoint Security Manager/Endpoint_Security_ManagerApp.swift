import Foundation

@main
struct Endpoint_Security_ManagerApp {
    static var files: [FullFileInfo] = []
    public static func main() {
        let ipcManager = IPCManager()
        let endpointSecurityManager = EndpointSecurityManager()
        endpointSecurityManager.setup()
        ipcManager.startListening(files: &Endpoint_Security_ManagerApp.files)
        dispatchMain()
    }
}
