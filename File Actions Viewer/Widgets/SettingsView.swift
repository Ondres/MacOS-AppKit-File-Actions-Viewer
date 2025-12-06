import Foundation
import SwiftUI

struct SettingsView: View {
    var file: String
    @Binding var blocker: NSLock
    @Binding var currentMonitoredFiles: [String: Monitors]
    @State var configCopy: [String: Monitors]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Text(file)
                    .foregroundColor(.black)
            }
            
            HStack {
                Text("On/Off Files Opening observer")
                    .frame(width: 250, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                ToggleButton(isOn: configCopy[file]?.monitorOpenEvent ?? false) {
                    if let currentValue = configCopy[file]?.monitorOpenEvent {
                        configCopy[file]?.monitorOpenEvent = !currentValue
                    } else {
                        configCopy[file]?.monitorOpenEvent = false
                    }
                }
            }

            HStack {
                Text("On/Off Files Moving observer")
                    .frame(width: 250, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                ToggleButton(isOn: configCopy[file]?.monitorMoveEvent ?? false) {
                    if let currentValue = configCopy[file]?.monitorMoveEvent {
                        configCopy[file]?.monitorMoveEvent = !currentValue
                    } else {
                        configCopy[file]?.monitorMoveEvent = false
                    }
                }
            }

            HStack {
                Text("On/Off Files Unlinking observer")
                    .frame(width: 250, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                ToggleButton(isOn: configCopy[file]?.monitorUnlinkEvent ?? false) {
                    if let currentValue = configCopy[file]?.monitorUnlinkEvent {
                        configCopy[file]?.monitorUnlinkEvent = !currentValue
                    } else {
                        configCopy[file]?.monitorUnlinkEvent = false
                    }
                }
            }

            HStack {
                Text("On/Off Files Renaming observer")
                    .frame(width: 250, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                ToggleButton(isOn: configCopy[file]?.monitorRenameEvent ?? false) {
                    if let currentValue = configCopy[file]?.monitorRenameEvent {
                        configCopy[file]?.monitorRenameEvent = !currentValue
                    } else {
                        configCopy[file]?.monitorRenameEvent = false
                    }
                }
            }

            HStack {
                Text("On/Off Files Deleting observer")
                    .frame(width: 250, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                ToggleButton(isOn: configCopy[file]?.monitorDeleteEvent ?? false) {
                    if let currentValue = configCopy[file]?.monitorDeleteEvent {
                        configCopy[file]?.monitorDeleteEvent = !currentValue
                    } else {
                        configCopy[file]?.monitorDeleteEvent = false
                    }
                }
            }

            HStack {
                Text("On/Off Files Exchanging observer")
                    .frame(width: 250, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                ToggleButton(isOn: configCopy[file]?.monitorExchangeEvent ?? false) {
                    if let currentValue = configCopy[file]?.monitorExchangeEvent {
                        configCopy[file]?.monitorExchangeEvent = !currentValue
                    } else {
                        configCopy[file]?.monitorExchangeEvent = false
                    }
                }
            }

            HStack {
                Text("On/Off Files Writing observer")
                    .frame(width: 250, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                ToggleButton(isOn: configCopy[file]?.monitorWriteEvent ?? false) {
                    if let currentValue = configCopy[file]?.monitorWriteEvent {
                        configCopy[file]?.monitorWriteEvent = !currentValue
                    } else {
                        configCopy[file]?.monitorWriteEvent = false
                    }
                }
            }

            HStack {
                Text("On/Off Files Closing observer")
                    .frame(width: 250, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                ToggleButton(isOn: configCopy[file]?.monitorCloseEvent ?? false) {
                    if let currentValue = configCopy[file]?.monitorCloseEvent {
                        configCopy[file]?.monitorCloseEvent = !currentValue
                    } else {
                        configCopy[file]?.monitorCloseEvent = false
                    }
                }
            }

            HStack {
                Text("On/Off Files Linking observer")
                    .frame(width: 250, alignment: .leading)
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                ToggleButton(isOn: configCopy[file]?.monitorLinkEvent ?? false) {
                    if let currentValue = configCopy[file]?.monitorLinkEvent {
                        configCopy[file]?.monitorLinkEvent = !currentValue
                    } else {
                        configCopy[file]?.monitorLinkEvent = false
                    }
                }
            }
            
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.black)
                }
                Spacer()
                Button(action: {
                    while true {
                        if blocker.try() {
                            currentMonitoredFiles = configCopy
                            blocker.unlock()
                            break
                        } else {
                            usleep(Constants.SLEEP_TIME_FOR_BLOCKER)
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                        .foregroundColor(.black)
                }
            }
        }
        .padding()
        .background(Color(red: 0.9, green: 0.9, blue: 0.9))

    }
}
