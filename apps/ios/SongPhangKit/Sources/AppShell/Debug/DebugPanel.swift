#if DEBUG
  import DesignSystem
  import Domain
  import PreviewSupport
  import Repositories
  import SwiftUI

  struct DebugPanel: View {
    private let world: FakeWorld?
    private let liveConfiguration: APIConfiguration?
    private let sessionModel: SessionModel
    private let pushCoordinator: PushCoordinator
    private let onOpenJoinToken: (String) -> Void
    private let onOpenLinkURL: (URL) -> Bool
    private let onSimulatePushTap: (String?, String?) -> Void
    private let onOpenGallery: () -> Void
    private let onReloadEnvironment: () -> Void
    private let onDismiss: () -> Void

    @State private var useScriptedMode: Bool
    @State private var apiBaseText: String
    @State private var webBaseText: String
    @State private var configStatusMessage: String?
    @State private var selectedPreset: ScenarioPreset = .tripStep4
    @State private var selectedLatencyIndex: Int = 0
    @State private var selectedFailureKind: FailureKind = .none
    @State private var hasSnapshot: Bool = true
    @State private var selectedRole: RoleChoice = .owner
    @State private var unverifiedEmail: Bool = false
    @State private var joinTokenText: String = TripScenario.invite.token
    @State private var linkURLText: String
    @State private var linkStatusMessage: String?
    @State private var debugPushToken: String = "sim_debug_device_token_5c5_0123456789abcdef"
    @State private var pushGroupIdText: String = TripScenario.groupId.rawValue
    @State private var pushTargetText: String = "/g/\(TripScenario.groupId.rawValue)/balances"
    @State private var pushStatusMessage: String?

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
      world: FakeWorld?,
      liveConfiguration: APIConfiguration?,
      sessionModel: SessionModel,
      pushCoordinator: PushCoordinator,
      onOpenJoinToken: @escaping (String) -> Void,
      onOpenLinkURL: @escaping (URL) -> Bool,
      onSimulatePushTap: @escaping (String?, String?) -> Void,
      onOpenGallery: @escaping () -> Void,
      onReloadEnvironment: @escaping () -> Void = {},
      onDismiss: @escaping () -> Void
    ) {
      self.world = world
      self.liveConfiguration = liveConfiguration
      self.sessionModel = sessionModel
      self.pushCoordinator = pushCoordinator
      self.onOpenJoinToken = onOpenJoinToken
      self.onOpenLinkURL = onOpenLinkURL
      self.onSimulatePushTap = onSimulatePushTap
      self.onOpenGallery = onOpenGallery
      self.onReloadEnvironment = onReloadEnvironment
      self.onDismiss = onDismiss
      let currentConfig = liveConfiguration ?? RootView.resolvedDebugConfiguration()
      self._useScriptedMode = State(initialValue: world != nil)
      self._apiBaseText = State(initialValue: currentConfig.apiBaseURL.absoluteString)
      self._webBaseText = State(initialValue: currentConfig.webBaseURL.absoluteString)
      let trimmedWeb = currentConfig.webBaseURL.absoluteString.trimmingCharacters(
        in: CharacterSet(charactersIn: "/"))
      self._linkURLText = State(initialValue: "\(trimmedWeb)/join/")
    }

    private var previewOriginText: String {
      guard let apiURL = RootView.parseOptionalHTTPURL(apiBaseText) else {
        return "Invalid URL"
      }
      let dummyWeb =
        RootView.parseOptionalHTTPURL(webBaseText)
        ?? RootView.resolvedDebugConfiguration().webBaseURL
      return APIConfiguration(
        apiBaseURL: apiURL,
        webBaseURL: dummyWeb,
        appVersion: "1.0.0",
        deviceName: "iPhone"
      )
      .serverOriginURL.absoluteString
    }

    var body: some View {
      NavigationStack {
        Form {
          Section("Mode") {
            Picker("Environment", selection: $useScriptedMode) {
              Text("Live API").tag(false)
              Text("Scripted (FakeWorld)").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: useScriptedMode) { _, nextValue in
              let isCurrentlyScripted = (world != nil)
              guard nextValue != isCurrentlyScripted else { return }
              DebugOverrides.useScripted = nextValue
              onReloadEnvironment()
            }
          }

          Section("Live API & LAN") {
            VStack(alignment: .leading, spacing: 4) {
              Text("API Base")
                .font(.caption)
                .foregroundStyle(.secondary)
              TextField("http://192.168.1.x:4000/api/v1", text: $apiBaseText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            }

            LabeledContent("Origin", value: previewOriginText)

            VStack(alignment: .leading, spacing: 4) {
              Text("Web Base")
                .font(.caption)
                .foregroundStyle(.secondary)
              TextField("http://192.168.1.x:3000", text: $webBaseText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            }

            LabeledContent(
              "Version",
              value: liveConfiguration?.appVersion
                ?? RootView.resolvedDebugConfiguration().appVersion
            )

            Button("Apply LAN URLs & Switch to Live API") {
              guard let parsedAPI = RootView.parseOptionalHTTPURL(apiBaseText),
                let parsedWeb = RootView.parseOptionalHTTPURL(webBaseText)
              else {
                configStatusMessage = "URL không hợp lệ (cần http:// hoặc https:// kèm host)."
                return
              }
              configStatusMessage = nil
              DebugOverrides.apiBaseURL = parsedAPI.absoluteString
              DebugOverrides.webBaseURL = parsedWeb.absoluteString
              DebugOverrides.useScripted = false
              onReloadEnvironment()
            }

            Button("Reset to Defaults") {
              configStatusMessage = nil
              DebugOverrides.resetURLs()
              let defaults = RootView.bundleConfiguration()
              apiBaseText = defaults.apiBaseURL.absoluteString
              webBaseText = defaults.webBaseURL.absoluteString
              if !useScriptedMode {
                onReloadEnvironment()
              }
            }

            if let configStatusMessage {
              Text(configStatusMessage)
                .font(.caption)
                .foregroundStyle(.red)
            }

            if liveConfiguration != nil {
              Button("Sign Out", role: .destructive) {
                Task {
                  await sessionModel.signOut()
                  onDismiss()
                }
              }
            }
          }

          if liveConfiguration != nil {
            Section("Push Registration & Routing") {
              TextField("Debug Push Token", text: $debugPushToken)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
              Button("Register Debug Token (Console)") {
                Task {
                  do throws(AppError) {
                    let deviceId = try await pushCoordinator.registerDebugDeviceToken(
                      debugPushToken.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    pushStatusMessage = "Registered device ID: \(deviceId)"
                  } catch {
                    pushStatusMessage = "Registration error: \(error)"
                  }
                }
              }
              if let deviceId = pushCoordinator.currentDeviceId {
                Button("Remove Current Device (\(deviceId.prefix(8)))", role: .destructive) {
                  Task {
                    do throws(AppError) {
                      try await pushCoordinator.removeCurrentDevice()
                      pushStatusMessage = "Device removed"
                    } catch {
                      pushStatusMessage = "Removal error: \(error)"
                    }
                  }
                }
              }
              TextField("Push groupId", text: $pushGroupIdText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
              TextField("Push target", text: $pushTargetText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
              Button("Simulate Push Tap") {
                onDismiss()
                onSimulatePushTap(
                  pushGroupIdText.trimmingCharacters(in: .whitespacesAndNewlines),
                  pushTargetText.trimmingCharacters(in: .whitespacesAndNewlines)
                )
              }
              if let pushStatusMessage {
                Text(pushStatusMessage)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
            }
          }

          if let world {
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
                Task { await syncBehavior(world: world) }
              }

              Toggle("Has Snapshot", isOn: $hasSnapshot)
                .onChange(of: hasSnapshot) { _, _ in
                  Task { await syncBehavior(world: world) }
                }

              Picker("Failure", selection: $selectedFailureKind) {
                ForEach(FailureKind.allCases) { kind in
                  Text(kind.rawValue).tag(kind)
                }
              }
              .onChange(of: selectedFailureKind) { _, newKind in
                Task {
                  await syncBehavior(world: world)
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
                Task { await syncBehavior(world: world) }
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
          }

          Section("Invite Link & Gallery") {
            TextField("Invite URL (LinkRouter)", text: $linkURLText)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .keyboardType(.URL)
            Button("Open URL via LinkRouter") {
              let trimmed = linkURLText.trimmingCharacters(in: .whitespacesAndNewlines)
              if let url = URL(string: trimmed), onOpenLinkURL(url) {
                linkStatusMessage = nil
                onDismiss()
              } else {
                linkStatusMessage = "Rejected by LinkRouter (invalid host, scheme, port or path)"
              }
            }
            if let linkStatusMessage {
              Text(linkStatusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            if world != nil {
              TextField("Scripted Invite Token", text: $joinTokenText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
              Button("Open Scripted Join Screen (S12)") {
                let token = joinTokenText
                onDismiss()
                onOpenJoinToken(token)
              }
            }
            Button("Open Design System Gallery") {
              onDismiss()
              onOpenGallery()
            }
          }
        }
        .navigationTitle("Debug Panel")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            SheetCloseButton(action: onDismiss)
          }
        }
        .task {
          guard let world else { return }
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
      .spSheet(.form, embedsNavigationStack: true)
    }

    private func syncBehavior(world: FakeWorld) async {
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
