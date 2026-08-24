import SwiftUI

@main
struct AudioShelfApp: App {
    @StateObject private var player = PlayerController()
    @StateObject private var library = LibraryStore()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environmentObject(player)
                .environmentObject(library)
        }
        .defaultSize(width: 1_180, height: 760)
        .windowToolbarStyle(.unified)
    }
}
