import Foundation

enum Activity {
    case sleeping
    case eating
    case working
    case resting
    case wandering
}

struct InhabitantData: Identifiable {
    let id: UUID
    var positionX: Float
    var positionZ: Float
    
    var activity: Activity
    var isMoving: Bool
    
    var destinationX: Float?
    var destinationZ: Float?
    
    var speed: Float
    var waitTimer: Float
    
    // Préférences de routine (pour désynchroniser)
    var wakeUpTime: Float // ex: 6.0 à 7.5
    var sleepTime: Float  // ex: 21.0 à 23.0
    var homeZoneIndex: Int
    var workZoneIndex: Int
}
