import ComposableArchitecture
import SwiftUI

@main
struct RESTSocketExampleApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(
                store: StoreOf<AppFeature>(
                    initialState: AppFeature.State()
                ) { AppFeature() }
            )
        }
    }
}
