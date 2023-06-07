// swift-tools-version:5.5

import Foundation
import PackageDescription

let coreVersionStr = "13.13.0"
let cocoaVersionStr = "10.40.5"

let coreVersionPieces = coreVersionStr.split(separator: ".")
let coreVersionExtra = coreVersionPieces[2].split(separator: "-")
let cxxSettings: [CXXSetting] = [
  .headerSearchPath("."),
  .headerSearchPath("include"),
  .define("REALM_SPM", to: "1"),
  .define("REALM_ENABLE_SYNC", to: "1"),
  .define("REALM_COCOA_VERSION", to: "@\"\(cocoaVersionStr)\""),
  .define("REALM_VERSION", to: "\"\(coreVersionStr)\""),
  .define("REALM_IOPLATFORMUUID", to: "@\"\(runCommand())\""),

  .define("REALM_DEBUG", .when(configuration: .debug)),
  .define("REALM_NO_CONFIG"),
  .define("REALM_INSTALL_LIBEXECDIR", to: ""),
  .define("REALM_ENABLE_ASSERTIONS", to: "1"),
  .define("REALM_ENABLE_ENCRYPTION", to: "1"),

  .define("REALM_VERSION_MAJOR", to: String(coreVersionPieces[0])),
  .define("REALM_VERSION_MINOR", to: String(coreVersionPieces[1])),
  .define("REALM_VERSION_PATCH", to: String(coreVersionExtra[0])),
  .define("REALM_VERSION_EXTRA", to: "\"\(coreVersionExtra.count > 1 ? String(coreVersionExtra[1]) : "")\""),
  .define("REALM_VERSION_STRING", to: "\"\(coreVersionStr)\""),
]
let testCxxSettings: [CXXSetting] = cxxSettings + [
  // Command-line `swift build` resolves header search paths
  // relative to the package root, while Xcode resolves them
  // relative to the target root, so we need both.
  .headerSearchPath("WabiRealm"),
  .headerSearchPath(".."),
]

// SPM requires all targets to explicitly include or exclude every file, which
// gets very awkward when we have four targets building from a single directory
let objectServerTestSources = [
  "Object-Server-Tests-Bridging-Header.h",
  "ObjectServerTests-Info.plist",
  "RLMAsymmetricSyncServerTests.mm",
  "RLMBSONTests.mm",
  "RLMCollectionSyncTests.mm",
  "RLMFlexibleSyncServerTests.mm",
  "RLMObjectServerPartitionTests.mm",
  "RLMObjectServerTests.mm",
  "RLMServerTestObjects.m",
  "RLMSyncTestCase.h",
  "RLMSyncTestCase.mm",
  "RLMUser+ObjectServerTests.h",
  "RLMUser+ObjectServerTests.mm",
  "RLMWatchTestUtility.h",
  "RLMWatchTestUtility.m",
  "EventTests.swift",
  "WabiRealmServer.swift",
  "SwiftAsymmetricSyncServerTests.swift",
  "SwiftCollectionSyncTests.swift",
  "SwiftFlexibleSyncServerTests.swift",
  "SwiftMongoClientTests.swift",
  "SwiftObjectServerPartitionTests.swift",
  "SwiftObjectServerTests.swift",
  "SwiftServerObjects.swift",
  "SwiftSyncTestCase.swift",
  "SwiftUIServerTests.swift",
  "TimeoutProxyServer.swift",
  "WatchTestUtility.swift",
  "certificates",
  "config_overrides.json",
  "include",
  "setup_baas.rb",
]

func objectServerTestSupportTarget(name: String, dependencies: [Target.Dependency], sources: [String]) -> Target {
  .target(
    name: name,
    dependencies: dependencies,
    path: "WabiRealm/ObjectServerTests",
    exclude: objectServerTestSources.filter { !sources.contains($0) },
    sources: sources,
    cxxSettings: testCxxSettings
  )
}

func objectServerTestTarget(name: String, sources: [String]) -> Target {
  .testTarget(
    name: name,
    dependencies: ["WabiRealmKit", "WabiRealmTestSupport", "WabiRealmSyncTestSupport", "WabiRealmKitSyncTestSupport"],
    path: "WabiRealm/ObjectServerTests",
    exclude: objectServerTestSources.filter { !sources.contains($0) },
    sources: sources,
    cxxSettings: testCxxSettings
  )
}

func runCommand() -> String {
  let task = Process()
  let pipe = Pipe()

  task.standardOutput = pipe
  task.standardError = pipe
  task.launchPath = "/usr/sbin/ioreg"
  task.arguments = ["-rd1", "-c", "IOPlatformExpertDevice"]
  task.standardInput = nil
  task.launch()

  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  let output = String(data: data, encoding: .utf8) ?? ""
  let range = NSRange(output.startIndex..., in: output)
  guard let regex = try? NSRegularExpression(pattern: ".*\\\"IOPlatformUUID\\\"\\s=\\s\\\"(.+)\\\"", options: .caseInsensitive),
        let firstMatch = regex.matches(in: output, range: range).first
  else {
    return ""
  }

  let matches = (0 ..< firstMatch.numberOfRanges).compactMap { ind -> String? in
    let matchRange = firstMatch.range(at: ind)
    if matchRange != range,
       let substringRange = Range(matchRange, in: output)
    {
      let capture = String(output[substringRange])
      return capture
    }
    return nil
  }
  return matches.last ?? ""
}

let package = Package(
  name: "WabiRealm",
  platforms: [
    .macOS(.v10_13),
    .iOS(.v11),
    .tvOS(.v11),
    .watchOS(.v4),
  ],
  products: [
    .library(
      name: "WabiRealm",
      targets: ["WabiRealm"]
    ),
    .library(
      name: "WabiRealmKit",
      targets: ["WabiRealm", "WabiRealmKit"]
    ),
  ],
  dependencies: [
    .package(name: "RealmDatabase", url: "https://github.com/realm/realm-core.git", .exact(Version(coreVersionStr)!)),
  ],
  targets: [
    .target(
      name: "WabiRealm",
      dependencies: [.product(name: "RealmCore", package: "RealmDatabase")],
      path: ".",
      exclude: [
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "Carthage",
        "Configuration",
        "Jenkinsfile.releasability",
        "LICENSE",
        "Package.swift",
        "README.md",
        "WabiRealm.podspec",
        "WabiRealm.xcodeproj",
        "WabiRealm/ObjectServerTests",
        "WabiRealm/RLMPlatform.h.in",
        "WabiRealm/WabiRealm-Info.plist",
        "WabiRealm/Swift/RLMSupport.swift",
        "WabiRealm/TestUtils",
        "WabiRealm/Tests",
        "WabiRealmKit",
        "WabiRealmKit.podspec",
        "SUPPORT.md",
        "build.sh",
        "ci_scripts/ci_post_clone.sh",
        "contrib",
        "dependencies.list",
        "docs",
        "examples",
        "include",
        "logo.png",
        "plugin",
        "scripts",
      ],
      sources: [
        "WabiRealm/RLMAccessor.mm",
        "WabiRealm/RLMAnalytics.mm",
        "WabiRealm/RLMArray.mm",
        "WabiRealm/RLMAsymmetricObject.mm",
        "WabiRealm/RLMAsyncTask.mm",
        "WabiRealm/RLMClassInfo.mm",
        "WabiRealm/RLMCollection.mm",
        "WabiRealm/RLMConstants.m",
        "WabiRealm/RLMDecimal128.mm",
        "WabiRealm/RLMDictionary.mm",
        "WabiRealm/RLMEmbeddedObject.mm",
        "WabiRealm/RLMError.mm",
        "WabiRealm/RLMEvent.mm",
        "WabiRealm/RLMLogger.mm",
        "WabiRealm/RLMManagedArray.mm",
        "WabiRealm/RLMManagedDictionary.mm",
        "WabiRealm/RLMManagedSet.mm",
        "WabiRealm/RLMMigration.mm",
        "WabiRealm/RLMObject.mm",
        "WabiRealm/RLMObjectBase.mm",
        "WabiRealm/RLMObjectId.mm",
        "WabiRealm/RLMObjectSchema.mm",
        "WabiRealm/RLMObjectStore.mm",
        "WabiRealm/RLMObservation.mm",
        "WabiRealm/RLMPredicateUtil.mm",
        "WabiRealm/RLMProperty.mm",
        "WabiRealm/RLMQueryUtil.mm",
        "WabiRealm/RLMRealm.mm",
        "WabiRealm/RLMRealmConfiguration.mm",
        "WabiRealm/RLMRealmUtil.mm",
        "WabiRealm/RLMResults.mm",
        "WabiRealm/RLMScheduler.mm",
        "WabiRealm/RLMSchema.mm",
        "WabiRealm/RLMSectionedResults.mm",
        "WabiRealm/RLMSet.mm",
        "WabiRealm/RLMSwiftCollectionBase.mm",
        "WabiRealm/RLMSwiftSupport.m",
        "WabiRealm/RLMSwiftValueStorage.mm",
        "WabiRealm/RLMThreadSafeReference.mm",
        "WabiRealm/RLMUUID.mm",
        "WabiRealm/RLMUpdateChecker.mm",
        "WabiRealm/RLMUtil.mm",
        "WabiRealm/RLMValue.mm",

        // Sync source files
        "WabiRealm/NSError+RLMSync.m",
        "WabiRealm/RLMApp.mm",
        "WabiRealm/RLMAPIKeyAuth.mm",
        "WabiRealm/RLMBSON.mm",
        "WabiRealm/RLMCredentials.mm",
        "WabiRealm/RLMEmailPasswordAuth.mm",
        "WabiRealm/RLMFindOneAndModifyOptions.mm",
        "WabiRealm/RLMFindOptions.mm",
        "WabiRealm/RLMMongoClient.mm",
        "WabiRealm/RLMMongoCollection.mm",
        "WabiRealm/RLMNetworkTransport.mm",
        "WabiRealm/RLMProviderClient.mm",
        "WabiRealm/RLMPushClient.mm",
        "WabiRealm/RLMRealm+Sync.mm",
        "WabiRealm/RLMSyncConfiguration.mm",
        "WabiRealm/RLMSyncManager.mm",
        "WabiRealm/RLMSyncSession.mm",
        "WabiRealm/RLMSyncSubscription.mm",
        "WabiRealm/RLMSyncUtil.mm",
        "WabiRealm/RLMUpdateResult.mm",
        "WabiRealm/RLMUser.mm",
        "WabiRealm/RLMUserAPIKey.mm",
      ],
      publicHeadersPath: "include",
      cxxSettings: cxxSettings
    ),
    .target(
      name: "WabiRealmKit",
      dependencies: ["WabiRealm"],
      path: "WabiRealmKit",
      exclude: [
        "Nonsync.swift",
        "WabiRealmKit-Info.plist",
        "Tests",
      ]
    ),
    .target(
      name: "WabiRealmTestSupport",
      dependencies: ["WabiRealm"],
      path: "WabiRealm/TestUtils",
      cxxSettings: testCxxSettings
    ),
    .target(
      name: "WabiRealmKitTestSupport",
      dependencies: ["WabiRealmKit", "WabiRealmTestSupport"],
      path: "WabiRealmKit/Tests",
      sources: ["TestUtils.swift"]
    ),
    .testTarget(
      name: "WabiRealmTests",
      dependencies: ["WabiRealm", "WabiRealmTestSupport"],
      path: "WabiRealm/Tests",
      exclude: [
        "PrimitiveArrayPropertyTests.tpl.m",
        "PrimitiveDictionaryPropertyTests.tpl.m",
        "PrimitiveRLMValuePropertyTests.tpl.m",
        "PrimitiveSetPropertyTests.tpl.m",
        "WabiRealmTests-Info.plist",
        "Swift",
        "SwiftUITestHost",
        "SwiftUITestHostUITests",
        "TestHost",
        "array_tests.py",
        "dictionary_tests.py",
        "fileformat-pre-null.realm",
        "mixed_tests.py",
        "set_tests.py",
        "SwiftUISyncTestHost",
        "SwiftUISyncTestHostUITests",
      ],
      cxxSettings: testCxxSettings
    ),
    .testTarget(
      name: "WabiRealmObjcSwiftTests",
      dependencies: ["WabiRealm", "WabiRealmTestSupport"],
      path: "WabiRealm/Tests/Swift",
      exclude: ["WabiRealmObjcSwiftTests-Info.plist"]
    ),
    .testTarget(
      name: "WabiRealmKitTests",
      dependencies: ["WabiRealmKit", "WabiRealmTestSupport", "WabiRealmKitTestSupport"],
      path: "WabiRealmKit/Tests",
      exclude: [
        "WabiRealmKitTests-Info.plist",
        "QueryTests.swift.gyb",
        "TestUtils.swift",
      ]
    ),

    // Object server tests have support code written in both obj-c and
    // Swift which is used by both the obj-c and swift test code. SPM
    // doesn't support mixed targets, so this ends up requiring four
    // different targets.
    objectServerTestSupportTarget(
      name: "WabiRealmSyncTestSupport",
      dependencies: ["WabiRealm", "WabiRealmKit", "WabiRealmTestSupport"],
      sources: ["RLMSyncTestCase.mm",
                "RLMUser+ObjectServerTests.mm",
                "RLMServerTestObjects.m"]
    ),
    objectServerTestSupportTarget(
      name: "WabiRealmKitSyncTestSupport",
      dependencies: ["WabiRealmKit", "WabiRealmTestSupport", "WabiRealmSyncTestSupport", "WabiRealmKitTestSupport"],
      sources: [
        "SwiftSyncTestCase.swift",
        "TimeoutProxyServer.swift",
        "WatchTestUtility.swift",
        "WabiRealmServer.swift",
        "SwiftServerObjects.swift",
      ]
    ),
    objectServerTestTarget(
      name: "SwiftObjectServerTests",
      sources: [
        "EventTests.swift",
        "SwiftAsymmetricSyncServerTests.swift",
        "SwiftCollectionSyncTests.swift",
        "SwiftFlexibleSyncServerTests.swift",
        "SwiftMongoClientTests.swift",
        "SwiftObjectServerPartitionTests.swift",
        "SwiftObjectServerTests.swift",
        "SwiftUIServerTests.swift",
      ]
    ),
    objectServerTestTarget(
      name: "ObjcObjectServerTests",
      sources: [
        "RLMAsymmetricSyncServerTests.mm",
        "RLMBSONTests.mm",
        "RLMCollectionSyncTests.mm",
        "RLMFlexibleSyncServerTests.mm",
        "RLMObjectServerPartitionTests.mm",
        "RLMObjectServerTests.mm",
        "RLMWatchTestUtility.m",
      ]
    ),
  ],
  cxxLanguageStandard: .cxx20
)
