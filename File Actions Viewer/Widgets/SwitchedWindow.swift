import SwiftUI
import Foundation

struct SwitchedWindow: View {
    @Binding var showMainWindow: Bool
    
    var body: some View {
        if !showMainWindow {
            PasswordInputWindow(showMainWindow: $showMainWindow)
                .frame(width: 400, height: 220)
        }
        if showMainWindow {
            ContentView()
        }
    }
    
    init(showMainWindow: Binding<Bool>) {
        _showMainWindow = showMainWindow
    }
}

