import Foundation
import EndpointSecurity

class IPCManager {
   // var pathToPipe: String
  //init(pathToPipe: String) {
     //   self.pathToPipe = pathToPipe
   // }
    func sendMessage(message: String, pathToPipe: String) {
        Logger.log(message: "Start sending \(pathToPipe)")
        cretePipeIfNeeded(pathToPipe: pathToPipe)
        
        let fileDescriptor = open(pathToPipe, O_RDWR | O_NONBLOCK)
        defer {
            close(fileDescriptor)
        }
        
        if fileDescriptor == -1 {
            let errnoDescription = String(cString: strerror(errno))
            Logger.log(message: "Error opening pipe: OPEN \(errnoDescription)")
            return
        }

        let bytesWritten = write(fileDescriptor, message, strlen(message))
        if bytesWritten == -1 {
            let errnoDescription = String(cString: strerror(errno))
            Logger.log(message: "Error opening pipe: WRITE \(errnoDescription)")
            return
        } else {
            Logger.log(message: "Write successful. Bytes written: \(bytesWritten), to \(pathToPipe)")
        }
    }
    
    func dataFromPipe(pathToPipe: String) -> Data? {
        cretePipeIfNeeded(pathToPipe: pathToPipe)
        
        let fileDescriptor = open(pathToPipe, O_RDONLY | O_NONBLOCK)
        
        if fileDescriptor == -1 {
            let errnoDescription = String(cString: strerror(errno))
            Logger.log(message: "Error opening pipe: \(errnoDescription)")
            return nil
        }
        return readFromPipe(fileDescriptor: fileDescriptor)
    }
    
    private func readFromPipe(fileDescriptor: Int32) -> Data? {
        var buffer = [UInt8](repeating: 0, count: 1024)
        let bytesRead = read(fileDescriptor, &buffer, buffer.count)
        switch bytesRead {
        case _ where bytesRead > 0:
            return getData(buffer: buffer, bytesRead: bytesRead)
        case 0: 
            Logger.log(message: "No data read from pipe ")
            return nil
        default:
            let errnoDescription = String(cString: strerror(errno))
            Logger.log(message: "Error opening pipe: \(errnoDescription)")
            return nil
        }
    }
    
    private func getData(buffer: [UInt8], bytesRead: Int) -> Data {
        Logger.log(message: "Return data")
        return Data(bytes: buffer, count: bytesRead)
    }
    
    private func cretePipeIfNeeded(pathToPipe: String) {
        if !FileManager.default.fileExists(atPath: pathToPipe) {
            Logger.log(message: "Start creating pipe")
            if mkfifo(pathToPipe, 0666) != 0 {
                perror("Error creating pipe")
                return
            }
        }
    }
}

