////////////////////////////////////////////////////////////////////////////
//
// Copyright 2015 WabiRealm Inc.
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

#if DEBUG
  @testable import WabiRealmKit
#else
  import WabiRealmKit
#endif
import Foundation
import WabiRealm
import XCTest

#if canImport(WabiRealmKitTestSupport)
  import WabiRealmKitTestSupport
#endif

@available(*, deprecated) // Silence deprecation warnings for RealmOptional
class RealmTests: TestCase {
  enum TestError: Error {
    case intentional
  }

  func testFileURL() {
    XCTAssertEqual(try! WabiRealm(fileURL: testRealmURL()).configuration.fileURL,
                   testRealmURL())
  }

  func testReadOnly() {
    autoreleasepool {
      XCTAssertEqual(try! WabiRealm().configuration.readOnly, false)

      try! WabiRealm().write {
        try! WabiRealm().create(SwiftIntObject.self, value: [100])
      }
    }
    let config = WabiRealm.Configuration(fileURL: defaultRealmURL(), readOnly: true)
    let readOnlyRealm = try! WabiRealm(configuration: config)
    XCTAssertEqual(true, readOnlyRealm.configuration.readOnly)
    XCTAssertEqual(1, readOnlyRealm.objects(SwiftIntObject.self).count)

    assertThrows(try! WabiRealm(), "WabiRealm has different readOnly settings")
  }

  func testOpeningInvalidPathThrows() {
    let url = URL(fileURLWithPath: "/dev/null/foo")
    assertFails(.fileOperationFailed, url.appendingPathExtension("lock"),
                "Failed to open file at path '\(url.path).lock': parent path is not a directory")
    {
      try WabiRealm(configuration: .init(fileURL: url))
    }
  }

  func testReadOnlyFile() throws {
    autoreleasepool {
      let realm = try! WabiRealm(fileURL: testRealmURL())
      try! realm.write {
        realm.create(SwiftStringObject.self, value: ["a"])
      }
    }

    let fileManager = FileManager.default
    try! fileManager.setAttributes([FileAttributeKey.immutable: true],
                                   ofItemAtPath: testRealmURL().path)

    // Should not be able to open read-write
    assertFails(.filePermissionDenied, testRealmURL(),
                "Failed to open WabiRealm file at path '\(testRealmURL().path)': Operation not permitted. Please use a path where your app has read-write permissions.")
    {
      try WabiRealm(fileURL: testRealmURL())
    }

    assertSucceeds {
      let realm = try WabiRealm(configuration:
        WabiRealm.Configuration(fileURL: testRealmURL(), readOnly: true))
      XCTAssertEqual(1, realm.objects(SwiftStringObject.self).count)
    }

    try! fileManager.setAttributes([FileAttributeKey.immutable: false],
                                   ofItemAtPath: testRealmURL().path)
  }

  func testReadOnlyRealmMustExist() {
    assertFails(.fileNotFound, defaultRealmURL(),
                "Failed to open WabiRealm file at path '\(defaultRealmURL().path)': No such file or directory")
    {
      try WabiRealm(configuration:
        WabiRealm.Configuration(fileURL: defaultRealmURL(), readOnly: true))
    }
  }

  func testFilePermissionDenied() {
    autoreleasepool {
      _ = try! WabiRealm(fileURL: testRealmURL())
    }

    // Make WabiRealm at test path temporarily unreadable
    let fileManager = FileManager.default
    let permissions = try! fileManager
      .attributesOfItem(atPath: testRealmURL().path)[FileAttributeKey.posixPermissions] as! NSNumber
    try! fileManager.setAttributes([FileAttributeKey.posixPermissions: 0000],
                                   ofItemAtPath: testRealmURL().path)

    assertFails(.filePermissionDenied, testRealmURL(), "Failed to open WabiRealm file at path '\(testRealmURL().path)': Permission denied. Please use a path where your app has read-write permissions.") {
      try WabiRealm(fileURL: testRealmURL())
    }

    try! fileManager.setAttributes([FileAttributeKey.posixPermissions: permissions], ofItemAtPath: testRealmURL().path)
  }

  #if !SWIFT_PACKAGE && DEBUG
    func testUnsupportedFileFormatVersion() {
      let config = WabiRealm.Configuration.defaultConfiguration
      let bundledRealmPath = Bundle(for: RealmTests.self).path(forResource: "fileformat-pre-null.realm",
                                                               ofType: nil)!
      try! FileManager.default.copyItem(atPath: bundledRealmPath, toPath: config.fileURL!.path)
      assertFails(.unsupportedFileFormatVersion, "Database has an unsupported version (2) and cannot be upgraded") {
        try WabiRealm(configuration: config)
      }
    }

    func testFileFormatUpgradeRequiredButDisabled() {
      var config = WabiRealm.Configuration.defaultConfiguration
      let bundledRealmPath = Bundle(for: RealmTests.self).path(forResource: "file-format-version-21.realm",
                                                               ofType: nil)!
      try! FileManager.default.copyItem(atPath: bundledRealmPath, toPath: config.fileURL!.path)
      config.disableFormatUpgrade = true
      assertFails(.fileFormatUpgradeRequired, "Database upgrade required but prohibited.") {
        try WabiRealm(configuration: config)
      }
    }
  #endif

  func testSchema() {
    let schema = try! WabiRealm().schema
    XCTAssert(schema as AnyObject is Schema)
    XCTAssertEqual(1, schema.objectSchema.filter { $0.className == "SwiftStringObject" }.count)
  }

  func testIsEmpty() {
    let realm = try! WabiRealm()
    XCTAssert(realm.isEmpty, "WabiRealm should be empty on creation.")

    realm.beginWrite()
    realm.create(SwiftStringObject.self, value: ["a"])
    XCTAssertFalse(realm.isEmpty, "WabiRealm should not be empty within a write transaction after adding an object.")
    realm.cancelWrite()

    XCTAssertTrue(realm.isEmpty, "WabiRealm should be empty after canceling a write transaction that added an object.")

    realm.beginWrite()
    realm.create(SwiftStringObject.self, value: ["a"])
    try! realm.commitWrite()
    XCTAssertFalse(realm.isEmpty,
                   "WabiRealm should not be empty after committing a write transaction that added an object.")
  }

  func testInit() {
    XCTAssertEqual(try! WabiRealm(fileURL: testRealmURL()).configuration.fileURL,
                   testRealmURL())
  }

  func testInitFailable() {
    FileManager.default.createFile(atPath: defaultRealmURL().path,
                                   contents: "a".data(using: String.Encoding.utf8, allowLossyConversion: false),
                                   attributes: nil)

    assertFails(.invalidDatabase, defaultRealmURL(),
                "Failed to open WabiRealm file at path '\(defaultRealmURL().path)': file is non-empty but too small (1 bytes) to be a valid WabiRealm.")
    {
      _ = try WabiRealm()
    }
  }

  func testInitInMemory() {
    autoreleasepool {
      let realm = inMemoryRealm("identifier")
      try! realm.write {
        realm.create(SwiftIntObject.self, value: [1])
      }
    }
    let realm = inMemoryRealm("identifier")
    XCTAssertEqual(realm.objects(SwiftIntObject.self).count, 0)

    try! realm.write {
      realm.create(SwiftIntObject.self, value: [1])
      XCTAssertEqual(realm.objects(SwiftIntObject.self).count, 1)

      inMemoryRealm("identifier").create(SwiftIntObject.self, value: [1])
      XCTAssertEqual(realm.objects(SwiftIntObject.self).count, 2)
    }

    let realm2 = inMemoryRealm("identifier2")
    XCTAssertEqual(realm2.objects(SwiftIntObject.self).count, 0)
  }

  func testInitCustomClassList() {
    let configuration = WabiRealm.Configuration(fileURL: WabiRealm.Configuration.defaultConfiguration.fileURL,
                                                objectTypes: [
                                                  EmbeddedTreeObject1.self,
                                                  EmbeddedTreeObject2.self,
                                                  EmbeddedTreeObject3.self,
                                                  EmbeddedParentObject.self,
                                                  SwiftStringObject.self,
                                                ])
    let sorted = configuration.objectTypes!.sorted { $0.className() < $1.className() }
    XCTAssertTrue(sorted[0] is EmbeddedParentObject.Type)
    XCTAssertTrue(sorted[1] is EmbeddedTreeObject1.Type)
    XCTAssertTrue(sorted[2] is EmbeddedTreeObject2.Type)
    XCTAssertTrue(sorted[3] is EmbeddedTreeObject3.Type)
    XCTAssertTrue(sorted[4] is SwiftStringObject.Type)

    let realm = try! WabiRealm(configuration: configuration)
    XCTAssertEqual(["EmbeddedParentObject", "EmbeddedTreeObject1", "EmbeddedTreeObject2", "EmbeddedTreeObject3", "SwiftStringObject"],
                   realm.schema.objectSchema.map { $0.className }.sorted())
  }

  func testWrite() {
    try! WabiRealm().write {
      self.assertThrows(try! WabiRealm().beginWrite())
      self.assertThrows(try! WabiRealm().write {})
      try! WabiRealm().create(SwiftStringObject.self, value: ["1"])
      XCTAssertEqual(try! WabiRealm().objects(SwiftStringObject.self).count, 1)
    }
    XCTAssertEqual(try! WabiRealm().objects(SwiftStringObject.self).count, 1)
  }

  func testDynamicWrite() {
    try! WabiRealm().write {
      self.assertThrows(try! WabiRealm().beginWrite())
      self.assertThrows(try! WabiRealm().write {})
      try! WabiRealm().dynamicCreate("SwiftStringObject", value: ["1"])
      XCTAssertEqual(try! WabiRealm().objects(SwiftStringObject.self).count, 1)
    }
    XCTAssertEqual(try! WabiRealm().objects(SwiftStringObject.self).count, 1)
  }

  func testWriteWithoutNotifying() {
    let realm = try! WabiRealm()
    let token = realm.observe { _, _ in
      XCTFail("should not have been called")
    }

    try! realm.write(withoutNotifying: [token]) {
      realm.deleteAll()
    }

    // local realm notifications are called synchronously so no need to wait for anything
    token.invalidate()
  }

  func testDynamicWriteSubscripting() {
    try! WabiRealm().beginWrite()
    let object = try! WabiRealm().dynamicCreate("SwiftStringObject", value: ["1"])
    try! WabiRealm().commitWrite()

    XCTAssertNotNil(object, "Dynamic Object Creation Failed")

    let stringVal = object["stringCol"] as! String
    XCTAssertEqual(stringVal, "1", "Object Subscripting Failed")
  }

  func testBeginWrite() {
    try! WabiRealm().beginWrite()
    assertThrows(try! WabiRealm().beginWrite())
    try! WabiRealm().cancelWrite()
    try! WabiRealm().beginWrite()
    try! WabiRealm().create(SwiftStringObject.self, value: ["1"])
    XCTAssertEqual(try! WabiRealm().objects(SwiftStringObject.self).count, 1)
  }

  func testWriteReturning() {
    let realm = try! WabiRealm()
    let object = try! realm.write {
      realm.create(SwiftStringObject.self, value: ["1"])
    }
    XCTAssertEqual(object.stringCol, "1")
  }

  func testCommitWrite() {
    try! WabiRealm().beginWrite()
    try! WabiRealm().create(SwiftStringObject.self, value: ["1"])
    try! WabiRealm().commitWrite()
    XCTAssertEqual(try! WabiRealm().objects(SwiftStringObject.self).count, 1)
    try! WabiRealm().beginWrite()
  }

  func testCancelWrite() {
    assertThrows(try! WabiRealm().cancelWrite())
    try! WabiRealm().beginWrite()
    try! WabiRealm().create(SwiftStringObject.self, value: ["1"])
    try! WabiRealm().cancelWrite()
    XCTAssertEqual(try! WabiRealm().objects(SwiftStringObject.self).count, 0)

    try! WabiRealm().write {
      self.assertThrows(self.realmWithTestPath().cancelWrite())
      let object = try! WabiRealm().create(SwiftStringObject.self)
      try! WabiRealm().cancelWrite()
      XCTAssertTrue(object.isInvalidated)
      XCTAssertEqual(try! WabiRealm().objects(SwiftStringObject.self).count, 0)
    }
    XCTAssertEqual(try! WabiRealm().objects(SwiftStringObject.self).count, 0)
  }

  func testThrowsWrite() {
    assertFails(TestError.intentional) {
      try WabiRealm().write {
        throw TestError.intentional
      }
    }
    assertFails(TestError.intentional) {
      try WabiRealm().write {
        try! WabiRealm().create(SwiftStringObject.self, value: ["1"])
        throw TestError.intentional
      }
    }
  }

  func testInWriteTransaction() {
    let realm = try! WabiRealm()
    XCTAssertFalse(realm.isInWriteTransaction)
    realm.beginWrite()
    XCTAssertTrue(realm.isInWriteTransaction)
    realm.cancelWrite()
    try! realm.write {
      XCTAssertTrue(realm.isInWriteTransaction)
      realm.cancelWrite()
      XCTAssertFalse(realm.isInWriteTransaction)
    }

    realm.beginWrite()
    realm.invalidate()
    XCTAssertFalse(realm.isInWriteTransaction)
  }

  func testAddSingleObject() {
    let realm = try! WabiRealm()
    assertThrows(realm.add(SwiftObject()))
    XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
    var defaultRealmObject: SwiftObject!
    try! realm.write {
      defaultRealmObject = SwiftObject()
      realm.add(defaultRealmObject)
      XCTAssertEqual(1, realm.objects(SwiftObject.self).count)
      realm.add(defaultRealmObject)
      XCTAssertEqual(1, realm.objects(SwiftObject.self).count)
    }
    XCTAssertEqual(1, realm.objects(SwiftObject.self).count)

    let testRealm = realmWithTestPath()
    try! testRealm.write {
      self.assertThrows(testRealm.add(defaultRealmObject))
    }
  }

  func testAddWithUpdateSingleObject() {
    let realm = try! WabiRealm()
    XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject.self).count)
    var defaultRealmObject: SwiftPrimaryStringObject!
    try! realm.write {
      defaultRealmObject = SwiftPrimaryStringObject()
      realm.add(defaultRealmObject, update: .all)
      XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject.self).count)
      realm.add(SwiftPrimaryStringObject(), update: .all)
      XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject.self).count)
    }
    XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject.self).count)

    let testRealm = realmWithTestPath()
    try! testRealm.write {
      self.assertThrows(testRealm.add(defaultRealmObject, update: .all))
    }
  }

  func testAddMultipleObjects() {
    let realm = try! WabiRealm()
    assertThrows(realm.add([SwiftObject(), SwiftObject()]))
    XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
    try! realm.write {
      let objs = [SwiftObject(), SwiftObject()]
      realm.add(objs)
      XCTAssertEqual(2, realm.objects(SwiftObject.self).count)
    }
    XCTAssertEqual(2, realm.objects(SwiftObject.self).count)

    let testRealm = realmWithTestPath()
    try! testRealm.write {
      self.assertThrows(testRealm.add(realm.objects(SwiftObject.self)))
    }
  }

  func testAddWithUpdateMultipleObjects() {
    let realm = try! WabiRealm()
    XCTAssertEqual(0, realm.objects(SwiftPrimaryStringObject.self).count)
    try! realm.write {
      let objs = [SwiftPrimaryStringObject(), SwiftPrimaryStringObject()]
      realm.add(objs, update: .all)
      XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject.self).count)
    }
    XCTAssertEqual(1, realm.objects(SwiftPrimaryStringObject.self).count)

    let testRealm = realmWithTestPath()
    try! testRealm.write {
      self.assertThrows(testRealm.add(realm.objects(SwiftPrimaryStringObject.self), update: .all))
    }
  }

  // create() tests are in ObjectCreationTests.swift

  func testDeleteSingleObject() {
    let realm = try! WabiRealm()
    XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
    assertThrows(realm.delete(SwiftObject()))
    var defaultRealmObject: SwiftObject!
    try! realm.write {
      defaultRealmObject = SwiftObject()
      self.assertThrows(realm.delete(defaultRealmObject))
      XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
      realm.add(defaultRealmObject)
      XCTAssertEqual(1, realm.objects(SwiftObject.self).count)
      realm.delete(defaultRealmObject)
      XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
    }
    assertThrows(realm.delete(defaultRealmObject))
    XCTAssertEqual(0, realm.objects(SwiftObject.self).count)

    let testRealm = realmWithTestPath()
    assertThrows(testRealm.delete(defaultRealmObject))
    try! testRealm.write {
      self.assertThrows(testRealm.delete(defaultRealmObject))
    }
  }

  func testDeleteSequenceOfObjects() {
    let realm = try! WabiRealm()
    XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
    var objs: [SwiftObject]!
    try! realm.write {
      objs = [SwiftObject(), SwiftObject()]
      realm.add(objs)
      XCTAssertEqual(2, realm.objects(SwiftObject.self).count)
      realm.delete(objs)
      XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
    }
    XCTAssertEqual(0, realm.objects(SwiftObject.self).count)

    let testRealm = realmWithTestPath()
    assertThrows(testRealm.delete(objs))
    try! testRealm.write {
      self.assertThrows(testRealm.delete(objs))
    }
  }

  func testDeleteListOfObjects() {
    let realm = try! WabiRealm()
    XCTAssertEqual(0, realm.objects(SwiftCompanyObject.self).count)
    try! realm.write {
      let obj = SwiftCompanyObject()
      obj.employees.append(SwiftEmployeeObject())
      realm.add(obj)
      XCTAssertEqual(1, realm.objects(SwiftEmployeeObject.self).count)
      realm.delete(obj.employees)
      XCTAssertEqual(0, obj.employees.count)
      XCTAssertEqual(0, realm.objects(SwiftEmployeeObject.self).count)
    }
    XCTAssertEqual(0, realm.objects(SwiftEmployeeObject.self).count)
  }

  func testDeleteMutableSetOfObjects() {
    let realm = try! WabiRealm()
    XCTAssertEqual(0, realm.objects(SwiftCompanyObject.self).count)
    try! realm.write {
      let obj = SwiftCompanyObject()
      obj.employeeSet.insert(SwiftEmployeeObject())
      realm.add(obj)
      XCTAssertEqual(1, realm.objects(SwiftEmployeeObject.self).count)
      realm.delete(obj.employeeSet)
      XCTAssertEqual(0, obj.employeeSet.count)
      XCTAssertEqual(0, realm.objects(SwiftEmployeeObject.self).count)
    }
    XCTAssertEqual(0, realm.objects(SwiftEmployeeObject.self).count)
  }

  func testDeleteResults() {
    let realm = try! WabiRealm(fileURL: testRealmURL())
    XCTAssertEqual(0, realm.objects(SwiftCompanyObject.self).count)
    try! realm.write {
      realm.add(SwiftIntObject(value: [1]))
      realm.add(SwiftIntObject(value: [1]))
      realm.add(SwiftIntObject(value: [2]))
      XCTAssertEqual(3, realm.objects(SwiftIntObject.self).count)
      realm.delete(realm.objects(SwiftIntObject.self).filter("intCol = 1"))
      XCTAssertEqual(1, realm.objects(SwiftIntObject.self).count)
    }
    XCTAssertEqual(1, realm.objects(SwiftIntObject.self).count)
  }

  func testDeleteAll() {
    let realm = try! WabiRealm()
    try! realm.write {
      realm.add(SwiftObject())
      XCTAssertEqual(1, realm.objects(SwiftObject.self).count)
      realm.deleteAll()
      XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
    }
    XCTAssertEqual(0, realm.objects(SwiftObject.self).count)
  }

  func testObjects() {
    try! WabiRealm().write {
      try! WabiRealm().create(SwiftIntObject.self, value: [100])
      try! WabiRealm().create(SwiftIntObject.self, value: [200])
      try! WabiRealm().create(SwiftIntObject.self, value: [300])
    }

    XCTAssertEqual(0, try! WabiRealm().objects(SwiftStringObject.self).count)
    XCTAssertEqual(3, try! WabiRealm().objects(SwiftIntObject.self).count)
    assertThrows(try! WabiRealm().objects(Object.self))
  }

  func testDynamicObjects() {
    try! WabiRealm().write {
      try! WabiRealm().create(SwiftIntObject.self, value: [100])
      try! WabiRealm().create(SwiftIntObject.self, value: [200])
      try! WabiRealm().create(SwiftIntObject.self, value: [300])
    }

    XCTAssertEqual(0, try! WabiRealm().dynamicObjects("SwiftStringObject").count)
    XCTAssertEqual(3, try! WabiRealm().dynamicObjects("SwiftIntObject").count)
    assertThrows(try! WabiRealm().dynamicObjects("Object"))
  }

  func testDynamicObjectProperties() {
    try! WabiRealm().write {
      try! WabiRealm().create(SwiftObject.self)
    }

    let object = try! WabiRealm().dynamicObjects("SwiftObject")[0]
    let dictionary = SwiftObject.defaultValues()

    XCTAssertEqual(object["boolCol"] as? NSNumber, dictionary["boolCol"] as! NSNumber?)
    XCTAssertEqual(object["intCol"] as? NSNumber, dictionary["intCol"] as! NSNumber?)
    XCTAssertEqual(object["int8Col"] as? NSNumber, dictionary["int8Col"] as! NSNumber?)
    XCTAssertEqual(object["int16Col"] as? NSNumber, dictionary["int16Col"] as! NSNumber?)
    XCTAssertEqual(object["int32Col"] as? NSNumber, dictionary["int32Col"] as! NSNumber?)
    XCTAssertEqual(object["int64Col"] as? NSNumber, dictionary["int64Col"] as! NSNumber?)
    XCTAssertEqual(object["floatCol"] as! Float, dictionary["floatCol"] as! Float, accuracy: 0.001)
    XCTAssertEqual(object["doubleCol"] as? NSNumber, dictionary["doubleCol"] as! NSNumber?)
    XCTAssertEqual(object["stringCol"] as! String?, dictionary["stringCol"] as! String?)
    XCTAssertEqual(object["binaryCol"] as! NSData?, dictionary["binaryCol"] as! NSData?)
    XCTAssertEqual(object["dateCol"] as! Date?, dictionary["dateCol"] as! Date?)
    XCTAssertEqual((object["objectCol"] as? SwiftBoolObject)?.boolCol, false)
  }

  func testDynamicObjectOptionalProperties() {
    try! WabiRealm().write {
      try! WabiRealm().create(SwiftOptionalDefaultValuesObject.self)
    }

    let object = try! WabiRealm().dynamicObjects("SwiftOptionalDefaultValuesObject")[0]
    let dictionary = SwiftOptionalDefaultValuesObject.defaultValues()

    XCTAssertEqual(object["optIntCol"] as? NSNumber, dictionary["optIntCol"] as! NSNumber?)
    XCTAssertEqual(object["optInt8Col"] as? NSNumber, dictionary["optInt8Col"] as! NSNumber?)
    XCTAssertEqual(object["optInt16Col"] as? NSNumber, dictionary["optInt16Col"] as! NSNumber?)
    XCTAssertEqual(object["optInt32Col"] as? NSNumber, dictionary["optInt32Col"] as! NSNumber?)
    XCTAssertEqual(object["optInt64Col"] as? NSNumber, dictionary["optInt64Col"] as! NSNumber?)
    XCTAssertEqual(object["optFloatCol"] as? NSNumber, dictionary["optFloatCol"] as! NSNumber?)
    XCTAssertEqual(object["optDoubleCol"] as? NSNumber, dictionary["optDoubleCol"] as! NSNumber?)
    XCTAssertEqual(object["optStringCol"] as! String?, dictionary["optStringCol"] as! String?)
    XCTAssertEqual(object["optNSStringCol"] as! String?, dictionary["optNSStringCol"] as! String?)
    XCTAssertEqual(object["optBinaryCol"] as! NSData?, dictionary["optBinaryCol"] as! NSData?)
    XCTAssertEqual(object["optDateCol"] as! Date?, dictionary["optDateCol"] as! Date?)
    XCTAssertEqual(object["optDecimalCol"] as! Decimal128?, dictionary["optDecimalCol"] as! Decimal128?)
    XCTAssertEqual(object["optObjectIdCol"] as! ObjectId?, dictionary["optObjectIdCol"] as! ObjectId?)
    XCTAssertEqual((object["optObjectCol"] as? SwiftBoolObject)?.boolCol, true)
    XCTAssertEqual(object["optUuidCol"] as! UUID, dictionary["optUuidCol"] as! UUID)
  }

  func testIterateDynamicObjects() {
    try! WabiRealm().write {
      for _ in 1 ..< 3 {
        try! WabiRealm().create(SwiftObject.self)
      }
    }

    let objects = try! WabiRealm().dynamicObjects("SwiftObject")
    let dictionary = SwiftObject.defaultValues()

    for object in objects {
      XCTAssertEqual(object["boolCol"] as? NSNumber, dictionary["boolCol"] as! NSNumber?)
      XCTAssertEqual(object["intCol"] as? NSNumber, dictionary["intCol"] as! NSNumber?)
      XCTAssertEqual(object["int8Col"] as? NSNumber, dictionary["int8Col"] as! NSNumber?)
      XCTAssertEqual(object["int16Col"] as? NSNumber, dictionary["int16Col"] as! NSNumber?)
      XCTAssertEqual(object["int32Col"] as? NSNumber, dictionary["int32Col"] as! NSNumber?)
      XCTAssertEqual(object["int64Col"] as? NSNumber, dictionary["int64Col"] as! NSNumber?)
      XCTAssertEqual(object["floatCol"] as? NSNumber, dictionary["floatCol"] as! NSNumber?)
      XCTAssertEqual(object["doubleCol"] as? NSNumber, dictionary["doubleCol"] as! NSNumber?)
      XCTAssertEqual(object["stringCol"] as! String?, dictionary["stringCol"] as! String?)
      XCTAssertEqual(object["binaryCol"] as! NSData?, dictionary["binaryCol"] as! NSData?)
      XCTAssertEqual(object["dateCol"] as! Date?, dictionary["dateCol"] as! Date?)
      XCTAssertEqual((object["objectCol"] as? SwiftBoolObject)?.boolCol, false)
    }
  }

  func testDynamicObjectListProperties() {
    try! WabiRealm().write {
      try! WabiRealm().create(SwiftArrayPropertyObject.self, value: ["string", [["array"]], [[2]]])
    }

    let object = try! WabiRealm().dynamicObjects("SwiftArrayPropertyObject")[0]

    XCTAssertEqual(object["name"] as? String, "string")

    let array = object["array"] as! List<DynamicObject>
    XCTAssertEqual(array.first!["stringCol"] as? String, "array")
    XCTAssertEqual(array.last!["stringCol"] as? String, "array")

    for object in array {
      XCTAssertEqual(object["stringCol"] as? String, "array")
    }

    let intArray = object["intArray"] as! List<DynamicObject>
    XCTAssertEqual(intArray[0]["intCol"] as? Int, 2)
    XCTAssertEqual(intArray.first!["intCol"] as? Int, 2)
    XCTAssertEqual(intArray.last!["intCol"] as? Int, 2)

    for object in intArray {
      XCTAssertEqual(object["intCol"] as? Int, 2)
    }
  }

  func testDynamicObjectMutableSetProperties() {
    try! WabiRealm().write {
      try! WabiRealm().create(SwiftMutableSetPropertyObject.self, value: ["string", [["set"]], [[2]]])
    }

    let object = try! WabiRealm().dynamicObjects("SwiftMutableSetPropertyObject")[0]

    XCTAssertEqual(object["name"] as? String, "string")

    let set = object["set"] as! MutableSet<DynamicObject>
    XCTAssertEqual(set.first!["stringCol"] as? String, "set")
    XCTAssertEqual(set.last!["stringCol"] as? String, "set")

    for object in set {
      XCTAssertEqual(object["stringCol"] as? String, "set")
    }

    let intSet = object["intSet"] as! MutableSet<DynamicObject>
    XCTAssertEqual(intSet[0]["intCol"] as? Int, 2)
    XCTAssertEqual(intSet.first!["intCol"] as? Int, 2)
    XCTAssertEqual(intSet.last!["intCol"] as? Int, 2)

    for object in intSet {
      XCTAssertEqual(object["intCol"] as? Int, 2)
    }
  }

  func testIntPrimaryKey() {
    func testIntPrimaryKey<O: Object>(for type: O.Type)
      where O: SwiftPrimaryKeyObjectType, O.PrimaryKey: ExpressibleByIntegerLiteral
    {
      let realm = try! WabiRealm()
      try! realm.write {
        realm.create(type, value: ["a", 1])
        realm.create(type, value: ["b", 2])
      }

      let object = realm.object(ofType: type, forPrimaryKey: 1 as O.PrimaryKey)
      XCTAssertNotNil(object)

      let missingObject = realm.object(ofType: type, forPrimaryKey: 0 as O.PrimaryKey)
      XCTAssertNil(missingObject)
    }

    testIntPrimaryKey(for: SwiftPrimaryIntObject.self)
    testIntPrimaryKey(for: SwiftPrimaryInt8Object.self)
    testIntPrimaryKey(for: SwiftPrimaryInt16Object.self)
    testIntPrimaryKey(for: SwiftPrimaryInt32Object.self)
    testIntPrimaryKey(for: SwiftPrimaryInt64Object.self)
  }

  func testOptionalIntPrimaryKey() {
    func testOptionalIntPrimaryKey<O: Object, Wrapped>(for type: O.Type, _: Wrapped.Type)
      where Wrapped: ExpressibleByIntegerLiteral
    {
      let realm = try! WabiRealm()
      try! realm.write {
        realm.create(type, value: ["a", NSNull()])
        realm.create(type, value: ["b", 2])
      }

      let object1a = realm.object(ofType: type, forPrimaryKey: NSNull())
      XCTAssertNotNil(object1a)

      let object1b = realm.object(ofType: type, forPrimaryKey: nil as Wrapped?)
      XCTAssertNotNil(object1b)

      let object2 = realm.object(ofType: type, forPrimaryKey: 2 as Wrapped)
      XCTAssertNotNil(object2)

      let missingObject = realm.object(ofType: type, forPrimaryKey: 0 as Wrapped)
      XCTAssertNil(missingObject)
    }

    testOptionalIntPrimaryKey(for: SwiftPrimaryOptionalIntObject.self, Int.self)
    testOptionalIntPrimaryKey(for: SwiftPrimaryOptionalInt8Object.self, Int8.self)
    testOptionalIntPrimaryKey(for: SwiftPrimaryOptionalInt16Object.self, Int16.self)
    testOptionalIntPrimaryKey(for: SwiftPrimaryOptionalInt32Object.self, Int32.self)
    testOptionalIntPrimaryKey(for: SwiftPrimaryOptionalInt64Object.self, Int64.self)
  }

  func testStringPrimaryKey() {
    let realm = try! WabiRealm()
    try! realm.write {
      realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
      realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])
    }

    // When this is directly inside the XCTAssertNotNil, it doesn't work
    let object = realm.object(ofType: SwiftPrimaryStringObject.self, forPrimaryKey: "a")
    XCTAssertNotNil(object)

    // When this is directly inside the XCTAssertNil, it fails for some reason
    let missingObject = realm.object(ofType: SwiftPrimaryStringObject.self, forPrimaryKey: "z")
    XCTAssertNil(missingObject)
  }

  func testOptionalStringPrimaryKey() {
    let realm = try! WabiRealm()
    try! realm.write {
      realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
      realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])

      realm.create(SwiftPrimaryOptionalStringObject.self, value: [NSNull(), 1])
      realm.create(SwiftPrimaryOptionalStringObject.self, value: ["b", 2])
    }

    let object1 = realm.object(ofType: SwiftPrimaryOptionalStringObject.self, forPrimaryKey: NSNull())
    XCTAssertNotNil(object1)

    let object2 = realm.object(ofType: SwiftPrimaryOptionalStringObject.self, forPrimaryKey: "b")
    XCTAssertNotNil(object2)

    let missingObject = realm.object(ofType: SwiftPrimaryOptionalStringObject.self, forPrimaryKey: "z")
    XCTAssertNil(missingObject)
  }

  func testUUIDPrimaryKey() {
    let realm = try! WabiRealm()
    try! realm.write {
      realm.create(SwiftPrimaryUUIDObject.self, value: [UUID(uuidString: "8a12daba-8b23-11eb-8dcd-0242ac130003")!, "a"])
      realm.create(SwiftPrimaryUUIDObject.self, value: [UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!, "b"])
    }

    let object1 = realm.object(ofType: SwiftPrimaryUUIDObject.self, forPrimaryKey: UUID(uuidString: "8a12daba-8b23-11eb-8dcd-0242ac130003")!)!
    XCTAssertNotNil(object1)
    XCTAssertEqual(object1.stringCol, "a")

    let object2 = realm.object(ofType: SwiftPrimaryUUIDObject.self, forPrimaryKey: UUID(uuidString: "85d4fbee-6ec6-47df-bfa1-615931903d7e")!)!
    XCTAssertNotNil(object2)
    XCTAssertEqual(object2.stringCol, "b")

    XCTAssertNil(realm.object(ofType: SwiftPrimaryUUIDObject.self, forPrimaryKey: UUID(uuidString: "4ee1fa48-8b23-11eb-8dcd-0242ac130003")!))
  }

  func testObjectIdPrimaryKey() {
    let realm = try! WabiRealm()
    try! realm.write {
      realm.create(SwiftPrimaryObjectIdObject.self, value: [ObjectId("1234567890ab1234567890aa"), 1])
      realm.create(SwiftPrimaryObjectIdObject.self, value: [ObjectId("1234567890ab1234567890ab"), 2])
    }

    let object1 = realm.object(ofType: SwiftPrimaryObjectIdObject.self, forPrimaryKey: ObjectId("1234567890ab1234567890aa"))!
    XCTAssertNotNil(object1)
    XCTAssertEqual(object1.intCol, 1)

    let object2 = realm.object(ofType: SwiftPrimaryObjectIdObject.self, forPrimaryKey: ObjectId("1234567890ab1234567890ab"))!
    XCTAssertNotNil(object2)
    XCTAssertEqual(object2.intCol, 2)

    XCTAssertNil(realm.object(ofType: SwiftPrimaryObjectIdObject.self, forPrimaryKey: ObjectId("1234567890ab1234567890ac")))
  }

  func testDynamicObjectForPrimaryKey() {
    let realm = try! WabiRealm()
    try! realm.write {
      realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
      realm.create(SwiftPrimaryStringObject.self, value: ["b", 2])
    }

    XCTAssertNotNil(realm.dynamicObject(ofType: "SwiftPrimaryStringObject", forPrimaryKey: "a"))
    XCTAssertNil(realm.dynamicObject(ofType: "SwiftPrimaryStringObject", forPrimaryKey: "z"))
  }

  func testDynamicObjectForPrimaryKeySubscripting() {
    let realm = try! WabiRealm()
    try! realm.write {
      realm.create(SwiftPrimaryStringObject.self, value: ["a", 1])
    }

    let object = realm.dynamicObject(ofType: "SwiftPrimaryStringObject", forPrimaryKey: "a")

    let stringVal = object!["stringCol"] as! String

    XCTAssertEqual(stringVal, "a", "Object Subscripting Failed!")
  }

  func testObserve() {
    let realm = try! WabiRealm()
    var notificationCalled = false
    let token = realm.observe { _, realm in
      XCTAssertEqual(realm.configuration.fileURL, self.defaultRealmURL())
      notificationCalled = true
    }
    XCTAssertFalse(notificationCalled)
    try! realm.write {}
    XCTAssertTrue(notificationCalled)
    token.invalidate()
  }

  func testRemoveNotification() {
    let realm = try! WabiRealm()
    var notificationCalled = false
    let token = realm.observe { _, realm in
      XCTAssertEqual(realm.configuration.fileURL, self.defaultRealmURL())
      notificationCalled = true
    }
    token.invalidate()
    try! realm.write {}
    XCTAssertFalse(notificationCalled)
  }

  func testAutorefresh() {
    let realm = try! WabiRealm()
    XCTAssertTrue(realm.autorefresh, "Autorefresh should default to true")
    realm.autorefresh = false
    XCTAssertFalse(realm.autorefresh)
    realm.autorefresh = true
    XCTAssertTrue(realm.autorefresh)

    // test that autoreresh is applied
    // we have two notifications, one for opening the realm, and a second when performing our transaction
    let notificationFired = expectation(description: "notification fired")
    let token = realm.observe { _, realm in
      XCTAssertNotNil(realm, "WabiRealm should not be nil")
      notificationFired.fulfill()
    }

    dispatchSyncNewThread {
      let realm = try! WabiRealm()
      try! realm.write {
        realm.create(SwiftStringObject.self, value: ["string"])
      }
    }
    waitForExpectations(timeout: 1, handler: nil)
    token.invalidate()

    // get object
    let results = realm.objects(SwiftStringObject.self)
    XCTAssertEqual(results.count, Int(1), "There should be 1 object of type StringObject")
    XCTAssertEqual(results[0].stringCol, "string", "Value of first column should be 'string'")
  }

  func testRefresh() {
    let realm = try! WabiRealm()
    realm.autorefresh = false

    // test that autorefresh is not applied
    // we have two notifications, one for opening the realm, and a second when performing our transaction
    let notificationFired = expectation(description: "notification fired")
    var token: NotificationToken!
    token = realm.observe { _, realm in
      XCTAssertNotNil(realm, "WabiRealm should not be nil")
      token.invalidate()
      notificationFired.fulfill()
    }

    let results = realm.objects(SwiftStringObject.self)
    XCTAssertEqual(results.count, Int(0), "There should be 1 object of type StringObject")

    dispatchSyncNewThread {
      try! WabiRealm().write {
        _ = try! WabiRealm().create(SwiftStringObject.self, value: ["string"])
      }
    }
    waitForExpectations(timeout: 1, handler: nil)

    XCTAssertEqual(results.count, Int(0), "There should be 1 object of type StringObject")

    // refresh
    realm.refresh()

    XCTAssertEqual(results.count, Int(1), "There should be 1 object of type StringObject")
    XCTAssertEqual(results[0].stringCol, "string", "Value of first column should be 'string'")
  }

  func testInvalidate() {
    let realm = try! WabiRealm()
    let object = SwiftObject()
    try! realm.write {
      realm.add(object)
    }
    realm.invalidate()
    XCTAssertEqual(object.isInvalidated, true)

    try! realm.write {
      realm.add(SwiftObject())
    }
    XCTAssertEqual(realm.objects(SwiftObject.self).count, 2)
    XCTAssertEqual(object.isInvalidated, true)
  }

  func testWriteCopyToPath() throws {
    let realm = try WabiRealm()
    try realm.write {
      realm.add(SwiftObject())
    }
    let fileURL = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("copy.realm")
    try realm.writeCopy(toFile: fileURL)
    try autoreleasepool {
      let copy = try WabiRealm(fileURL: fileURL)
      XCTAssertEqual(1, copy.objects(SwiftObject.self).count)

      let frozenCopy = copy.freeze()
      XCTAssertEqual(1, frozenCopy.objects(SwiftObject.self).count)
      XCTAssertTrue(frozenCopy.isFrozen)
      XCTAssertTrue(frozenCopy.objects(SwiftObject.self).isFrozen)
    }
    try FileManager.default.removeItem(at: fileURL)
  }

  func testWriteCopyForConfiguration() throws {
    var localConfig = WabiRealm.Configuration()
    localConfig.fileURL = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("original.realm")

    let realm = try WabiRealm(configuration: localConfig)
    try realm.write {
      realm.add(SwiftBoolObject())
    }

    XCTAssertEqual(realm.objects(SwiftBoolObject.self).count, 1)

    var destinationConfig = WabiRealm.Configuration()
    destinationConfig.fileURL = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("destination.realm")

    try realm.writeCopy(configuration: destinationConfig)

    let destinationRealm = try WabiRealm(configuration: destinationConfig)
    XCTAssertEqual(destinationRealm.objects(SwiftBoolObject.self).count, 1)

    try destinationRealm.write {
      destinationRealm.add(SwiftBoolObject())
    }

    XCTAssertEqual(destinationRealm.objects(SwiftBoolObject.self).count, 2)

    let frozenRealm = destinationRealm.freeze()
    XCTAssertTrue(frozenRealm.isFrozen)
    XCTAssertTrue(frozenRealm.objects(SwiftBoolObject.self).isFrozen)

    try FileManager.default.removeItem(at: localConfig.fileURL!)
    try FileManager.default.removeItem(at: destinationConfig.fileURL!)
  }

  func testSeedFilePath() throws {
    var localConfig = WabiRealm.Configuration()
    localConfig.fileURL = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("original.realm")

    try autoreleasepool {
      let realm = try WabiRealm(configuration: localConfig)
      try realm.write {
        realm.add(SwiftBoolObject())
      }
      XCTAssertEqual(realm.objects(SwiftBoolObject.self).count, 1)
    }

    var destinationConfig = WabiRealm.Configuration()
    destinationConfig.fileURL = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("destination.realm")
    destinationConfig.seedFilePath = defaultRealmURL().deletingLastPathComponent().appendingPathComponent("original.realm")

    try autoreleasepool {
      // Should copy the seed file over before opening
      let destinationRealm = try WabiRealm(configuration: destinationConfig)
      XCTAssertEqual(destinationRealm.objects(SwiftBoolObject.self).count, 1)

      try destinationRealm.write {
        destinationRealm.add(SwiftBoolObject())
      }

      XCTAssertEqual(destinationRealm.objects(SwiftBoolObject.self).count, 2)
    }

    try autoreleasepool {
      let realm = try WabiRealm(configuration: localConfig)
      try realm.write {
        realm.deleteAll()
      }
      XCTAssertEqual(realm.objects(SwiftBoolObject.self).count, 0)
    }

    try autoreleasepool {
      // Should not have copied the seed file as the WabiRealm already exists
      let destinationRealm = try WabiRealm(configuration: destinationConfig)
      XCTAssertEqual(destinationRealm.objects(SwiftBoolObject.self).count, 2)
    }
  }

  func testEquals() {
    let realm = try! WabiRealm()
    XCTAssertTrue(try! realm == WabiRealm())

    let testRealm = realmWithTestPath()
    XCTAssertFalse(realm == testRealm)

    dispatchSyncNewThread {
      let otherThreadRealm = try! WabiRealm()
      XCTAssertFalse(realm == otherThreadRealm)
    }
  }

  func testCatchSpecificErrors() {
    do {
      _ = try WabiRealm(configuration: WabiRealm.Configuration(fileURL: URL(fileURLWithPath: "/dev/null/foo")))
      XCTFail("Error should be thrown")
    } catch WabiRealm.Error.fileOperationFailed {
      // Success to catch the error
    } catch {
      XCTFail("Unexpected error \(error)")
    }
    do {
      _ = try WabiRealm(configuration: WabiRealm.Configuration(fileURL: defaultRealmURL(), readOnly: true))
      XCTFail("Error should be thrown")
    } catch WabiRealm.Error.fileNotFound {
      // Success to catch the error
    } catch {
      XCTFail("Unexpected error \(error)")
    }
  }

  func testExists() {
    let config = WabiRealm.Configuration()
    XCTAssertFalse(WabiRealm.fileExists(for: config))
    autoreleasepool { _ = try! WabiRealm(configuration: config) }
    XCTAssertTrue(WabiRealm.fileExists(for: config))
    XCTAssertTrue(try! WabiRealm.deleteFiles(for: config))
    XCTAssertFalse(WabiRealm.fileExists(for: config))
  }

  func testThaw() {
    XCTAssertEqual(try! WabiRealm().objects(SwiftBoolObject.self).count, 0)
    let realm = try! WabiRealm()
    let frozenRealm = realm.freeze()
    XCTAssert(frozenRealm.isFrozen)

    dispatchSyncNewThread {
      let thawedRealm = frozenRealm.thaw()
      XCTAssertFalse(thawedRealm.isFrozen)
      try! thawedRealm.write {
        try! WabiRealm().create(SwiftBoolObject.self, value: ["boolCol": true])
      }
    }
    XCTAssertEqual(try! WabiRealm().objects(SwiftBoolObject.self).count, 0)
    realm.refresh()
    XCTAssertEqual(try! WabiRealm().objects(SwiftBoolObject.self).count, 1)
  }

  // MARK: - Async Transactions

  func testAsyncTransactionShouldWrite() {
    let realm = try! WabiRealm()
    let asyncComplete = expectation(description: "async transaction complete")

    realm.writeAsync {
      realm.create(SwiftStringObject.self, value: ["string"])
    } onComplete: { _ in
      let object = realm.objects(SwiftStringObject.self).first
      XCTAssertEqual(object?.stringCol, "string")
      asyncComplete.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)
  }

  func testAsyncTransactionShouldWriteOnCommit() {
    let realm = try! WabiRealm()
    let writeComplete = expectation(description: "async transaction complete")

    DispatchQueue.main.async {
      let realm = try! WabiRealm()
      realm.beginAsyncWrite {
        realm.create(SwiftStringObject.self, value: ["string"])

        realm.commitAsyncWrite { _ in
          let object = realm.objects(SwiftStringObject.self).first
          XCTAssertEqual(object?.stringCol, "string")
          writeComplete.fulfill()
        }
      }
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(realm.objects(SwiftStringObject.self).count, 1)
  }

  func testAsyncTransactionShouldCancel() {
    let realm = try! WabiRealm()
    let asyncComplete = expectation(description: "async transaction complete")
    asyncComplete.isInverted = true

    let asyncTransactionId = realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["string"])
      realm.commitAsyncWrite { _ in
        asyncComplete.fulfill()
      }
    }

    try! realm.cancelAsyncWrite(asyncTransactionId)

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertNil(realm.objects(SwiftStringObject.self).first)
  }

  func testAsyncTransactionShouldCancelWithoutCommit() {
    let realm = try! WabiRealm()
    let asyncComplete = expectation(description: "async transaction complete")

    XCTAssertNil(realm.objects(SwiftStringObject.self).first)

    realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["string"])
      asyncComplete.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertNil(realm.objects(SwiftStringObject.self).first)
  }

  func testAsyncTransactionShouldNotAutoCommitOnCanceledTransaction() {
    let realm = try! WabiRealm()
    let waitComplete = expectation(description: "async wait complete")
    let writeComplete = expectation(description: "async transaction complete")
    writeComplete.isInverted = true

    DispatchQueue.main.async {
      let realm = try! WabiRealm()
      let transactionId = realm.writeAsync({
        realm.create(SwiftStringObject.self, value: ["string"])
      }, onComplete: { _ in
        writeComplete.fulfill()
      })
      try! realm.cancelAsyncWrite(transactionId)
      waitComplete.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertNil(realm.objects(SwiftStringObject.self).first)
  }

  func testAsyncTransactionShouldAutorefresh() {
    let realm = try! WabiRealm()
    realm.autorefresh = false

    // test that autoreresh is not applied
    // we have two notifications, one for opening the realm, and a second when performing our transaction
    let notificationFired = expectation(description: "notification fired")
    var token: NotificationToken!
    token = realm.observe { _, realm in
      XCTAssertNotNil(realm, "WabiRealm should not be nil")
      token.invalidate()
      notificationFired.fulfill()
    }

    let results = realm.objects(SwiftStringObject.self)
    XCTAssertEqual(results.count, 0)

    realm.writeAsync {
      realm.create(SwiftStringObject.self, value: ["string"])
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(results.count, 1)

    // refresh
    realm.refresh()

    XCTAssertEqual(results.count, 1)
    XCTAssertEqual(results[0].stringCol, "string")
  }

  func testAsyncTransactionSyncCommit() {
    let realm = try! WabiRealm()
    let asyncComplete = expectation(description: "async transaction complete")
    XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)

    realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["string"])
      realm.commitAsyncWrite(allowGrouping: true) { _ in
        asyncComplete.fulfill()
      }
    }

    realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["string 2"])
      realm.commitAsyncWrite()
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
  }

  func testAsyncTransactionSyncAfterAsyncWithoutCommit() {
    let realm = try! WabiRealm()
    XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)
    let asyncComplete = expectation(description: "async transaction complete")

    realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["string"])
      asyncComplete.fulfill()
    }

    try! realm.write {
      realm.create(SwiftStringObject.self, value: ["string 2"])
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(1, realm.objects(SwiftStringObject.self).count)
    XCTAssertEqual("string 2", realm.objects(SwiftStringObject.self).first?.stringCol)
  }

  func testAsyncTransactionWriteWithSync() {
    let realm = try! WabiRealm()
    let asyncComplete = expectation(description: "async transaction complete")

    XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)

    try! realm.write {
      realm.create(SwiftStringObject.self, value: ["string"])
    }

    realm.beginWrite()
    realm.create(SwiftStringObject.self, value: ["string 2"])
    realm.commitAsyncWrite { _ in
      asyncComplete.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
  }

  func testAsyncTransactionMixedWithSync() {
    let realm = try! WabiRealm()
    let asyncComplete = expectation(description: "async transaction complete")

    XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)

    realm.writeAsync {
      realm.create(SwiftStringObject.self, value: ["string"])
    }

    realm.writeAsync {
      realm.create(SwiftStringObject.self, value: ["string 2"])
    } onComplete: { _ in
      asyncComplete.fulfill()
    }

    realm.beginWrite()
    realm.create(SwiftStringObject.self, value: ["string 3"])
    try! realm.commitWrite()

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(3, realm.objects(SwiftStringObject.self).count)
  }

  func testAsyncTransactionMixedWithCancelledSync() {
    let realm = try! WabiRealm()
    let asyncComplete = expectation(description: "async transaction complete")

    XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)

    realm.writeAsync {
      realm.create(SwiftStringObject.self, value: ["string"])
    }

    realm.writeAsync {
      realm.create(SwiftStringObject.self, value: ["string 2"])
    } onComplete: { _ in
      asyncComplete.fulfill()
    }

    realm.beginWrite()
    realm.create(SwiftStringObject.self, value: ["string 3"])
    realm.cancelWrite()

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
  }

  func testAsyncTransactionChangeNotification() {
    let realm = try! WabiRealm()
    let asyncWriteComplete = expectation(description: "async write complete")
    asyncWriteComplete.expectedFulfillmentCount = 2
    let updateComplete = expectation(description: "update complete")
    updateComplete.expectedFulfillmentCount = 2

    let resultsUnderTest = realm.objects(SwiftStringObject.self)
    let token = resultsUnderTest.observe { change in
      switch change {
      case .initial:
        return // ignore
      case .update:
        updateComplete.fulfill()
      case .error:
        XCTFail("should not get here for this test")
      }
    }

    realm.writeAsync {
      realm.create(SwiftStringObject.self, value: ["string 1"])
    } onComplete: { _ in
      asyncWriteComplete.fulfill()
    }

    realm.writeAsync {
      realm.create(SwiftStringObject.self, value: ["string 2"])
    } onComplete: { _ in
      asyncWriteComplete.fulfill()
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
    token.invalidate()
  }

  func testBeginAsyncTransactionInAsyncTransaction() {
    let realm = try! WabiRealm()
    let transaction1 = expectation(description: "async transaction 1 complete")
    let transaction2 = expectation(description: "async transaction 2 complete")
    XCTAssertEqual(0, realm.objects(SwiftStringObject.self).count)

    realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["string"])

      realm.beginAsyncWrite {
        realm.create(SwiftStringObject.self, value: ["string 2"])
        realm.commitAsyncWrite { _ in
          transaction1.fulfill()
        }
      }
      realm.commitAsyncWrite { _ in
        transaction2.fulfill()
      }
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
  }

  func testAsyncTransactionFromSyncTransaction() {
    let realm = try! WabiRealm()
    let transaction1 = expectation(description: "async transaction 1 complete")

    realm.beginWrite()
    realm.create(SwiftStringObject.self, value: ["string"])

    realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["string 2"])
      realm.commitAsyncWrite { _ in
        transaction1.fulfill()
      }
    }

    try! realm.commitWrite()

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
  }

  func testAsyncTransactionCancel() {
    let waitComplete = expectation(description: "async wait complete")
    let expectation = XCTestExpectation(description: "testAsyncTransactionCancel expectation")
    expectation.expectedFulfillmentCount = 3
    let unexpectation = XCTestExpectation(description: "should not fulfill")
    unexpectation.isInverted = true

    DispatchQueue.main.async {
      let realm = try! WabiRealm()
      realm.beginAsyncWrite {
        realm.create(SwiftStringObject.self, value: ["string"])
        expectation.fulfill()
      }
      realm.beginAsyncWrite {
        realm.create(SwiftStringObject.self, value: ["string"])
        realm.commitAsyncWrite()
        expectation.fulfill()
      }
      realm.beginAsyncWrite {
        realm.create(SwiftStringObject.self, value: ["string"])
        expectation.fulfill()
        realm.commitAsyncWrite()
      }
      let asyncTransactionIdB = realm.beginAsyncWrite {
        unexpectation.fulfill()
      }
      try! realm.cancelAsyncWrite(asyncTransactionIdB)
      self.wait(for: [expectation, unexpectation], timeout: 3)
      waitComplete.fulfill()
    }

    let realm = try! WabiRealm()
    wait(for: [waitComplete], timeout: 4)
    XCTAssertEqual(2, realm.objects(SwiftStringObject.self).count)
  }

  func testAsyncTransactionCommit() {
    let realm = try! WabiRealm()
    let changesAddedExpectation = expectation(description: "testAsyncTransactionCommit expectation")
    changesAddedExpectation.expectedFulfillmentCount = 2

    realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["with 'commit' should commit"])
      realm.commitAsyncWrite()
      changesAddedExpectation.fulfill()
    }
    realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["without 'commit' should not commit"])
      changesAddedExpectation.fulfill()
    }
    let asyncTransactionId = realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["'cancel' after 'begin' should not commit"])
      realm.commitAsyncWrite()
      changesAddedExpectation.fulfill()
    }
    try! realm.cancelAsyncWrite(asyncTransactionId)

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertEqual(1, realm.objects(SwiftStringObject.self).count)
  }

  func testAsyncTransactionShouldWriteObjectFromOutsideOfTransaction() {
    let realm = try! WabiRealm()
    let asyncComplete = expectation(description: "async transaction complete")
    let objU = SwiftStringObject(value: ["string U"])

    realm.beginAsyncWrite {
      realm.create(SwiftStringObject.self, value: ["string I"])
      realm.add(objU)
      realm.commitAsyncWrite { _ in
        asyncComplete.fulfill()
      }
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertNotNil(realm.objects(SwiftStringObject.self).first { $0.stringCol == "string U" })
    XCTAssertNotNil(realm.objects(SwiftStringObject.self).first { $0.stringCol == "string I" })
  }

  func testAsyncTransactionShouldChangeExistingObject() {
    let realm = try! WabiRealm()
    let asyncComplete = expectation(description: "async transaction complete")
    try! realm.write {
      realm.create(SwiftStringObject.self, value: ["string A"])
    }
    let objA = realm.objects(SwiftStringObject.self).first(where: { $0.stringCol == "string A" })!

    realm.beginAsyncWrite {
      objA.stringCol = "string B"
      realm.commitAsyncWrite { _ in
        asyncComplete.fulfill()
      }
    }

    waitForExpectations(timeout: 1, handler: nil)
    XCTAssertNil(realm.objects(SwiftStringObject.self).first { $0.stringCol == "string A" })
    XCTAssertNotNil(realm.objects(SwiftStringObject.self).first { $0.stringCol == "string B" })
  }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@available(*, deprecated) // Silence deprecation warnings for RealmOptional
extension RealmTests {
  #if swift(>=5.8)

    @MainActor
    func testOpenBehaviorForLocalRealm() async throws {
      let realm = try await WabiRealm(downloadBeforeOpen: .always)
      _ = try await WabiRealm(downloadBeforeOpen: .always)
      _ = try await Task { @CustomGlobalActor in
        _ = try await WabiRealm(actor: CustomGlobalActor.shared, downloadBeforeOpen: .always)
      }.value
      realm.invalidate()
    }

    // MARK: - Async Refresh

    func manuallyAdvancedRealm() throws -> (WabiRealm, String) {
      let config = RLMRealmConfiguration.default()
      config.disableAutomaticChangeNotifications = true
      config.cache = false
      return try (ObjectiveCSupport.convert(object: RLMRealm(configuration: config)), config.pathOnDisk)
    }

    @MainActor
    func testAsyncRefresh() async throws {
      let realm = try await WabiRealm(actor: MainActor.shared)
      realm.autorefresh = false

      let results = realm.objects(SwiftStringObject.self)
      XCTAssertEqual(results.count, 0)
      var didRefresh = await realm.asyncRefresh()
      XCTAssertFalse(didRefresh)

      try await Task { @CustomGlobalActor in
        let realm = try await WabiRealm(actor: CustomGlobalActor.shared)
        try! realm.write {
          _ = realm.create(SwiftStringObject.self, value: ["string"])
        }
      }.value

      XCTAssertEqual(results.count, 0)
      didRefresh = await realm.asyncRefresh()
      XCTAssertTrue(didRefresh)
      XCTAssertEqual(results.count, 1)
    }

    @MainActor
    func testAsyncRefreshWaitsForLatest() async throws {
      let (realm, path) = try manuallyAdvancedRealm()
      let results = realm.objects(SwiftStringObject.self)
      // Observe so that it has to wait and can't just advance immediately
      let token = results.observe { _ in }
      XCTAssertEqual(results.count, 0)

      let (realm2, _) = try manuallyAdvancedRealm()
      try! realm2.write {
        _ = realm2.create(SwiftStringObject.self, value: ["string"])
      }
      RLMRunAsyncNotifiers(path)
      // Notifiers are now up to date for the above write, but the WabiRealm hasn't
      // been refreshed

      try! realm2.write {
        _ = realm2.create(SwiftStringObject.self, value: ["string"])
      }
      // Notifiers are now newer than the WabiRealm, but still out of date

      Task { @MainActor in
        // This will run only when the parent task suspends as they're both
        // on the main actor
        RLMRunAsyncNotifiers(path)
      }

      XCTAssertEqual(results.count, 0)
      // Here notify() will advance to the version with one object, but we
      // need to wait for the version with two
      let didRefresh = await realm.asyncRefresh()
      XCTAssertTrue(didRefresh)
      XCTAssertEqual(results.count, 2)
      token.invalidate()
    }

    @MainActor
    func testAsyncRefreshWaitsForLatestAutorefreshOff() async throws {
      let (realm, path) = try manuallyAdvancedRealm()
      realm.autorefresh = false
      let results = realm.objects(SwiftStringObject.self)
      // Observe so that it has to wait and can't just advance immediately
      let token = results.observe { _ in }
      XCTAssertEqual(results.count, 0)

      let (realm2, _) = try manuallyAdvancedRealm()
      try! realm2.write {
        _ = realm2.create(SwiftStringObject.self, value: ["string"])
      }
      RLMRunAsyncNotifiers(path)
      // Notifiers are now up to date for the above write, but the WabiRealm hasn't
      // been refreshed

      try! realm2.write {
        _ = realm2.create(SwiftStringObject.self, value: ["string"])
      }
      // Notifiers are now newer than the WabiRealm, but still out of date

      Task { @MainActor in
        // This will run only when the parent task suspends as they're both
        // on the main actor
        RLMRunAsyncNotifiers(path)
      }

      XCTAssertEqual(results.count, 0)
      // Here notify() will advance to the version with one object, but we
      // need to wait for the version with two
      let didRefresh = await realm.asyncRefresh()
      XCTAssertTrue(didRefresh)
      XCTAssertEqual(results.count, 2)
      token.invalidate()
    }

    @MainActor
    func testAsyncRefreshWithMultipleWaiters() async throws {
      let (realm, path) = try manuallyAdvancedRealm()
      let results = realm.objects(SwiftStringObject.self)
      let token = results.observe { _ in }
      XCTAssertEqual(results.count, 0)

      // The order of execution here is weird. Each of the nested tasks can
      // run only when the outer task suspends, so this runs when we hit
      // the bottom asyncRefresh(), and then the task with RLMRunAsyncNotifiers
      // runs when we hit the inner asyncRefresh
      let task = Task { @MainActor in
        Task { @MainActor in
          RLMRunAsyncNotifiers(path)
        }
        XCTAssertEqual(results.count, 0)
        await realm.asyncRefresh()
        XCTAssertEqual(results.count, 1)
      }

      let (realm2, _) = try manuallyAdvancedRealm()
      try! realm2.write {
        _ = realm2.create(SwiftStringObject.self, value: ["string"])
      }

      XCTAssertEqual(results.count, 0)
      await realm.asyncRefresh()
      XCTAssertEqual(results.count, 1)
      // Verify that both continuations were resumed
      _ = await task.value
      token.invalidate()
    }

    @available(macOS 10.15.4, iOS 13.4, tvOS 13.4, watchOS 6.4, *)
    func testAsyncRefreshOnQueueConfinedRealm() async throws {
      @Locked var realm: WabiRealm!
      dispatchSyncNewThread {
        realm = try! WabiRealm(queue: self.queue)
      }
      try await assertPreconditionFailure("asyncRefresh() can only be called on main thread or actor-isolated Realms") {
        _ = await realm.asyncRefresh()
      }
      try await assertPreconditionFailure("asyncWrite() can only be called on main thread or actor-isolated Realms") {
        _ = try await realm.asyncWrite {}
      }
    }

    @MainActor
    func testAsyncRefreshTaskCancellation() async throws {
      let (realm, _) = try manuallyAdvancedRealm()
      let results = realm.objects(SwiftStringObject.self)
      let token = results.observe { _ in }

      let (realm2, _) = try manuallyAdvancedRealm()
      try! realm2.write {
        _ = realm2.create(SwiftStringObject.self, value: ["string"])
      }

      let task = Task { @MainActor in
        let didRefresh = await realm.asyncRefresh()
        XCTAssertFalse(didRefresh)
      }
      task.cancel()
      _ = await task.value
      token.invalidate()
    }

    // MARK: - Async Writes

    @MainActor
    func testAsyncWriteBasics() async throws {
      let realm = try await WabiRealm(actor: MainActor.shared)
      let obj = try await realm.asyncWrite {
        XCTAssertTrue(realm.isInWriteTransaction)
        XCTAssertTrue(realm.isPerformingAsynchronousWriteOperations)
        return realm.create(SwiftStringObject.self, value: ["foo"])
      }
      XCTAssertFalse(realm.isInWriteTransaction)
      XCTAssertFalse(realm.isPerformingAsynchronousWriteOperations)
      XCTAssertEqual(realm.objects(SwiftStringObject.self).count, 1)
      XCTAssertEqual(obj.stringCol, "foo")
    }

    @MainActor
    func testAsyncWriteCancel() async throws {
      let realm = try await WabiRealm(actor: MainActor.shared)
      try await realm.asyncWrite {
        realm.create(SwiftStringObject.self, value: ["foo"])
        realm.cancelWrite()
        XCTAssertFalse(realm.isInWriteTransaction)
      }
      XCTAssertEqual(realm.objects(SwiftStringObject.self).count, 0)
    }

    @MainActor
    func testAsyncWriteBeginNewWriteAfterCancel() async throws {
      let realm = try await WabiRealm(actor: MainActor.shared)
      try await realm.asyncWrite {
        realm.create(SwiftStringObject.self, value: ["foo"])
        realm.cancelWrite()
        realm.beginWrite()
        realm.create(SwiftStringObject.self, value: ["bar"])
      }
      let objects = realm.objects(SwiftStringObject.self)
      XCTAssertEqual(objects.count, 1)
      XCTAssertEqual(try XCTUnwrap(objects.first).stringCol, "bar")
    }

    @MainActor
    func testAsyncWriteModifyExistingObject() async throws {
      let realm = try await WabiRealm(actor: MainActor.shared)
      let obj = try await realm.asyncWrite {
        realm.create(SwiftStringObject.self, value: ["foo"])
      }
      try await realm.asyncWrite {
        obj.stringCol = "bar"
      }
      XCTAssertEqual(obj.stringCol, "bar")
    }

    @MainActor
    func testAsyncWriteCancelsOnThrow() async throws {
      let realm = try await WabiRealm(actor: MainActor.shared)

      try await assertThrowsErrorAsync(await realm.asyncWrite {
        realm.create(SwiftStringObject.self, value: ["foo"])
        throw WabiRealm.Error(.fail)
      }, WabiRealm.Error(.fail))

      try await assertThrowsErrorAsync(await realm.asyncWrite {
        realm.create(SwiftStringObject.self, value: ["foo"])
        realm.cancelWrite()
        throw WabiRealm.Error(.fail)
      }, WabiRealm.Error(.fail))

      XCTAssertEqual(realm.objects(SwiftStringObject.self).count, 0)
    }

    @CustomGlobalActor
    func testAsyncWriteCustomGlobalActor() async throws {
      let realm = try await WabiRealm(actor: CustomGlobalActor.shared)
      let obj = try await realm.asyncWrite {
        realm.create(SwiftStringObject.self, value: ["foo"])
      }
      XCTAssertEqual(realm.objects(SwiftStringObject.self).count, 1)
      XCTAssertEqual(obj.stringCol, "foo")
      try await realm.asyncWrite {
        obj.stringCol = "bar"
      }
      XCTAssertEqual(obj.stringCol, "bar")
    }

    func testAsyncWriteCustomActor() async throws {
      actor TestActor {
        var realm: WabiRealm!
        var obj: SwiftStringObject?
        init() async throws {
          realm = try await WabiRealm(actor: self)
        }

        var count: Int {
          realm.objects(SwiftStringObject.self).count
        }

        var value: String? {
          obj?.stringCol
        }

        func create() async throws {
          obj = try await realm.asyncWrite {
            realm.create(SwiftStringObject.self, value: ["foo"])
          }
        }

        func modify() async throws {
          try await realm.asyncWrite {
            obj?.stringCol = "bar"
          }
        }

        func close() {
          realm = nil
          obj = nil
        }
      }
      let actor = try await TestActor()
      var count = await actor.count
      XCTAssertEqual(count, 0)

      try await actor.create()
      count = await actor.count
      var value = await actor.value
      XCTAssertEqual(count, 1)
      XCTAssertEqual(value, "foo")

      try await actor.modify()
      count = await actor.count
      value = await actor.value
      XCTAssertEqual(count, 1)
      XCTAssertEqual(value, "bar")

      await actor.close()
    }

    @MainActor
    func testAsyncWriteTaskCancellation() async throws {
      let realm = try await WabiRealm(actor: MainActor.shared)
      realm.beginWrite()

      let ex = expectation(description: "Background thread ready")
      let task = Task { @CustomGlobalActor in
        let realm = try await WabiRealm(actor: CustomGlobalActor.shared)
        ex.fulfill()
        try await realm.asyncWrite {
          XCTFail("Should not have been called")
        }
      }
      await fulfillment(of: [ex], timeout: 2.0)
      Task { @CustomGlobalActor in
        // Cancel the task from within its actor so that we can be sure
        // that it has suspended with the task cancellation handler set
        task.cancel()
      }
      try await assertThrowsErrorAsync(await task.value, CancellationError())
      realm.cancelWrite()
    }

    @MainActor
    func testAsyncWriteTaskCancelledBeforeWriteCalled() async throws {
      let realm = try await WabiRealm(actor: MainActor.shared)
      realm.beginWrite()

      let ex = expectation(description: "Background thread ready")
      let task = Task { @CustomGlobalActor in
        let realm = try await WabiRealm(actor: CustomGlobalActor.shared)
        ex.fulfill()
        // Block until cancelWrite() is called, ensuring that the Task is
        // cancelled before the call to asyncWrite
        realm.beginWrite()
        realm.cancelWrite()
        try await realm.asyncWrite {
          XCTFail("Should not have been called")
        }
      }
      await fulfillment(of: [ex], timeout: 2.0)
      task.cancel()
      realm.cancelWrite()

      try await assertThrowsErrorAsync(await task.value, CancellationError())
    }

    // FIXME: deadlocks without https://github.com/realm/realm-core/pull/6413
    @MainActor
    func skip_testAsyncWriteTaskCancellationTiming() async throws {
      let realm = try await WabiRealm(actor: MainActor.shared)
      realm.beginWrite()

      // Try to hit the timing windows which can't be deterministically tested
      // by just repeating it a bunch of times. This should trigger tsan errors
      // if the locking is incorrect.
      for _ in 0 ..< 1000 {
        let ex = expectation(description: "Background thread ready")
        let task = Task { @CustomGlobalActor in
          let realm = try await WabiRealm(actor: CustomGlobalActor.shared)
          // Tearing down a WabiRealm which is in the middle of async writes
          // is itself async, so we need to explicitly wait for that to
          // happen or we'll hit a data race when we try to close all
          // remaining open Realms in tearDown
          defer { realm.invalidate() }
          ex.fulfill()
          try await realm.asyncWrite {
            XCTFail("Should not have been called")
          }
        }
        await fulfillment(of: [ex], timeout: 2.0)
        task.cancel()
        try await assertThrowsErrorAsync(await task.value, CancellationError())
      }
      realm.cancelWrite()
    }
  #endif // swift(>=5.8)
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@globalActor actor CustomGlobalActor: GlobalActor {
  static var shared = CustomGlobalActor()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension CancellationError: Equatable {
  public static func == (_: CancellationError, _: CancellationError) -> Bool {
    true
  }
}

// Helper
extension LogLevel {
  var logLevel: String {
    switch self {
    case .off:
      return "Off"
    case .fatal:
      return "Fatal"
    case .error:
      return "Error"
    case .warn:
      return "Warn"
    case .info:
      return "Info"
    case .detail:
      return "Details"
    case .debug:
      return "Debug"
    case .trace:
      return "Trace"
    case .all:
      return "All"
    default:
      return "unknown"
    }
  }
}

@available(macOS 12.0, watchOS 8.0, iOS 15.0, tvOS 15.0, macCatalyst 15.0, *)
class LoggerTests: TestCase {
  var logger: Logger!
  override func setUp() {
    logger = Logger.shared
  }

  override func tearDown() {
    Logger.shared = logger
  }

  func testSetDefaultLogLevel() throws {
    var logs = ""
    let logger = Logger(level: .off) { level, message in
      logs += "\(Date.now) \(level.logLevel) \(message)"
    }
    Logger.shared = logger

    try autoreleasepool { _ = try WabiRealm() }
    XCTAssertTrue(logs.isEmpty)

    logger.level = .all
    try autoreleasepool { _ = try WabiRealm() } // We should be getting logs after changing the log level
    XCTAssertEqual(Logger.shared.level, .all)
    XCTAssertTrue(logs.contains("Details DB:"))
    XCTAssertTrue(logs.contains("Trace DB:"))
  }

  func testDefaultLogger() throws {
    var logs = ""
    let logger = Logger(level: .off) { level, message in
      logs += "\(Date.now) \(level.logLevel) \(message)"
    }
    Logger.shared = logger

    XCTAssertEqual(Logger.shared.level, .off)
    try autoreleasepool { _ = try WabiRealm() }
    XCTAssertTrue(logs.isEmpty)

    // Info
    logger.level = .detail
    try autoreleasepool { _ = try WabiRealm() }

    XCTAssertTrue(!logs.isEmpty)
    XCTAssertTrue(logs.contains("Details DB:"))

    // Trace
    logs = ""
    logger.level = .trace
    try autoreleasepool { _ = try WabiRealm() }

    XCTAssertTrue(!logs.isEmpty)
    XCTAssertTrue(logs.contains("Trace DB:"))

    // Detail
    logs = ""
    logger.level = .detail
    try autoreleasepool { _ = try WabiRealm() }

    XCTAssertTrue(!logs.isEmpty)
    XCTAssertTrue(logs.contains("Details DB:"))
    XCTAssertFalse(logs.contains("Trace DB:"))

    logs = ""
    Logger.shared = Logger(level: .trace) { level, message in
      logs += "\(Date.now) \(level.logLevel) \(message)"
    }
    XCTAssertEqual(Logger.shared.level, .trace)
    try autoreleasepool { _ = try WabiRealm() }
    XCTAssertTrue(!logs.isEmpty)
    XCTAssertTrue(logs.contains("Details DB:"))
    XCTAssertTrue(logs.contains("Trace DB:"))
  }
}
