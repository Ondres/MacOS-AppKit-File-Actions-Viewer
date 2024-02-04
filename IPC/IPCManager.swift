import Foundation
import EndpointSecurity

class IPCManager {
    var writefileDescriptor: Int32 = -1
    var readFileDescriptor: Int32 = -1
    var pathToWrite: String = ""
    var pathToRead: String = ""

    init(pathToWrite: String, pathToRead: String) {
        self.pathToRead = pathToRead
        self.pathToWrite = pathToWrite
        openReadDescriptor()
    }
    
    func openReadDescriptor() {
        readFileDescriptor = open(pathToRead, O_RDONLY | O_NONBLOCK)
        if readFileDescriptor == -1 {
            let errnoDescription = String(cString: strerror(errno))
            Logger.log(message: "Error opening pipe: \(errnoDescription)")
        }
    }
    
    func openWriteDescriptor() {
        writefileDescriptor = open(pathToWrite, O_RDWR | O_NONBLOCK)
        if writefileDescriptor == -1 {
            let errnoDescription = String(cString: strerror(errno))
            Logger.log(message: "Error opening pipe: \(errnoDescription)")
        }
    }
    
    func closeReadDescriptor() {
        close(readFileDescriptor)
    }
    
    func closeWriteDescriptor() {
        close(writefileDescriptor)
    }
    
    deinit {
        closeReadDescriptor()
        closeWriteDescriptor()
    }
    
    func sendMessage(data: Data) {
        openWriteDescriptor()
        let fileDescriptor = writefileDescriptor
        let bytesWritten = write(fileDescriptor, (data as NSData).bytes, data.count)
        closeWriteDescriptor()
        if bytesWritten == -1 {
            let errnoDescription = String(cString: strerror(errno))
            Logger.log(message: "Error opening pipe: WRITE \(errnoDescription)")
            return
        } else {
            Logger.log(message: "Write successful. Bytes written: \(bytesWritten)")
        }
    }
    
    func dataFromPipe() -> Data? {
        openReadDescriptor()
        let fileDescriptor = readFileDescriptor
        defer {
            closeReadDescriptor()
        }
        return readFromPipe(fileDescriptor: fileDescriptor)
    }
    
    private func readFromPipe(fileDescriptor: Int32) -> Data? {
        var buffer = [UInt8](repeating: 0, count: Constants.MAX_DATA_BYTES)
        let bytesRead = read(fileDescriptor, &buffer, buffer.count)
        switch bytesRead {
        case _ where bytesRead > 0:
            return getData(buffer: buffer, bytesRead: bytesRead)
        case 0:
            Logger.log(message: "No data read from pipe")
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

