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

import WabiRealm
import XCTest

#if canImport(WabiRealmTestSupport)
  import WabiRealmTestSupport
#endif

extension RLMObject {
  @discardableResult
  class func create(in realm: RLMRealm, withValue value: [Any]) -> Self {
    create(in: realm, withValue: value as Any)
  }

  @discardableResult
  class func createInDefaultRealm(withValue value: [Any]) -> Self {
    createInDefaultRealm(withValue: value as Any)
  }

  @discardableResult
  class func createOrUpdate(in realm: RLMRealm, withValue value: [Any]) -> Self {
    create(in: realm, withValue: value as Any)
  }

  @discardableResult
  class func createOrUpdateInDefaultRealm(withValue value: [Any]) -> Self {
    createOrUpdateInDefaultRealm(withValue: value as Any)
  }
}

class SwiftRLMArrayPropertyTests: RLMTestCase {
  // Swift models

  func testBasicArray() {
    let string = SwiftRLMStringObject()
    string.stringCol = "string"

    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    realm.add(string)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(SwiftRLMStringObject.allObjects(in: realm).count, UInt(1), "There should be a single SwiftRLMStringObject in the realm")

    let array = SwiftRLMArrayPropertyObject()
    array.name = "arrayObject"
    array.array.add(string)
    XCTAssertEqual(array.array.count, UInt(1))
    XCTAssertEqual(array.array.firstObject()!.stringCol, "string")

    realm.beginWriteTransaction()
    realm.add(array)
    array.array.add(string)
    try! realm.commitWriteTransaction()

    let arrayObjects = SwiftRLMArrayPropertyObject.allObjects(in: realm) as! RLMResults<SwiftRLMArrayPropertyObject>

    XCTAssertEqual(arrayObjects.count, UInt(1), "There should be a single SwiftRLMStringObject in the realm")
    let cmp = arrayObjects.firstObject()!.array.firstObject()!
    XCTAssertTrue(string.isEqual(to: cmp), "First array object should be the string object we added")
  }

  func testPopulateEmptyArray() {
    let realm = realmWithTestPath()

    realm.beginWriteTransaction()
    let array = SwiftRLMArrayPropertyObject.create(in: realm, withValue: ["arrayObject"])
    XCTAssertNotNil(array.array, "Should be able to get an empty array")
    XCTAssertEqual(array.array.count, UInt(0), "Should start with no array elements")

    let obj = SwiftRLMStringObject()
    obj.stringCol = "a"
    array.array.add(obj)
    array.array.add(SwiftRLMStringObject.create(in: realm, withValue: ["b"]))
    array.array.add(obj)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(array.array.count, UInt(3), "Should have three elements in array")
    XCTAssertEqual(array.array[0].stringCol, "a", "First element should have property value 'a'")
    XCTAssertEqual(array.array[1].stringCol, "b", "Second element should have property value 'b'")
    XCTAssertEqual(array.array[2].stringCol, "a", "Third element should have property value 'a'")

    for obj in array.array {
      XCTAssertFalse(obj.description.isEmpty, "Object should have description")
    }
  }

  func testModifyDetatchedArray() {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    let arObj = SwiftRLMArrayPropertyObject.create(in: realm, withValue: ["arrayObject"])
    XCTAssertNotNil(arObj.array, "Should be able to get an empty array")
    XCTAssertEqual(arObj.array.count, UInt(0), "Should start with no array elements")

    let obj = SwiftRLMStringObject()
    obj.stringCol = "a"
    let array = arObj.array
    array.add(obj)
    array.add(SwiftRLMStringObject.create(in: realm, withValue: ["b"]))
    try! realm.commitWriteTransaction()

    XCTAssertEqual(array.count, UInt(2), "Should have two elements in array")
    XCTAssertEqual(array[0].stringCol, "a", "First element should have property value 'a'")
    XCTAssertEqual(array[1].stringCol, "b", "Second element should have property value 'b'")
  }

  func testInsertMultiple() {
    let realm = realmWithTestPath()

    realm.beginWriteTransaction()

    let obj = SwiftRLMArrayPropertyObject.create(in: realm, withValue: ["arrayObject"])
    let child1 = SwiftRLMStringObject.create(in: realm, withValue: ["a"])
    let child2 = SwiftRLMStringObject()
    child2.stringCol = "b"
    obj.array.addObjects([child2, child1] as NSArray)
    try! realm.commitWriteTransaction()

    let children = SwiftRLMStringObject.allObjects(in: realm)
    XCTAssertEqual((children[0] as! SwiftRLMStringObject).stringCol, "a", "First child should be 'a'")
    XCTAssertEqual((children[1] as! SwiftRLMStringObject).stringCol, "b", "Second child should be 'b'")
  }

  // FIXME: Support unmanaged RLMArray's in Swift-defined models
  //    func testUnmanaged() {
  //        let realm = realmWithTestPath()
  //
  //        let array = SwiftRLMArrayPropertyObject()
  //        array.name = "name"
  //        XCTAssertNotNil(array.array, "RLMArray property should get created on access")
  //
  //        let obj = SwiftRLMStringObject()
  //        obj.stringCol = "a"
  //        array.array.addObject(obj)
  //        array.array.addObject(obj)
  //
  //        realm.beginWriteTransaction()
  //        realm.addObject(array)
  //        try! realm.commitWriteTransaction()
  //
  //        XCTAssertEqual(array.array.count, UInt(2), "Should have two elements in array")
  //        XCTAssertEqual((array.array[0] as SwiftRLMStringObject).stringCol, "a", "First element should have property value 'a'")
  //        XCTAssertEqual((array.array[1] as SwiftRLMStringObject).stringCol, "a", "Second element should have property value 'a'")
  //    }

  // Objective-C models

  func testBasicArray_objc() {
    let string = StringObject()
    string.stringCol = "string"

    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    realm.add(string)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(StringObject.allObjects(in: realm).count, UInt(1), "There should be a single StringObject in the realm")

    let array = ArrayPropertyObject()
    array.name = "arrayObject"
    array.array.add(string)

    realm.beginWriteTransaction()
    realm.add(array)
    try! realm.commitWriteTransaction()

    let arrayObjects = ArrayPropertyObject.allObjects(in: realm)

    XCTAssertEqual(arrayObjects.count, UInt(1), "There should be a single StringObject in the realm")
    let cmp = (arrayObjects.firstObject() as! ArrayPropertyObject).array.firstObject()!
    XCTAssertTrue(string.isEqual(to: cmp), "First array object should be the string object we added")
  }

  func testPopulateEmptyArray_objc() {
    let realm = realmWithTestPath()

    realm.beginWriteTransaction()
    let array = ArrayPropertyObject.create(in: realm, withValue: ["arrayObject"])
    XCTAssertNotNil(array.array, "Should be able to get an empty array")
    XCTAssertEqual(array.array.count, UInt(0), "Should start with no array elements")

    let obj = StringObject()
    obj.stringCol = "a"
    array.array.add(obj)
    array.array.add(StringObject.create(in: realm, withValue: ["b"]))
    array.array.add(obj)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(array.array.count, UInt(3), "Should have three elements in array")
    XCTAssertEqual((array.array[0]).stringCol!, "a", "First element should have property value 'a'")
    XCTAssertEqual((array.array[1]).stringCol!, "b", "Second element should have property value 'b'")
    XCTAssertEqual((array.array[2]).stringCol!, "a", "Third element should have property value 'a'")

    for idx in 0 ..< array.array.count {
      XCTAssertFalse(array.array[idx].description.isEmpty, "Object should have description")
    }
  }

  func testModifyDetatchedArray_objc() {
    let realm = realmWithTestPath()
    realm.beginWriteTransaction()
    let arObj = ArrayPropertyObject.create(in: realm, withValue: ["arrayObject"])
    XCTAssertNotNil(arObj.array, "Should be able to get an empty array")
    XCTAssertEqual(arObj.array.count, UInt(0), "Should start with no array elements")

    let obj = StringObject()
    obj.stringCol = "a"
    let array = arObj.array!
    array.add(obj)
    array.add(StringObject.create(in: realm, withValue: ["b"]))
    try! realm.commitWriteTransaction()

    XCTAssertEqual(array.count, UInt(2), "Should have two elements in array")
    XCTAssertEqual(array[0].stringCol!, "a", "First element should have property value 'a'")
    XCTAssertEqual(array[1].stringCol!, "b", "Second element should have property value 'b'")
  }

  func testInsertMultiple_objc() {
    let realm = realmWithTestPath()

    realm.beginWriteTransaction()

    let obj = ArrayPropertyObject.create(in: realm, withValue: ["arrayObject"])
    let child1 = StringObject.create(in: realm, withValue: ["a"])
    let child2 = StringObject()
    child2.stringCol = "b"
    obj.array.addObjects([child2, child1] as NSArray)
    try! realm.commitWriteTransaction()

    let children = StringObject.allObjects(in: realm)
    XCTAssertEqual((children[0] as! StringObject).stringCol!, "a", "First child should be 'a'")
    XCTAssertEqual((children[1] as! StringObject).stringCol!, "b", "Second child should be 'b'")
  }

  func testUnmanaged_objc() {
    let realm = realmWithTestPath()

    let array = ArrayPropertyObject()
    array.name = "name"
    XCTAssertNotNil(array.array, "RLMArray property should get created on access")

    let obj = StringObject()
    obj.stringCol = "a"
    array.array.add(obj)
    array.array.add(obj)

    realm.beginWriteTransaction()
    realm.add(array)
    try! realm.commitWriteTransaction()

    XCTAssertEqual(array.array.count, UInt(2), "Should have two elements in array")
    XCTAssertEqual(array.array[0].stringCol!, "a", "First element should have property value 'a'")
    XCTAssertEqual(array.array[1].stringCol!, "a", "Second element should have property value 'a'")
  }
}
