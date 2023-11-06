import ComposableArchitecture
import SwiftUI

struct HomeFeature: Reducer {
    struct State: Equatable {
        @PresentationState public var alert: AlertState<AlertAction>?
        var currentSession: SessionInfo?
        var transactions: [BitcoinTransactionDetails] = []
        var totalTransactionsAmount: Double = 0
        var isStreamingTransactions: Bool = false
    }

    enum Action: Equatable {
        case gotSessionInfo(SessionInfo)
        case sessionInfoErrorMessage(String)

        case logoutFinished

        case alert(PresentationAction<AlertAction>)
        case socketStream(BitcoinTransactionDetails)

        case view(View)

        enum View: Equatable {
            case onAppear
            case logoutButtonTapped
            case startButtonTapped
            case stopButtonTapped
            case clearButtonTapped
        }
    }

    enum AlertAction: Equatable, Sendable {}

    @Dependency(\.authClient) var authClient
    private enum CancelID { case transactionUpdates }

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .alert:
                return .none

            case .logoutFinished:
                return .none

            case let .socketStream(message):
                state.transactions.insert(message, at: 0)
                state.totalTransactionsAmount += message.btcAmount
                return .none

            case let .gotSessionInfo(info):
                state.currentSession = info
                return .none

            case let .sessionInfoErrorMessage(message):
                state.alert = AlertState { TextState(message) }
                return .none

            case .view(.onAppear):
                return .run { send in
                    do {
                        let session = try await authClient.currentSession()
                        await send(.gotSessionInfo(session))
                    } catch {
                        await send(.sessionInfoErrorMessage(error.localizedDescription))
                    }
                }

            case .view(.startButtonTapped):
                state.isStreamingTransactions = true
                return .run { send in
                    do {
                        let socketStream = authClient.transactionsSocketStream()
                        try await socketStream.send("{\"op\": \"unconfirmed_sub\"}")
                        for try await message in socketStream {
                            try await send(.socketStream(message.transactionDetails()))
                        }
                    } catch {
                        print("Socket Error: \(error)")
                    }
                }
                .animation()
                .cancellable(id: CancelID.transactionUpdates)

            case .view(.stopButtonTapped):
                state.isStreamingTransactions = false
                return .cancel(id: CancelID.transactionUpdates)

            case .view(.clearButtonTapped):
                state.transactions = []
                state.totalTransactionsAmount = 0
                return .none

            case .view(.logoutButtonTapped):
                return .run { [sessionId = state.currentSession?.session.sessionId] send in
                    await authClient.logout(sessionId)
                    await send(.logoutFinished)
                }
                .merge(with: .send(.view(.stopButtonTapped)))
            }
        }
    }
}

public struct HomeView: View {
    let store: StoreOf<HomeFeature>
    @ObservedObject var viewStore: ViewStore<HomeFeature.State, HomeFeature.Action.View>

    init(
        store: StoreOf<HomeFeature>
    ) {
        self.store = store
        viewStore = ViewStore(self.store, observe: { $0 }, send: { .view($0) }, removeDuplicates: ==)
    }

    public var body: some View {
        ScrollView {
            // MARK: - Account info view

            VStack(alignment: .leading) {
                Text("Account Info")
                    .font(.title)
                    .padding(.bottom, 16)

                if let session = viewStore.currentSession {
                    if let profile = session.profiles.first {
                        VStack(alignment: .leading) {
                            Text("Account ID:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(profile.accountId)")
                        }
                        VStack(alignment: .leading) {
                            Text("Profile ID:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(profile.profileId)")
                        }
                        VStack(alignment: .leading) {
                            Text("Email:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(profile.email)")
                        }
                        VStack(alignment: .leading) {
                            Text("First Name:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(profile.firstName)")
                        }
                        VStack(alignment: .leading) {
                            Text("Last Name:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(profile.lastName)")
                        }
                    } else {
                        Text("No profile found")
                    }
                } else {
                    ProgressView(label: { Text("Loading...") })
                }
            }
            .frame(maxWidth: .infinity)
            .padding()

            // MARK: - Transactions view

            VStack(alignment: .leading) {
                Text("Transactions")
                    .font(.title)
                    .padding(.bottom, 16)

                if viewStore.isStreamingTransactions {
                    Button("Stop streaming") {
                        viewStore.send(.stopButtonTapped)
                    }
                } else {
                    Button("Start streaming") {
                        viewStore.send(.startButtonTapped)
                    }
                }

                Button("Clear") {
                    viewStore.send(.clearButtonTapped)
                }

                HStack {
                    Text("Total Amount:")
                        .font(.title3)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Text("\(viewStore.totalTransactionsAmount) BTC")
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                VStack(alignment: .leading) {
                    ForEach(viewStore.transactions) { transaction in
                        Divider()

                        VStack {
                            HStack {
                                Text("Transaction ID:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Text(transaction.hash)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }

                            HStack {
                                Text("Amount:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                Text("\(transaction.btcAmount) BTC")
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                        }
                        .transition(.opacity)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("Home")
        .navigationBarItems(trailing: Button("Logout") { viewStore.send(.logoutButtonTapped) })
        .onAppear(perform: {
            viewStore.send(.onAppear)
        })
        .alert(store: store.scope(state: \.$alert, action: { .alert($0) }))
    }
}

// MARK: - Preview

#Preview {
    MainActor.assumeIsolated {
        NavigationStack {
            HomeView(store: StoreOf<HomeFeature>(initialState: .init(), reducer: {
                HomeFeature()._printChanges()
            }, withDependencies: {
                $0.authClient = AuthClientMock()
            }))
        }
    }
}
