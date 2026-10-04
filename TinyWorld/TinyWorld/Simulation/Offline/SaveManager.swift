import Foundation

class SaveManager {
    static let shared = SaveManager()
    
    private let saveFileName = "tinyworld_save.json"
    
    private var saveURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(saveFileName)
    }
    
    func save(world: WorldData) {
        do {
            let data = try JSONEncoder().encode(world)
            try data.write(to: saveURL)
            print("Sauvegarde réussie.")
        } catch {
            print("Erreur lors de la sauvegarde: \(error)")
        }
    }
    
    func load() -> WorldData? {
        do {
            let data = try Data(contentsOf: saveURL)
            let world = try JSONDecoder().decode(WorldData.self, from: data)
            print("Chargement réussi.")
            return world
        } catch {
            print("Aucune sauvegarde valide trouvée ou erreur de chargement: \(error)")
            return nil
        }
    }
}
