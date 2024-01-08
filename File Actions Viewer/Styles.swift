import SwiftUI
import AppKit

struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .frame(minWidth: 110)
            .background(Color(.blue))
            .foregroundColor(Color(.white))
            .cornerRadius(5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct FileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .frame(width: 110)
            .background(Color(.white))
            .foregroundColor(Color(.blue))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct FileWidgetView: View {
    var filePath: String
    var onDelete: () -> Void
    var onEdit: () -> Void

    var body: some View {
        HStack {
            Text(filePath.components(separatedBy: "/").last ?? filePath)
                .foregroundColor(Color(.white))
            Spacer()

            Button("Delete") {
                onDelete()
            }
            .buttonStyle(FileButtonStyle())

            Button("Edit") {
                onEdit()
            }
            .buttonStyle(FileButtonStyle())
        }
        .padding(10)
        .background(Color(.blue))
        .cornerRadius(10)
    }
}


