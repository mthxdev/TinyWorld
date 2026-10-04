import Foundation

enum Activity: String, Codable {
    case sleeping
    case eating
    case working
    case resting
    case wandering
}

struct InhabitantData: Identifiable, Codable {
    let id: UUID
    let name: String
    
    var positionX: Float
    var positionZ: Float
    
    var activity: Activity
    var isMoving: Bool
    
    var destinationX: Float?
    var destinationZ: Float?
    
    var speed: Float
    var waitTimer: Float
    
    // Preferences
    var wakeUpTime: Float
    var sleepTime: Float
    var homeZoneId: Int
    var workZoneId: Int
    
    // Appearance
    let colorR: Float
    let colorG: Float
    let colorB: Float
    let hasHat: Bool
}
