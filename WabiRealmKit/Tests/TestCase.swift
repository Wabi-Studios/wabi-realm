////////////////////////////////////////////////////////////////////////////
//
// Copyright 2014 WabiRealm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import WabiRealm
import WabiRealm.Dynamic
import WabiRealmKit
import XCTest

#if canImport(WabiRealmTestSupport)
  import WabiRealmKitTestSupport
  import WabiRealmTestSupport
#endif

func inMemoryRealm(_ inMememoryIdentifier: String) -> WabiRealm {
  return try! WabiRealm(configuration: WabiRealm.Configuration(inMemoryIdentifier: inMememoryIdentifier))
}

class TestCase: RLMTestCaseBase, @unchecked Sendable {
  @Locked var exceptionThrown = false
  var testDir: String!

  let queue = DispatchQueue(label: "background")

  @discardableResult
  func realmWithTestPath(configuration: WabiRealm.Configuration = WabiRealm.Configuration()) -> WabiRealm {
    var configuration = configuration
    configuration.fileURL = testRealmURL()
    return try! WabiRealm(configuration: configuration)
  }

  override class func tearDown() {
    RLMRealm.resetRealmState()
    super.tearDown()
  }

  override func invokeTest() {
    testDir = RLMRealmPathForFile(realmFilePrefix())

    do {
      try FileManager.default.removeItem(atPath: testDir)
    } catch {
      // The directory shouldn't actually already exist, so not an error
    }
    try! FileManager.default.createDirectory(at: URL(fileURLWithPath: testDir, isDirectory: true),
                                             withIntermediateDirectories: true, attributes: nil)

    let config = WabiRealm.Configuration(fileURL: defaultRealmURL())
    WabiRealm.Configuration.defaultConfiguration = config

    exceptionThrown = false
    autoreleasepool { super.invokeTest() }
    queue.sync {}

    if !exceptionThrown {
      XCTAssertFalse(RLMHasCachedRealmForPath(defaultRealmURL().path))
      XCTAssertFalse(RLMHasCachedRealmForPath(testRealmURL().path))
    }

    resetRealmState()

    do {
      try FileManager.default.removeItem(atPath: testDir)
    } catch {
      XCTFail("Unable to delete realm files")
    }

    // Verify that there are no remaining realm files after the test
    let parentDir = (testDir as NSString).deletingLastPathComponent
    for url in FileManager.default.enumerator(atPath: parentDir)! {
      let url = url as! NSString
      XCTAssertNotEqual(url.pathExtension, "realm", "Lingering realm file at \(parentDir)/\(url)")
      assert(url.pathExtension != "realm")
    }
  }

  func dispatchSyncNewThread(block: @escaping () -> Void) {
    queue.async {
      autoreleasepool {
        block()
      }
    }
    queue.sync {}
  }

  func assertThrows<T>(_ block: @autoclosure () -> T, named: String? = RLMExceptionName,
                       _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line)
  {
    exceptionThrown = true
    RLMAssertThrowsWithName(self, { _ = block() }, named, message, fileName, lineNumber)
  }

  func assertThrows<T>(_ block: @autoclosure () -> T, reason: String,
                       _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line)
  {
    exceptionThrown = true
    RLMAssertThrowsWithReason(self, { _ = block() }, reason, message, fileName, lineNumber)
  }

  func assertThrows<T>(_ block: @autoclosure () -> T, reasonMatching regexString: String,
                       _ message: String? = nil, fileName: String = #file, lineNumber: UInt = #line)
  {
    exceptionThrown = true
    RLMAssertThrowsWithReasonMatching(self, { _ = block() }, regexString, message, fileName, lineNumber)
  }

  private func realmFilePrefix() -> String {
    let name: String? = self.name
    return name!.trimmingCharacters(in: CharacterSet(charactersIn: "-[]"))
  }

  internal func testRealmURL() -> URL {
    return realmURLForFile("test.realm")
  }

  internal func defaultRealmURL() -> URL {
    return realmURLForFile("default.realm")
  }

  private func realmURLForFile(_ fileName: String) -> URL {
    let directory = URL(fileURLWithPath: testDir, isDirectory: true)
    return directory.appendingPathComponent(fileName, isDirectory: false)
  }
}

public extension WabiRealm {
  @discardableResult
  func create<T: Object>(_ type: T.Type, value: [String: Any], update: UpdatePolicy = .error) -> T {
    return create(type, value: value as Any, update: update)
  }

  @discardableResult
  func create<T: Object>(_ type: T.Type, value: [Any], update: UpdatePolicy = .error) -> T {
    return create(type, value: value as Any, update: update)
  }
}

public extension Object {
  convenience init(value: [String: Any]) {
    self.init(value: value as Any)
  }

  convenience init(value: [Any]) {
    self.init(value: value as Any)
  }
}

public extension AsymmetricObject {
  convenience init(value: [String: Any]) {
    self.init(value: value as Any)
  }

  convenience init(value: [Any]) {
    self.init(value: value as Any)
  }
}
