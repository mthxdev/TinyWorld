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
    var speed: Float // Vitesse de déplacement propre à chaque habitant
    var waitTimer: Float // Temps restant avant de bouger à nouveau
}
