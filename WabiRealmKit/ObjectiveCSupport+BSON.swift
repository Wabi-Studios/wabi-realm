////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 WabiRealm Inc.
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

/**
 :nodoc:
 **/
public extension ObjectiveCSupport {
  // FIXME: remove these and rename convertBson to convert on the next major
  // version bump
  static func convert(object: AnyBSON?) -> RLMBSON? {
    if let converted = object.map(convertBson), !(converted is NSNull) {
      return converted
    }
    return nil
  }

  static func convert(object: RLMBSON?) -> AnyBSON? {
    if let object = object {
      let converted = convertBson(object: object)
      if converted == .null {
        return nil
      }
      return converted
    }
    return nil
  }

  static func convert(_ object: Document) -> [String: RLMBSON] {
    object.reduce(into: [String: RLMBSON]()) { (result: inout [String: RLMBSON], kvp) in
      result[kvp.key] = kvp.value.map(convertBson) ?? NSNull()
    }
  }

  /// Convert an `AnyBSON` to a `RLMBSON`.
  static func convertBson(object: AnyBSON) -> RLMBSON {
    switch object {
    case let .int32(val):
      return val as NSNumber
    case let .int64(val):
      return val as NSNumber
    case let .double(val):
      return val as NSNumber
    case let .string(val):
      return val as NSString
    case let .binary(val):
      return val as NSData
    case let .datetime(val):
      return val as NSDate
    case let .timestamp(val):
      return val as NSDate
    case let .decimal128(val):
      return val as RLMDecimal128
    case let .objectId(val):
      return val as RLMObjectId
    case let .document(val):
      return convert(val) as NSDictionary
    case let .array(val):
      return val.map { $0.map(convertBson) } as NSArray
    case .maxKey:
      return MaxKey()
    case .minKey:
      return MinKey()
    case let .regex(val):
      return val
    case let .bool(val):
      return val as NSNumber
    case let .uuid(val):
      return val as NSUUID
    case .null:
      return NSNull()
    }
  }

  static func convert(_ object: [String: RLMBSON]) -> Document {
    object.mapValues { convert(object: $0) }
  }

  /// Convert a `RLMBSON` to an `AnyBSON`.
  static func convertBson(object bson: RLMBSON) -> AnyBSON? {
    switch bson.__bsonType {
    case .null:
      return .null
    case .int32:
      guard let val = bson as? NSNumber else {
        return nil
      }
      return .int32(Int32(val.intValue))
    case .int64:
      guard let val = bson as? NSNumber else {
        return nil
      }
      return .int64(Int64(val.int64Value))
    case .bool:
      guard let val = bson as? NSNumber else {
        return nil
      }
      return .bool(val.boolValue)
    case .double:
      guard let val = bson as? NSNumber else {
        return nil
      }
      return .double(val.doubleValue)
    case .string:
      guard let val = bson as? NSString else {
        return nil
      }
      return .string(val as String)
    case .binary:
      guard let val = bson as? NSData else {
        return nil
      }
      return .binary(val as Data)
    case .timestamp:
      guard let val = bson as? NSDate else {
        return nil
      }
      return .timestamp(val as Date)
    case .datetime:
      guard let val = bson as? NSDate else {
        return nil
      }
      return .datetime(val as Date)
    case .objectId:
      guard let val = bson as? RLMObjectId,
            let oid = try? ObjectId(string: val.stringValue)
      else {
        return nil
      }
      return .objectId(oid)
    case .decimal128:
      guard let val = bson as? RLMDecimal128 else {
        return nil
      }
      return .decimal128(Decimal128(stringLiteral: val.stringValue))
    case .regularExpression:
      guard let val = bson as? NSRegularExpression else {
        return nil
      }
      return .regex(val)
    case .maxKey:
      return .maxKey
    case .minKey:
      return .minKey
    case .document:
      guard let val = bson as? [String: RLMBSON] else {
        return nil
      }
      return .document(convert(val))
    case .array:
      guard let val = bson as? [RLMBSON?] else {
        return nil
      }
      return .array(val.compactMap {
        if let value = $0 {
          return convertBson(object: value)
        }
        return .null
      }.map { (v: AnyBSON) -> AnyBSON? in v == .null ? nil : v })
    case .UUID:
      guard let val = bson as? NSUUID else {
        return nil
      }
      return .uuid(val as UUID)
    default:
      return nil
    }
  }
}
