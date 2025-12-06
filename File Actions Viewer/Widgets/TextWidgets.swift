import Foundation
import SwiftUI

struct TextWidget: View {
    var width: CGFloat = 80
    var text: String = ""
    var body: some View {
        Text(text)
            .frame(width: width, height: 20, alignment: .leading)
            .padding(.leading, 10.5)
            .border(Color(red: 0.6, green: 0.8, blue: 0.9), width: 1)
            .font(.system(size: 14))
            .foregroundColor(Color.black)
    }
}

struct CombinedTextWidget: View {
    @Binding var currentIndex: Int
    var index: Int
    var model: Model
    var body: some View {
        HStack(spacing: 0) {
            TextWidget(text: model.eventName)
            TextWidget(width: 200, text: model.processName.components(separatedBy: "/").last ?? model.processName)
            TextWidget(width: 60, text: model.processPid)
            TextWidget(width: 400, text: model.filePath)
        }
        .background(currentIndex == index ? Color(red: 0, green: 0.6, blue: 1) : Color.white)
        .onTapGesture {
            if index != -2 {
                currentIndex = index
            }
        }
    }
}

class SelectionManager: ObservableObject {
    @State static var allIndexies = [Int]()
    @State static var currentIndex = -1
}

    struct FileTextWidget: View {
        @Binding var currentIndex: Int
        var index: Int
        var width: CGFloat = 80
        var text: String = ""
        
        var body: some View {
            Text(text)
                .frame(width: width, height: 20, alignment: .leading)
                .padding(.leading, 10)
                .foregroundColor(Color.black)
                .font(.system(size: 14))
                .background(currentIndex == index ? Color(red: 0, green: 0.6, blue: 1) : Color.white)
                .onTapGesture {
                    currentIndex = index
                }
        }
    }

struct CustomTextWidget: View {
    var title: String
    var text: String
    
    var body: some View {
        HStack {
            Text("\(Text(title).bold()) \(text)")
        }
        .modifier(HeadingTextStyle())
    }
}

struct CustomTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.black)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(nil)
            .padding([.horizontal, .vertical], 3)
    }
}

struct HeadingTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(Color.black)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(nil)
            .padding([.horizontal, .vertical], 3)
    }
}
