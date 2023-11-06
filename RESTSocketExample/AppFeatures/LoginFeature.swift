import ComposableArchitecture
import SwiftUI

struct LoginFeature: Reducer, Sendable {
    struct State: Equatable {
        @PresentationState public var alert: AlertState<AlertAction>?
        @BindingState public var email = ""
        public var isFormValid = false
        public var isLoginRequestInFlight = false
        @BindingState public var password = ""

        init() {}
    }

    enum Action: Equatable, Sendable {
        case alert(PresentationAction<AlertAction>)
        case loginResponse(TaskResult<AuthToken>)
        case view(View)

        enum View: BindableAction, Equatable, Sendable {
            case binding(BindingAction<State>)
            case loginButtonTapped
        }
    }

    enum AlertAction: Equatable, Sendable {}

    @Dependency(\.authClient) var authClient

    var body: some Reducer<State, Action> {
        BindingReducer(action: /Action.view)
        Reduce { state, action in
            switch action {
            case .alert:
                return .none

            case .loginResponse(.success):
                state.isLoginRequestInFlight = false

                return .none

            case let .loginResponse(.failure(error)):
                state.alert = AlertState { TextState(error.localizedDescription) }
                state.isLoginRequestInFlight = false
                return .none

            case .view(.binding):
                state.isFormValid = !state.email.isEmpty && !state.password.isEmpty
                return .none

            case .view(.loginButtonTapped):
                state.isLoginRequestInFlight = true
                return .run { [email = state.email, password = state.password] send in
                    await send(
                        .loginResponse(
                            await TaskResult {
                                try await self.authClient.signIn(email, password)
                            }
                        )
                    )
                }
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }
}

struct LoginView: View {
    let store: StoreOf<LoginFeature>

    struct ViewState: Equatable {
        @BindingViewState var email: String
        var isActivityIndicatorVisible: Bool
        var isFormDisabled: Bool
        var isLoginButtonDisabled: Bool
        @BindingViewState var password: String
    }

    var body: some View {
        WithViewStore(self.store, observe: \.view, send: { .view($0) }) { viewStore in
            Form {
                Text(
                    """
                    Please enter your account credentials
                    """
                )

                Section {
                    TextField("your@email.com", text: viewStore.$email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)

                    SecureField("••••••••", text: viewStore.$password)
                }

                Button {
                    // NB: SwiftUI will print errors to the console about "AttributeGraph: cycle detected" if
                    //     you disable a text field while it is focused. This hack will force all fields to
                    //     unfocus before we send the action to the view store.
                    // CF: https://stackoverflow.com/a/69653555
                    _ = UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
                    viewStore.send(.loginButtonTapped)
                } label: {
                    HStack {
                        Text("Log in")
                        if viewStore.isActivityIndicatorVisible {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(viewStore.isLoginButtonDisabled)
            }
            .disabled(viewStore.isFormDisabled)
            .alert(store: self.store.scope(state: \.$alert, action: { .alert($0) }))
        }
        .navigationTitle("Login")
    }
}

extension BindingViewStore<LoginFeature.State> {
    var view: LoginView.ViewState {
        LoginView.ViewState(
            email: self.$email,
            isActivityIndicatorVisible: self.isLoginRequestInFlight,
            isFormDisabled: self.isLoginRequestInFlight,
            isLoginButtonDisabled: !self.isFormValid,
            password: self.$password
        )
    }
}
// MARK: - Preview

#Preview {
    MainActor.assumeIsolated {
        NavigationStack {
            LoginView(
                store: Store(initialState: LoginFeature.State()) {
                    LoginFeature()
                        ._printChanges()
                }
            )
        }
    }
}
