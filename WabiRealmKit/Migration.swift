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
import WabiRealm.Private

/**
 The type of a migration block used to migrate a WabiRealm.

 - parameter migration:  A `Migration` object used to perform the migration. The migration object allows you to
                         enumerate and alter any existing objects which require migration.

 - parameter oldSchemaVersion: The schema version of the WabiRealm being migrated.
 */
public typealias MigrationBlock = @Sendable (_ migration: Migration, _ oldSchemaVersion: UInt64) -> Void

/// An object class used during migrations.
public typealias MigrationObject = DynamicObject

/**
 A block type which provides both the old and new versions of an object in the WabiRealm. Object
 properties can only be accessed using subscripting.

 - parameter oldObject: The object from the original WabiRealm (read-only).
 - parameter newObject: The object from the migrated WabiRealm (read-write).
 */
public typealias MigrationObjectEnumerateBlock = (_ oldObject: MigrationObject?, _ newObject: MigrationObject?) -> Void

/**
 Returns the schema version for a WabiRealm at a given local URL.

 - parameter fileURL:       Local URL to a WabiRealm file.
 - parameter encryptionKey: 64-byte key used to encrypt the file, or `nil` if it is unencrypted.

 - throws: An `NSError` that describes the problem.
 */
public func schemaVersionAtURL(_ fileURL: URL, encryptionKey: Data? = nil) throws -> UInt64 {
  var error: NSError?
  let version = RLMRealm.__schemaVersion(at: fileURL, encryptionKey: encryptionKey, error: &error)
  guard version != RLMNotVersioned else {
    throw error!
  }
  return version
}

public extension WabiRealm {
  /**
   Performs the given WabiRealm configuration's migration block on a WabiRealm at the given path.

   This method is called automatically when opening a WabiRealm for the first time and does not need to be called
   explicitly. You can choose to call this method to control exactly when and how migrations are performed.

   - parameter configuration: The WabiRealm configuration used to open and migrate the WabiRealm.
   */
  static func performMigration(for configuration: WabiRealm.Configuration = WabiRealm.Configuration.defaultConfiguration) throws {
    try RLMRealm.performMigration(for: configuration.rlmConfiguration)
  }
}

/**
 `Migration` instances encapsulate information intended to facilitate a schema migration.

 A `Migration` instance is passed into a user-defined `MigrationBlock` block when updating the version of a WabiRealm. This
 instance provides access to the old and new database schemas, the objects in the WabiRealm, and provides functionality for
 modifying the WabiRealm during the migration.
 */
public typealias Migration = RLMMigration
public extension Migration {
  // MARK: Properties

  /// The old schema, describing the WabiRealm before applying a migration.
  var oldSchema: Schema { return Schema(__oldSchema) }

  /// The new schema, describing the WabiRealm after applying a migration.
  var newSchema: Schema { return Schema(__newSchema) }

  // MARK: Altering Objects During a Migration

  /**
   Enumerates all the objects of a given type in this WabiRealm, providing both the old and new versions of each object.
   Properties on an object can be accessed using subscripting.

   - parameter objectClassName: The name of the `Object` class to enumerate.
   - parameter block:           The block providing both the old and new versions of an object in this WabiRealm.
   */
  func enumerateObjects(ofType typeName: String, _ block: MigrationObjectEnumerateBlock) {
    __enumerateObjects(typeName) { oldObject, newObject in
      block(unsafeBitCast(oldObject, to: MigrationObject.self),
            unsafeBitCast(newObject, to: MigrationObject.self))
    }
  }

  /**
   Creates and returns an `Object` of type `className` in the WabiRealm being migrated.

   The `value` argument is used to populate the object. It can be a key-value coding compliant object, an array or
   dictionary returned from the methods in `NSJSONSerialization`, or an `Array` containing one element for each
   managed property. An exception will be thrown if any required properties are not present and those properties were
   not defined with default values.

   When passing in an `Array` as the `value` argument, all properties must be present, valid and in the same order as
   the properties defined in the model.

   - parameter className: The name of the `Object` class to create.
   - parameter value:     The value used to populate the created object.

   - returns: The newly created object.
   */
  @discardableResult
  func create(_ typeName: String, value: Any = [Any]()) -> MigrationObject {
    return unsafeBitCast(__createObject(typeName, withValue: value), to: MigrationObject.self)
  }

  /**
   Deletes an object from a WabiRealm during a migration.

   It is permitted to call this method from within the block passed to `enumerate(_:block:)`.

   - parameter object: An object to be deleted from the WabiRealm being migrated.
   */
  func delete(_ object: MigrationObject) {
    __delete(object.unsafeCastToRLMObject())
  }

  /**
   Deletes the data for the class with the given name.

   All objects of the given class will be deleted. If the `Object` subclass no longer exists in your program, any
   remaining metadata for the class will be removed from the WabiRealm file.

   - parameter objectClassName: The name of the `Object` class to delete.

   - returns: A Boolean value indicating whether there was any data to delete.
   */
  @discardableResult
  func deleteData(forType typeName: String) -> Bool {
    return __deleteData(forClassName: typeName)
  }

  /**
   Renames a property of the given class from `oldName` to `newName`.

   - parameter className:  The name of the class whose property should be renamed. This class must be present
                           in both the old and new WabiRealm schemas.
   - parameter oldName:    The old column name for the property to be renamed. There must not be a property with this name in
                           the class as defined by the new WabiRealm schema.
   - parameter newName:    The new column name for the property to be renamed. There must not be a property with this name in
                           the class as defined by the old WabiRealm schema.
   */
  func renameProperty(onType typeName: String, from oldName: String, to newName: String) {
    __renameProperty(forClass: typeName, oldName: oldName, newName: newName)
  }
}
