import Foundation

enum ZoneType {
    case home
    case work
    case food
    case park
}

struct Zone {
    let id: Int
    let type: ZoneType
    let centerX: Float
    let centerZ: Float
    let radius: Float
}

struct WorldData {
    let size: Float
    var timeOfDay: Float
    var inhabitants: [InhabitantData]
    var zones: [Zone]
    
    init(size: Float = 20.0, timeOfDay: Float = 6.0) { // Début à 6h du matin
        self.size = size
        self.timeOfDay = timeOfDay
        
        // Création des zones basiques
        self.zones = [
            Zone(id: 0, type: .home, centerX: -6.0, centerZ: -6.0, radius: 3.0),
            Zone(id: 1, type: .home, centerX: 6.0, centerZ: -6.0, radius: 3.0),
            Zone(id: 2, type: .work, centerX: 0.0, centerZ: 6.0, radius: 4.0),
            Zone(id: 3, type: .food, centerX: -5.0, centerZ: 2.0, radius: 2.0),
            Zone(id: 4, type: .park, centerX: 5.0, centerZ: 2.0, radius: 3.0)
        ]
        
        // Initialisation de 3 habitants
        self.inhabitants = (0..<3).map { i in
            InhabitantData(
                id: UUID(),
                positionX: Float.random(in: -size/2...size/2),
                positionZ: Float.random(in: -size/2...size/2),
                activity: .sleeping,
                isMoving: false,
                destinationX: nil,
                destinationZ: nil,
                speed: Float.random(in: 0.4...0.6),
                waitTimer: 0.0,
                wakeUpTime: Float.random(in: 6.0...7.5),
                sleepTime: Float.random(in: 21.0...23.0),
                homeZoneIndex: i % 2, // Répartis dans les deux maisons
                workZoneIndex: 2
            )
        }
    }
}
