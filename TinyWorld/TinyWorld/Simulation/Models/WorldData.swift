import Foundation

struct WorldData {
    let size: Float
    var timeOfDay: Float
    var inhabitants: [InhabitantData]
    
    init(size: Float = 20.0, timeOfDay: Float = 12.0) {
        self.size = size
        self.timeOfDay = timeOfDay
        
        // Initialisation de 3 habitants pour le prototype
        self.inhabitants = (0..<3).map { _ in
            InhabitantData(
                id: UUID(),
                positionX: Float.random(in: -size/2...size/2),
                positionZ: Float.random(in: -size/2...size/2),
                state: .idle,
                destinationX: nil,
                destinationZ: nil
            )
        }
    }
}
