import Foundation
import EndpointSecurity

class IPCManager {
    var writefileDescriptor: Int32 = -1
    var readFileDescriptor: Int32 = -1
    var pathToWrite: String = ""
    var pathToRead: String = ""

    init(pathToWrite: String, pathToRead: String) {
        cretePipeIfNeeded(pathToPipe: pathToRead)
        cretePipeIfNeeded(pathToPipe: pathToWrite)
        self.pathToRead = pathToRead
        self.pathToWrite = pathToWrite
        openReadDescriptor()
        openWriteDescriptor()
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
        Logger.log(message: "Close opened file descriptors, deinitialize IPC manager")
        closeReadDescriptor()
        closeWriteDescriptor()
    }
    
    func sendMessage(data: Data) {
        let fileDescriptor = writefileDescriptor
        let bytesWritten = write(fileDescriptor, (data as NSData).bytes, data.count)
        if bytesWritten == -1 {
            let errnoDescription = String(cString: strerror(errno))
            Logger.log(message: "Error opening pipe: WRITE \(errnoDescription)")
            return
        } else {
            Logger.log(message: "Write successful. Bytes written: \(bytesWritten)")
        }
    }
    
    func dataFromPipe() -> Data? {
        let fileDescriptor = readFileDescriptor
        return readFromPipe(fileDescriptor: fileDescriptor)
    }
    
    private func readFromPipe(fileDescriptor: Int32) -> Data? {
        var buffer = [UInt8](repeating: 0, count: Constants.MAX_DATA_BYTES)
        let bytesRead = read(fileDescriptor, &buffer, buffer.count)
        switch bytesRead {
        case _ where bytesRead > 0:
            return getData(buffer: buffer, bytesRead: bytesRead)
        case 0:
            Logger.log(message: "No data read from pipe, bytesRead = 0")
            return nil
        default:
            let errnoDescription = String(cString: strerror(errno))
            if errno == EAGAIN || errno == EWOULDBLOCK {
                Logger.log(message: "No data read from pipe, errno - Resource temporarily unavailable")
            } else {
                Logger.log(message: "Error reading from pipe: \(bytesRead), \(errnoDescription)")
            }
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

