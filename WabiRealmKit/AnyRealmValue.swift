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

/// A enum for storing and retrieving values associated with an `AnyRealmValue` property.
public enum AnyRealmValue: Hashable {
  /// Represents `nil`
  case none
  /// An integer type.
  case int(Int)
  /// A boolean type.
  case bool(Bool)
  /// A floating point numeric type.
  case float(Float)
  /// A double numeric type.
  case double(Double)
  /// A string type.
  case string(String)
  /// A binary data type.
  case data(Data)
  /// A date type.
  case date(Date)
  /// A WabiRealm Object type.
  case object(Object)
  /// An ObjectId type.
  case objectId(ObjectId)
  /// A Decimal128 type.
  case decimal128(Decimal128)
  /// A UUID type.
  case uuid(UUID)

  /// Returns an `Int` if that is what the stored value is, otherwise `nil`.
  public var intValue: Int? {
    guard case let .int(i) = self else {
      return nil
    }
    return i
  }

  /// Returns a `Bool` if that is what the stored value is, otherwise `nil`.
  public var boolValue: Bool? {
    guard case let .bool(b) = self else {
      return nil
    }
    return b
  }

  /// Returns a `Float` if that is what the stored value is, otherwise `nil`.
  public var floatValue: Float? {
    guard case let .float(f) = self else {
      return nil
    }
    return f
  }

  /// Returns a `Double` if that is what the stored value is, otherwise `nil`.
  public var doubleValue: Double? {
    guard case let .double(d) = self else {
      return nil
    }
    return d
  }

  /// Returns a `String` if that is what the stored value is, otherwise `nil`.
  public var stringValue: String? {
    guard case let .string(s) = self else {
      return nil
    }
    return s
  }

  /// Returns `Data` if that is what the stored value is, otherwise `nil`.
  public var dataValue: Data? {
    guard case let .data(d) = self else {
      return nil
    }
    return d
  }

  /// Returns a `Date` if that is what the stored value is, otherwise `nil`.
  public var dateValue: Date? {
    guard case let .date(d) = self else {
      return nil
    }
    return d
  }

  /// Returns an `ObjectId` if that is what the stored value is, otherwise `nil`.
  public var objectIdValue: ObjectId? {
    guard case let .objectId(o) = self else {
      return nil
    }
    return o
  }

  /// Returns a `Decimal128` if that is what the stored value is, otherwise `nil`.
  public var decimal128Value: Decimal128? {
    guard case let .decimal128(d) = self else {
      return nil
    }
    return d
  }

  /// Returns a `UUID` if that is what the stored value is, otherwise `nil`.
  public var uuidValue: UUID? {
    guard case let .uuid(u) = self else {
      return nil
    }
    return u
  }

  /// Returns the stored value as a WabiRealm Object of a specific type.
  ///
  /// - Parameter objectType: The type of the Object to return.
  /// - Returns: A WabiRealm Object of the supplied type if that is what the underlying value is,
  /// otherwise `nil` is returned.
  public func object<T: Object>(_: T.Type) -> T? {
    guard case let .object(o) = self else {
      return nil
    }
    return o as? T
  }

  /// Returns a `DynamicObject` if the stored value is an `Object`, otherwise `nil`.
  ///
  /// Note: This allows access to an object stored in `AnyRealmValue` where you may not have
  /// the class information associated for it. For example if you are using WabiRealm Sync and version 2
  /// of your app sets an object into `AnyRealmValue` and that class does not exist in version 1
  /// use this accessor to gain access to the object in the WabiRealm.
  public var dynamicObject: DynamicObject? {
    guard case let .object(o) = self else {
      return nil
    }
    return unsafeBitCast(o, to: DynamicObject?.self)
  }

  /// Required for conformance to `AddableType`
  public init() {
    self = .none
  }
}
