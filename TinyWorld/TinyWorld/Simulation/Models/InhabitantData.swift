import Foundation

enum InhabitantState {
    case idle
    case moving
}

struct InhabitantData: Identifiable {
    let id: UUID
    var positionX: Float
    var positionZ: Float
    var state: InhabitantState
    var destinationX: Float?
    var destinationZ: Float?
}
