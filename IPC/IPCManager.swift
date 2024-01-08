import Foundation

class IPCManager {
    let pipePath = "/Users/user/Library/Containers/com.new.File-Actions-Viewer/Data/Documents/myPipe"
    //FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("myPipe").path()
    
    func startListening(files: inout [FullFileInfo]) {
        Logger.log(message: "Start listening \(pipePath)")
        cretePipeIfNeeded()
        
        let fileDescriptor = open(pipePath, O_RDONLY | O_NONBLOCK)
        defer {
            close(fileDescriptor)
        }
        
        while true {
            sleep(3)
            readFromPipe(fileDescriptor: fileDescriptor, files: &files)
        }
    }

    func sendMessage(_ message: String) {
        Logger.log(message: "Start sending \(pipePath)")
        cretePipeIfNeeded()
        let fileDescriptor = open(pipePath, O_WRONLY | O_NONBLOCK)
        let bytesWritten = write(fileDescriptor, message, strlen(message))
        if bytesWritten == -1 {
            perror("Error writing to the pipe")
        } else {
            Logger.log(message: "Write successful. Bytes written: \(bytesWritten)")
        }
        close(fileDescriptor)
    }
    
    func createFullFileInfoFromMessage(message: String) -> FullFileInfo? {
        let messageSplited = message.split(separator: " ")
        if messageSplited.count < 4 {
            return nil
        }
        let pathToFile = String(messageSplited[0])
        guard let trackOpenClose = Bool(String(messageSplited[1])),
              let trackRenameEdit = Bool(String(messageSplited[2])), 
              let trackMoveDelete = Bool(String(messageSplited[3])) else {
                  return nil
        }
        return FullFileInfo(settings: SettingsModel(trackOpenClose: trackOpenClose, trackRenameEdit: trackRenameEdit, trackMoveDelete: trackMoveDelete), pathToFile: pathToFile)
    }
    
    func cretePipeIfNeeded() {
        if !FileManager.default.fileExists(atPath: pipePath) {
            if mkfifo(pipePath, 0666) != 0 {
                perror("Error creating pipe")
                return
            }
        }
    }
    
    func readFromPipe(fileDescriptor: Int32, files: inout [FullFileInfo]) {
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = read(fileDescriptor, &buffer, buffer.count)
        
        if bytesRead > 0 {
            let messageData = Data(bytes: buffer, count: bytesRead)
            if let message = String(data: messageData, encoding: .utf8) {
                Logger.log(message: "Received Message: \(message)")
                if let fullFileInfo = createFullFileInfoFromMessage(message: message) {
                    files.append(fullFileInfo)
                }
            } else {
                Logger.log(message: "Error decoding message")
            }
        } else if bytesRead == 0 {
            Logger.log(message: "No data read from pipe")
        } else {
            Logger.log(message: "Error reading from pipe")
        }
    }
}


