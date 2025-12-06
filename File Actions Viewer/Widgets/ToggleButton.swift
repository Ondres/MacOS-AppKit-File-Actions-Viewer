import Foundation
import SwiftUI

struct ToggleButton: View {
    @State var isOn: Bool
    var action: () -> Void
    var body: some View {
        RoundedRectangle(cornerRadius: 12.5)
            .fill(isOn ? Color.green : Color.gray)
            .animation(.easeInOut(duration: isOn ? 0.4 : 0.2))
            .frame(width: 50, height: 25)
            .overlay(
                Circle()
                    .fill(Color.white)
                    .offset(x: isOn ? 12.5 : -12.5, y: 0)
                    .animation(.easeInOut(duration: 0.2))
            )
            .onTapGesture {
                isOn.toggle()
                action()
            }
    }
}
