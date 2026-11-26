import SwiftUI

@main
struct TimeskipApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var dependencies = AppDependencies.live()

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
                .preferredColorScheme(.dark)
        }
    }
}
