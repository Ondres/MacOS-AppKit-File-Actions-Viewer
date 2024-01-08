import Foundation
import SwiftUI

class SettingsModel: ObservableObject {
    @Published var trackOpenClose: Bool
    @Published var trackRenameEdit: Bool
    @Published var trackMoveDelete: Bool

    init(trackOpenClose: Bool, trackRenameEdit: Bool, trackMoveDelete: Bool) {
        self.trackOpenClose = trackOpenClose
        self.trackRenameEdit = trackRenameEdit
        self.trackMoveDelete = trackMoveDelete
    }
}

class FullFileInfo: ObservableObject, Identifiable {
    @Published var settings: SettingsModel
    @Published var pathToFile: String

    init(settings: SettingsModel, pathToFile: String) {
        self.settings = settings
        self.pathToFile = pathToFile
    }
}
