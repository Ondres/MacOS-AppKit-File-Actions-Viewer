import Foundation

class IPCManager {
    let pipePath = "/Users/user/Desktop/PIR Proj/File Accessibility Controller/File Actions Viewer/myPipe"

    func startListening() {
        let fileDescriptor = open(pipePath, O_RDONLY | O_NONBLOCK)
        defer {
            close(fileDescriptor)
        }

        while true {
            sleep(3)

            Logger.log(message: "Получено сообщение")
            var buffer = [UInt8](repeating: 0, count: 1024)
            let bytesRead = read(fileDescriptor, &buffer, buffer.count)

            if bytesRead > 0 {
                let message = String(cString: buffer)
                Logger.log(message: "Получено сообщение: \(message)")
            } else {
                
            }
        }
    }
    
    func sendMessage(_ message: String) {
        if !FileManager.default.fileExists(atPath: pipePath) {
            mkfifo(pipePath, 0600)
        }

        let fileDescriptor = open(pipePath, O_WRONLY)
        defer {
            close(fileDescriptor)
        }

        write(fileDescriptor, message, strlen(message))
    }
}
