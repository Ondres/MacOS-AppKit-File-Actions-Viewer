import Foundation

@main
struct Endpoint_Security_ManagerApp {
    public static func main() {
        let endpointSecurityManager = EndpointSecurityManager()

        endpointSecurityManager.setup()

        dispatchMain()
    }
}
