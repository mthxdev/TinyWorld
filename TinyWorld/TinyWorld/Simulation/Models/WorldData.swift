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
    var centerX: Float
    var centerZ: Float
    var radius: Float
    var isBuilt: Bool
}

struct WorldData: Codable {
    let size: Float
    var timeOfDay: Float
    var inhabitants: [InhabitantData]
    var zones: [Zone]
    var lastSavedDate: Date
    
    var developmentScore: Float
    var milestoneIndex: Int
    
    init(size: Float = 40.0, timeOfDay: Float = 6.0) {
        self.size = size
        self.timeOfDay = timeOfDay
        self.lastSavedDate = Date()
        self.developmentScore = 0
        self.milestoneIndex = 0
        
        // Plan global du village (isBuilt indique s'ils sont deja presents)
        self.zones = [
            Zone(id: 0, type: .home, centerX: -6.0, centerZ: -6.0, radius: 3.0, isBuilt: true),
            Zone(id: 1, type: .work, centerX: 0.0, centerZ: 8.0, radius: 4.0, isBuilt: true),
            Zone(id: 2, type: .home, centerX: 6.0, centerZ: -6.0, radius: 3.0, isBuilt: false),
            Zone(id: 3, type: .park, centerX: 0.0, centerZ: -10.0, radius: 5.0, isBuilt: false),
            Zone(id: 4, type: .home, centerX: -12.0, centerZ: 0.0, radius: 3.0, isBuilt: false),
            Zone(id: 5, type: .food, centerX: 10.0, centerZ: 6.0, radius: 3.0, isBuilt: false),
            Zone(id: 6, type: .home, centerX: 12.0, centerZ: 0.0, radius: 3.0, isBuilt: false)
        ]
        
        self.inhabitants = []
        // On commence avec 3 habitants
        addInhabitants(count: 3, toHome: 0, work: 1)
    }
    
    mutating func addInhabitants(count: Int, toHome homeId: Int, work workId: Int) {
        let possibleNames = ["Arthur", "Béatrice", "Charles", "Diane", "Émile", "Flora", "Gaston", "Hélène", "Igor", "Juliette", "Léon", "Margot", "Noah", "Olivia", "Paul", "Rose", "Lucas", "Emma", "Hugo", "Alice"]
        
        for _ in 0..<count {
            let color = (r: Float.random(in: 0.2...0.9), g: Float.random(in: 0.2...0.9), b: Float.random(in: 0.2...0.9))
            
            let newInhabitant = InhabitantData(
                id: UUID(),
                name: possibleNames.randomElement() ?? "Inconnu",
                positionX: Float.random(in: -5...5),
                positionZ: Float.random(in: -5...5),
                activity: .sleeping,
                isMoving: false,
                destinationX: nil,
                destinationZ: nil,
                speed: Float.random(in: 0.35...0.6),
                waitTimer: 0.0,
                wakeUpTime: Float.random(in: 6.0...8.0),
                sleepTime: Float.random(in: 21.0...23.5),
                homeZoneId: homeId,
                workZoneId: workId,
                colorR: color.r,
                colorG: color.g,
                colorB: color.b,
                hasHat: Bool.random()
            )
            self.inhabitants.append(newInhabitant)
        }
    }
}
