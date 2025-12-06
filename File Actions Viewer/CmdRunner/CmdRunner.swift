import Foundation

class CmdRunner {
    static private var password: String = ""
    
    static func updateUsersPassword(password: String) {
        CmdRunner.password = password
    }
    
    static func runShellCommand(command: String) -> CommandStatus {
        Logger.log(message: "Start running \(command) command")
        let process = Process()
        process.launchPath = "/bin/sh"
        let inputPipe = Pipe()
        process.standardInput = inputPipe
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        let errorPipe = Pipe()
        process.standardError = errorPipe
        
        process.launch()
        if let inputData = "echo \(password) | sudo -S launchctl \(command) /Library/LaunchDaemons/com.my.endpoint.plist\n".data(using: .utf8) {
            inputPipe.fileHandleForWriting.write(inputData)
        }
        inputPipe.fileHandleForWriting.closeFile()
     
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return .unknownError
        }
        Logger.log(message: "Standart output: \(output)")

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        guard let error = String(data: errorData, encoding: .utf8) else {
            return .unknownError
        }
        Logger.log(message: "Error output: \(error)")

        if output == "" && error.contains("Password") && !error.contains("Sorry, try again") {
            return .success
        }
        
        if output == "" && error.contains("Password") && error.contains("Sorry, try again") {
            return .wrongPassword
        }
        
        if error.contains("Load failed: 37: Operation already in progress") || error.contains("Unload failed: 113: Could not find specified service") {
            return .alreadyDone
        }
        
        return .unknownError
    }
}
