import SwiftUI
import Foundation

struct PasswordInputWindow: View {
    @Binding public var showMainWindow: Bool
    @State private var password: String = ""
    @State private var showAlert = false
    @State var errorMessage = ""
    var body: some View {
        VStack {
            SecureField("Enter user password", text: $password)
                .padding()
                .foregroundColor(.gray)
                .cornerRadius(10)
                .font(.system(size: 16))
                .frame(width: 350, height: 50)
                .padding(.horizontal)
            Button(action: {
                CmdRunner.updateUsersPassword(password: password)
                let status = CmdRunner.runShellCommand(command: Constants.loadCommand)
                if status == .alreadyDone || status == .success {
                    showMainWindow.toggle()
                } else {
                    errorMessage = status == .wrongPassword ? "Wrond password" : "Unknown error, restart application"
                    showAlert.toggle()
                }
                print(showMainWindow)
            }) {
                Text("Start")
                    .foregroundColor(.white)
                    .frame(width: 280, height: 18)
                    .cornerRadius(10)
                    .font(.system(size: 16))
            }
            .frame(width: 300, height: 50)
        }
        .frame(width: 400, height: 200)
        .background(.black)
        .border(Color.black, width: 1)
        .cornerRadius(10)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("ok")))
        }
    }
    init(showMainWindow: Binding<Bool>) {
        _showMainWindow = showMainWindow
    }
}
