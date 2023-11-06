import ComposableArchitecture
import SwiftUI

struct AppFeature: Reducer {
    enum State: Equatable {
        case loading
        case login(LoginFeature.State)
        case home(HomeFeature.State)

        init() { self = .loading }
    }

    enum Action: Equatable {
        case onAppear
        case login(LoginFeature.Action)
        case home(HomeFeature.Action)
    }

    @Dependency(\.authClient) var authClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                let isAuthorized = authClient.isAuthorized()
                state = isAuthorized ? .home(HomeFeature.State()) : .login(LoginFeature.State())
                return .none

            case .login(.loginResponse(.success)):
                state = .home(HomeFeature.State())
                return .none

            case .login:
                return .none

            case .home(.logoutFinished):
                state = .login(LoginFeature.State())
                return .none

            case .home:
                return .none
            }
        }
        .ifCaseLet(/State.login, action: /Action.login) {
            LoginFeature()
        }
        .ifCaseLet(/State.home, action: /Action.home) {
            HomeFeature()
        }
    }
}

struct AppView: View {
    let store: StoreOf<AppFeature>

    public var body: some View {
        SwitchStore(self.store) { state in
            switch state {
            case .loading:
                ProgressView().scaleEffect(2)
            case .login:
                CaseLet(/AppFeature.State.login, action: AppFeature.Action.login) { store in
                    NavigationStack {
                        LoginView(store: store)
                    }
                }
            case .home:
                CaseLet(/AppFeature.State.home, action: AppFeature.Action.home) { store in
                    NavigationStack {
                        HomeView(store: store)
                    }
                }
            }
        }
        .onAppear { self.store.send(.onAppear) }
    }
}
