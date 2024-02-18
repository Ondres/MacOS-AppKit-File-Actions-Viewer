import Foundation
import EndpointSecurity

@main
struct EndpointSecurityManagerApp {
    static let endpointSecurityManager = EndpointSecurityManager()
    
    public static func main() {
        
        DispatchQueue.global(qos: .background).async {
            endpointSecurityManager.sendMessages()
        }
        endpointSecurityManager.updateEvents()

        dispatchMain()
    }
}
