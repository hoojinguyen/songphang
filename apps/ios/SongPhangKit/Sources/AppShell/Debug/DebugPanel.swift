#if DEBUG
  import DesignSystem
  import Domain
  import PreviewSupport
  import SwiftUI

  struct DebugPanel: View {
    private let world: FakeWorld
    private let sessionModel: SessionModel
    private let onOpenJoinToken: (String) -> Void
    private let onOpenGallery: () -> Void
    private let onDismiss: () -> Void

    @State private var selectedPreset: ScenarioPreset = .tripStep4
    @State private var selectedLatencyIndex: Int = 0
    @State private var selectedFailureKind: FailureKind = .none
    @State private var hasSnapshot: Bool = true
    @State private var selectedRole: RoleChoice = .owner
    @State private var unverifiedEmail: Bool = false
    @State private var joinTokenText: String = TripScenario.invite.token

    enum FailureKind: String, CaseIterable, Identifiable {
      case none = "None"
      case offline = "offline"
      case unauthorized = "unauthorized"
      case upgradeRequired = "upgradeRequired"
      case conflict = "conflict"
      case rateLimited = "rateLimited"
      case invalidCredentials = "api(INVALID_CREDENTIALS)"
      case unexpected = "unexpected"

      var id: String { rawValue }

      var appError: AppError? {
        switch self {
        case .none: return nil
        case .offline: return .offline
        case .unauthorized: return .unauthorized
        case .upgradeRequired: return .upgradeRequired
        case .conflict: return .conflict
        case .rateLimited: return .rateLimited
        case .invalidCredentials: return .api(code: "INVALID_CREDENTIALS", status: 401)
        case .unexpected: return .unexpected
        }
      }
    }

    enum RoleChoice: String, CaseIterable, Identifiable {
      case owner = "owner"
      case editor = "editor"
      case viewer = "viewer"

      var id: String { rawValue }

      var domainRole: Role {
        switch self {
        case .owner: return .owner
        case .editor: return .editor
        case .viewer: return .viewer
        }
      }
    }

    init(
      world: FakeWorld,
      sessionModel: SessionModel,
      onOpenJoinToken: @escaping (String) -> Void,
      onOpenGallery: @escaping () -> Void,
      onDismiss: @escaping () -> Void
    ) {
      self.world = world
      self.sessionModel = sessionModel
      self.onOpenJoinToken = onOpenJoinToken
      self.onOpenGallery = onOpenGallery
      self.onDismiss = onDismiss
    }

    var body: some View {
      NavigationStack {
        Form {
          Section("Scenario") {
            Picker("Scenario", selection: $selectedPreset) {
              ForEach(ScenarioPreset.allCases, id: \.self) { preset in
                Text(preset.rawValue).tag(preset)
              }
            }
            .onChange(of: selectedPreset) { _, newValue in
              Task {
                await world.applyScenario(newValue, signedIn: true)
                if let user = await world.currentUser {
                  sessionModel.didSignIn(user)
                }
              }
            }
          }

          Section("Network & Snapshot") {
            Picker("Latency", selection: $selectedLatencyIndex) {
              Text("0 ms").tag(0)
              Text("300 ms").tag(1)
              Text("2 s").tag(2)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedLatencyIndex) { _, _ in
              Task { await syncBehavior() }
            }

            Toggle("Has Snapshot", isOn: $hasSnapshot)
              .onChange(of: hasSnapshot) { _, _ in
                Task { await syncBehavior() }
              }

            Picker("Failure", selection: $selectedFailureKind) {
              ForEach(FailureKind.allCases) { kind in
                Text(kind.rawValue).tag(kind)
              }
            }
            .onChange(of: selectedFailureKind) { _, newKind in
              Task {
                await syncBehavior()
                if newKind == .unauthorized {
                  sessionModel.handleError(.unauthorized)
                }
              }
            }
          }

          Section("Role & Account") {
            Picker("Role", selection: $selectedRole) {
              ForEach(RoleChoice.allCases) { role in
                Text(role.rawValue).tag(role)
              }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedRole) { _, _ in
              Task { await syncBehavior() }
            }

            Toggle("Unverified Email", isOn: $unverifiedEmail)
              .onChange(of: unverifiedEmail) { _, isUnverified in
                Task {
                  let user = isUnverified ? PreviewSamples.unverifiedUser : PreviewSamples.user
                  await world.setCurrentUser(user)
                  sessionModel.didSignIn(user)
                }
              }

            Button("Sign Out", role: .destructive) {
              Task {
                await sessionModel.signOut()
                onDismiss()
              }
            }
          }

          Section("Realtime Group Events") {
            Button("Send .changed([\"transactions\", \"balances\"])") {
              Task {
                await world.emitEvent(.changed(["transactions", "balances"]))
                onDismiss()
              }
            }
            Button("Send .reconnected") {
              Task {
                await world.emitEvent(.reconnected)
                onDismiss()
              }
            }
            Button("Send .removed", role: .destructive) {
              Task {
                await world.emitEvent(.removed)
                onDismiss()
              }
            }
          }

          Section("Invite Link & Gallery") {
            TextField("Invite Token", text: $joinTokenText)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
            Button("Open Join Screen (S12)") {
              let token = joinTokenText
              onDismiss()
              onOpenJoinToken(token)
            }
            Button("Open Design System Gallery") {
              onDismiss()
              onOpenGallery()
            }
          }
        }
        .navigationTitle("Debug Panel")
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button("Done", action: onDismiss)
          }
        }
        .task {
          selectedPreset = await world.preset
          let behavior = await world.behavior
          hasSnapshot = behavior.hasSnapshot
          if behavior.latency == .milliseconds(300) {
            selectedLatencyIndex = 1
          } else if behavior.latency == .seconds(2) {
            selectedLatencyIndex = 2
          } else {
            selectedLatencyIndex = 0
          }
          switch behavior.role {
          case .owner: selectedRole = .owner
          case .editor: selectedRole = .editor
          default: selectedRole = .viewer
          }
          if let currentUser = await world.currentUser {
            unverifiedEmail = !currentUser.emailVerified
          }
        }
      }
    }

    private func syncBehavior() async {
      let latency: Duration
      switch selectedLatencyIndex {
      case 1: latency = .milliseconds(300)
      case 2: latency = .seconds(2)
      default: latency = .zero
      }
      let newBehavior = FakeBehavior(
        latency: latency,
        failure: selectedFailureKind.appError,
        hasSnapshot: hasSnapshot,
        role: selectedRole.domainRole
      )
      await world.setBehavior(newBehavior)
    }
  }
#endif
