import Foundation
import SwiftUI

struct CustomButtonStyle: ButtonStyle {
    var width: CGFloat
    var height: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: width, height: height)
            .foregroundColor(Color.black)
            .background(Color.white)
    }
}
