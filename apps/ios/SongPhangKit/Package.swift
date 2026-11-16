// swift-tools-version: 6.2
import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
  .swiftLanguageMode(.v6),
  .treatAllWarnings(as: .error),
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("InternalImportsByDefault"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("InferIsolatedConformances"),
]

let mainActorSwiftSettings: [SwiftSetting] =
  sharedSwiftSettings + [
    .defaultIsolation(MainActor.self)
  ]

let package = Package(
  name: "SongPhangKit",
  defaultLocalization: "vi",
  platforms: [.iOS(.v26)],
  products: [
    .library(name: "Domain", targets: ["Domain"]),
    .library(name: "DesignSystem", targets: ["DesignSystem"]),
    .library(name: "PreviewSupport", targets: ["PreviewSupport"]),
    .library(name: "AuthFeature", targets: ["AuthFeature"]),
    .library(name: "GroupsFeature", targets: ["GroupsFeature"]),
    .library(name: "AccountFeature", targets: ["AccountFeature"]),
    .library(name: "AppShell", targets: ["AppShell"]),
  ],
  targets: [
    .target(
      name: "Domain",
      swiftSettings: sharedSwiftSettings
    ),
    .target(
      name: "DesignSystem",
      dependencies: ["Domain"],
      resources: [
        .process("Resources")
      ],
      swiftSettings: mainActorSwiftSettings
    ),
    .target(
      name: "PreviewSupport",
      dependencies: ["Domain"],
      swiftSettings: mainActorSwiftSettings
    ),
    .target(
      name: "AuthFeature",
      dependencies: ["Domain", "DesignSystem", "PreviewSupport"],
      swiftSettings: mainActorSwiftSettings
    ),
    .target(
      name: "GroupsFeature",
      dependencies: ["Domain", "DesignSystem", "PreviewSupport"],
      swiftSettings: mainActorSwiftSettings
    ),
    .target(
      name: "AccountFeature",
      dependencies: ["Domain", "DesignSystem", "PreviewSupport"],
      swiftSettings: mainActorSwiftSettings
    ),
    .target(
      name: "AppShell",
      dependencies: [
        "Domain",
        "DesignSystem",
        "PreviewSupport",
        "AuthFeature",
        "GroupsFeature",
        "AccountFeature",
      ],
      swiftSettings: mainActorSwiftSettings
    ),
  ]
)
