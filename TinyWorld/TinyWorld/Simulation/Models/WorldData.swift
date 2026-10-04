import Foundation

enum ZoneType: String, Codable {
    case home
    case work
    case food
    case park
    case farm
    case forest
}

struct Zone: Codable {
    let id: Int
    let type: ZoneType
    var centerX: Float
    var centerZ: Float
    var radius: Float
    var isBuilt: Bool
    var cost: Float
    var name: String
}

struct WorldData: Codable {
    let size: Float
    var timeOfDay: Float
    var inhabitants: [InhabitantData]
    var zones: [Zone]
    var lastSavedDate: Date
    
    var developmentScore: Float
    
    init(size: Float = 50.0, timeOfDay: Float = 6.0) {
        self.size = size
        self.timeOfDay = timeOfDay
        self.lastSavedDate = Date()
        self.developmentScore = 50 // Start with some score
        
        self.zones = [
            Zone(id: 0, type: .home, centerX: -6.0, centerZ: -6.0, radius: 4.0, isBuilt: true, cost: 0, name: "Maison Fondatrice"),
            Zone(id: 1, type: .work, centerX: 0.0, centerZ: 8.0, radius: 5.0, isBuilt: true, cost: 0, name: "Atelier"),
            
            Zone(id: 2, type: .home, centerX: 8.0, centerZ: -6.0, radius: 4.0, isBuilt: false, cost: 100, name: "Petite Maison"),
            Zone(id: 3, type: .park, centerX: 0.0, centerZ: -12.0, radius: 6.0, isBuilt: false, cost: 250, name: "Parc du Village"),
            Zone(id: 4, type: .farm, centerX: -12.0, centerZ: 6.0, radius: 6.0, isBuilt: false, cost: 400, name: "Ferme"),
            Zone(id: 5, type: .home, centerX: -14.0, centerZ: -4.0, radius: 4.0, isBuilt: false, cost: 600, name: "Maison de Fermier"),
            Zone(id: 6, type: .food, centerX: 12.0, centerZ: 6.0, radius: 4.0, isBuilt: false, cost: 900, name: "Marché"),
            Zone(id: 7, type: .forest, centerX: 15.0, centerZ: -12.0, radius: 7.0, isBuilt: false, cost: 1200, name: "Forêt Paisible"),
            Zone(id: 8, type: .home, centerX: 6.0, centerZ: 14.0, radius: 4.0, isBuilt: false, cost: 1500, name: "Maison Lointaine")
        ]
        
        self.inhabitants = []
        addInhabitants(count: 3, toHome: 0, work: 1)
    }
    
    mutating func addInhabitants(count: Int, toHome homeId: Int, work workId: Int) {
        let possibleNames = ["Arthur", "Béatrice", "Charles", "Diane", "Émile", "Flora", "Gaston", "Hélène", "Igor", "Juliette", "Léon", "Margot", "Noah", "Olivia", "Paul", "Rose"]
        
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
