////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 WabiRealm Inc.
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

// MARK: Public API

/**
 A type which can be mapped to and from a type which WabiRealm supports.

 To store types in a WabiRealm which WabiRealm doesn't natively support, declare the
 type as conforming to either CustomPersistable or FailableCustomPersistable.
 This requires defining an associatedtype named `PersistedType` which indicates
 what WabiRealm type this type will be mapped to, an initializer taking the
 `PersistedType`, and a property which returns the appropriate `PersistedType`.
 For example, to make `URL` persistable:

 ```
 // Not all strings are valid URLs, so this uses
 // FailableCustomPersistable to handle the case when the data
 // in the WabiRealm isn't a valid URL.
 extension URL: FailableCustomPersistable {
     typealias PersistedType = String
     init?(persistedValue: String) {
         self.init(string: persistedValue)
     }
     var persistableValue: PersistedType {
         self.absoluteString
     }
 }
 ```

 After doing this, you can define properties using URL:
 ```
 class MyModel: Object {
     @Persisted var url: URL
     @Persisted var mapOfUrls: Map<String, URL>
 }
 ```

 `PersistedType` can be any of the primitive types supported by WabiRealm or an
 `EmbeddedObject` subclass. `EmbeddedObject` subclasses can be used if you
 need to store more than one piece of data for your mapped type. For
 example, to store `CGPoint`:

 ```
 // Define the storage object. A type used for custom mappings
 // does not have to be used exclusively for custom mappings,
 // and more than one type can map to a single embedded object
 // type.
 class CGPointObject: EmbeddedObject {
     @Persisted var double: x
     @Persisted var double: y
 }

 // Define the mapping. This mapping isn't failable, as the
 // data stored in the WabiRealm can always be interpreted as a
 // CGPoint.
 extension CGPoint: CustomPersistable {
     typealias PersistedType = CGPointObject
     init(persistedValue: CGPointObject) {
         self.init(x: persistedValue.x, y: persistedValue.y)
     }
     var persistableValue: PersistedType {
         CGPointObject(value: [x, y])
     }
 }

 class PointModel: Object {
     // Note that types which are mapped to embedded objects do
     // not have to be optional (but can be).
     @Persisted var point: CGPoint
     @Persisted var line: List<CGPoint>
 }
 ```

 Queries are performed on the persisted type and not the custom persistable
 type. Values passed into queries can be of either the persisted type or
 custom persistable type. For custom persistable types which map to embedded
 objects, memberwise equality will be used. For examples,
 `realm.objects(PointModel.self).where { $0.point == CGPoint(x: 1, y: 2) }`
 is equivalent to `"point.x == 1 AND point.y == 2"`.
  */
public protocol CustomPersistable: _CustomPersistable {
  /// Construct an instance of this type from the persisted type.
  init(persistedValue: PersistedType)
  /// Construct an instance of the persisted type from this type.
  var persistableValue: PersistedType { get }
}

/**
 A type which can be mapped to and from a type which WabiRealm supports.

 This protocol is identical to `CustomPersistable`, except with
 `init?(persistedValue:)` instead of `init(persistedValue:)`.

 FailableCustomPersistable types are force-unwrapped in
 non-Optional contexts, and collapsed to `nil` in Optional contexts.
 That is, if you have a value that can't be converted to a URL, reading a
 `@Persisted var url: URL` property will throw an unwrapped failed exception, and
 reading from `Persisted var url: URL?` will return `nil`.
 */
public protocol FailableCustomPersistable: _CustomPersistable {
  /// Construct an instance of the this type from the persisted type,
  /// returning nil if the conversion is not possible.
  ///
  /// This function must not return `nil` when given a default-initalized
  /// `PersistedType()`.
  init?(persistedValue: PersistedType)
  /// Construct an instance of the persisted type from this type.
  var persistableValue: PersistedType { get }
}

// MARK: - Implementation

/// :nodoc:
public protocol _CustomPersistable: _PersistableInsideOptional, _RealmCollectionValueInsideOptional {}

/// :nodoc:
public extension _CustomPersistable { // _RealmSchemaDiscoverable
  /// :nodoc:
  static var _rlmType: PropertyType { PersistedType._rlmType }
  /// :nodoc:
  static var _rlmOptional: Bool { PersistedType._rlmOptional }
  /// :nodoc:
  static var _rlmRequireObjc: Bool { false }
  /// :nodoc:
  func _rlmPopulateProperty(_: RLMProperty) {}
  /// :nodoc:
  static func _rlmPopulateProperty(_ prop: RLMProperty) {
    prop.customMappingIsOptional = prop.optional
    if prop.type == .object, !prop.collection || prop.dictionary {
      prop.optional = true
    }
    PersistedType._rlmPopulateProperty(prop)
  }
}

public extension CustomPersistable { // _Persistable
  /// :nodoc:
  static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Self {
    return Self(persistedValue: PersistedType._rlmGetProperty(obj, key))
  }

  /// :nodoc:
  static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Self? {
    return PersistedType._rlmGetPropertyOptional(obj, key).flatMap(Self.init)
  }

  /// :nodoc:
  static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Self) {
    PersistedType._rlmSetProperty(obj, key, value.persistableValue)
  }

  /// :nodoc:
  static func _rlmSetAccessor(_ prop: RLMProperty) {
    if prop.customMappingIsOptional {
      prop.swiftAccessor = BridgedPersistedPropertyAccessor<Self?>.self
    } else if prop.optional {
      prop.swiftAccessor = CustomPersistablePropertyAccessor<Self>.self
    } else {
      prop.swiftAccessor = BridgedPersistedPropertyAccessor<Self>.self
    }
  }

  /// :nodoc:
  static func _rlmDefaultValue() -> Self {
    Self(persistedValue: PersistedType._rlmDefaultValue())
  }

  /// :nodoc:
  func hash(into hasher: inout Hasher) {
    persistableValue.hash(into: &hasher)
  }
}

public extension FailableCustomPersistable { // _Persistable
  /// :nodoc:
  static func _rlmGetProperty(_ obj: ObjectBase, _ key: PropertyKey) -> Self {
    let persistedValue = PersistedType._rlmGetProperty(obj, key)
    if let value = Self(persistedValue: persistedValue) {
      return value
    }
    throwRealmException("Failed to convert persisted value '\(persistedValue)' to type '\(Self.self)' in a non-optional context.")
  }

  /// :nodoc:
  static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Self? {
    return PersistedType._rlmGetPropertyOptional(obj, key).flatMap(Self.init)
  }

  /// :nodoc:
  static func _rlmSetProperty(_ obj: ObjectBase, _ key: PropertyKey, _ value: Self) {
    PersistedType._rlmSetProperty(obj, key, value.persistableValue)
  }

  /// :nodoc:
  static func _rlmSetAccessor(_ prop: RLMProperty) {
    if prop.customMappingIsOptional {
      prop.swiftAccessor = BridgedPersistedPropertyAccessor<Self?>.self
    } else if prop.optional {
      prop.swiftAccessor = CustomPersistablePropertyAccessor<Self>.self
    } else {
      prop.swiftAccessor = BridgedPersistedPropertyAccessor<Self>.self
    }
  }

  /// :nodoc:
  static func _rlmDefaultValue() -> Self {
    if let value = Self(persistedValue: PersistedType._rlmDefaultValue()) {
      return value
    }
    throwRealmException("Failed to default construct a \(Self.self) using the default value for persisted type \(PersistedType.self). " +
      "This conversion must either succeed, the property must be optional, or you must explicitly specify a default value for the property.")
  }

  /// :nodoc:
  func hash(into hasher: inout Hasher) {
    persistableValue.hash(into: &hasher)
  }
}

public extension CustomPersistable { // _ObjcBridgeable
  /// :nodoc:
  static func _rlmFromObjc(_ value: Any, insideOptional: Bool) -> Self? {
    if let value = PersistedType._rlmFromObjc(value) {
      return Self(persistedValue: value)
    }
    if let value = value as? Self {
      return value
    }
    if !insideOptional, value is NSNull {
      return Self._rlmDefaultValue()
    }
    return nil
  }

  /// :nodoc:
  var _rlmObjcValue: Any { persistableValue }
}

public extension FailableCustomPersistable { // _ObjcBridgeable
  /// :nodoc:
  static func _rlmFromObjc(_ value: Any, insideOptional _: Bool) -> Self? {
    if let value = PersistedType._rlmFromObjc(value) {
      return Self(persistedValue: value)
    }
    if let value = value as? Self {
      return value
    }
    return nil
  }

  /// :nodoc:
  var _rlmObjcValue: Any { persistableValue }
}
