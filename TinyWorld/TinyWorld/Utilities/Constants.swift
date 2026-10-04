import Foundation
import CoreGraphics

struct Constants {
    // Configuration de la simulation
    static let simulationTickRate: TimeInterval = 0.1 // 10 tps
    
    // Configuration du rendu
    static let worldSize: Float = 20.0
    static let initialCameraZ: Float = 20.0
    static let initialCameraY: Float = 20.0
    static let cameraAngleX: Float = -Float.pi / 4 // Inclinaison à 45 degrés
    
    // Configuration des habitants
    static let inhabitantSpeed: Float = 0.5 // Unités par tick
    static let inhabitantBodyColor = (r: 0.8, g: 0.2, b: 0.2) // Rouge stylisé
}
