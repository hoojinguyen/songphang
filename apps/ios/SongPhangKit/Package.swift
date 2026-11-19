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
    .library(name: "Repositories", targets: ["Repositories"]),
    .library(name: "DesignSystem", targets: ["DesignSystem"]),
    .library(name: "PreviewSupport", targets: ["PreviewSupport"]),
    .library(name: "AuthFeature", targets: ["AuthFeature"]),
    .library(name: "GroupsFeature", targets: ["GroupsFeature"]),
    .library(name: "LedgerFeature", targets: ["LedgerFeature"]),
    .library(name: "AccountFeature", targets: ["AccountFeature"]),
    .library(name: "AppShell", targets: ["AppShell"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-openapi-generator", exact: "1.14.4"),
    .package(url: "https://github.com/apple/swift-openapi-runtime", exact: "1.13.4"),
    .package(url: "https://github.com/apple/swift-openapi-urlsession", exact: "1.4.0"),
  ],
  targets: [
    .target(
      name: "Domain",
      swiftSettings: sharedSwiftSettings
    ),
    .target(
      name: "GeneratedAPI",
      dependencies: [
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime")
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .treatAllWarnings(as: .error),
      ],
      plugins: [
        .plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")
      ]
    ),
    .target(
      name: "Repositories",
      dependencies: [
        "Domain",
        "GeneratedAPI",
        .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
        .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
      ],
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
      name: "LedgerFeature",
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
        "Repositories",
        "DesignSystem",
        "PreviewSupport",
        "AuthFeature",
        "GroupsFeature",
        "LedgerFeature",
        "AccountFeature",
      ],
      swiftSettings: mainActorSwiftSettings
    ),
  ]
)
