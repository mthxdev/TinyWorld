import Foundation

enum ZoneType: String, Codable {
    case home
    case work
    case food
    case park
}

struct Zone: Codable {
    let id: Int
    let type: ZoneType
    let centerX: Float
    let centerZ: Float
    let radius: Float
}

struct WorldData: Codable {
    let size: Float
    var timeOfDay: Float
    var inhabitants: [InhabitantData]
    var zones: [Zone]
    var lastSavedDate: Date
    
    init(size: Float = 30.0, timeOfDay: Float = 6.0) {
        self.size = size
        self.timeOfDay = timeOfDay
        self.lastSavedDate = Date()
        
        // Création des zones basiques
        self.zones = [
            Zone(id: 0, type: .home, centerX: -8.0, centerZ: -8.0, radius: 4.0),
            Zone(id: 1, type: .home, centerX: 8.0, centerZ: -8.0, radius: 4.0),
            Zone(id: 2, type: .home, centerX: -8.0, centerZ: 8.0, radius: 4.0),
            Zone(id: 3, type: .work, centerX: 0.0, centerZ: 0.0, radius: 5.0),
            Zone(id: 4, type: .food, centerX: 8.0, centerZ: 8.0, radius: 3.0),
            Zone(id: 5, type: .park, centerX: 0.0, centerZ: -10.0, radius: 4.0)
        ]
        
        let possibleNames = ["Arthur", "Béatrice", "Charles", "Diane", "Émile", "Flora", "Gaston", "Hélène", "Igor", "Juliette", "Léon", "Margot", "Noah", "Olivia", "Paul", "Rose"]
        
        // Initialisation de 12 habitants
        self.inhabitants = (0..<12).map { i in
            InhabitantData(
                id: UUID(),
                name: possibleNames[i % possibleNames.count],
                positionX: Float.random(in: -size/2...size/2),
                positionZ: Float.random(in: -size/2...size/2),
                activity: .sleeping,
                isMoving: false,
                destinationX: nil,
                destinationZ: nil,
                speed: Float.random(in: 0.4...0.7),
                waitTimer: 0.0,
                wakeUpTime: Float.random(in: 6.0...8.0),
                sleepTime: Float.random(in: 21.0...23.5),
                homeZoneIndex: i % 3, // Répartis dans les 3 maisons
                workZoneIndex: 3
            )
        }
    }
}
