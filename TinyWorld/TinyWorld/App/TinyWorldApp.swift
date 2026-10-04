import SwiftUI

@main
struct TinyWorldApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .ignoresSafeArea()
        }
    }
}
