import Foundation
import SwiftUI

class ViewModel: ObservableObject {
    @Published var models: [Model] = []
}
