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

#import <WabiRealm/RLMConstants.h>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@class RLMSchema;
@class RLMArray;
@class RLMObject;

/**
 A block type which provides both the old and new versions of an object in the
 WabiRealm. Object properties can only be accessed using keyed subscripting.

 @see `-[RLMMigration enumerateObjects:block:]`

 @param oldObject The object from the original WabiRealm (read-only).
 @param newObject The object from the migrated WabiRealm (read-write).
*/
typedef void (^RLMObjectMigrationBlock)(RLMObject *__nullable oldObject,
                                        RLMObject *__nullable newObject);

/**
 `RLMMigration` instances encapsulate information intended to facilitate a
 schema migration.

 A `RLMMigration` instance is passed into a user-defined `RLMMigrationBlock`
 block when updating the version of a WabiRealm. This instance provides access
 to the old and new database schemas, the objects in the WabiRealm, and provides
 functionality for modifying the WabiRealm during the migration.
 */
@interface RLMMigration : NSObject

#pragma mark - Properties

/**
 Returns the old `RLMSchema`. This is the schema which describes the WabiRealm
 before the migration is applied.
 */
@property(nonatomic, readonly) RLMSchema *oldSchema NS_REFINED_FOR_SWIFT;

/**
 Returns the new `RLMSchema`. This is the schema which describes the WabiRealm
 after the migration is applied.
 */
@property(nonatomic, readonly) RLMSchema *newSchema NS_REFINED_FOR_SWIFT;

#pragma mark - Altering Objects during a Migration

/**
 Enumerates all the objects of a given type in the WabiRealm, providing both the
 old and new versions of each object. Within the block, object properties can
 only be accessed using keyed subscripting.

 @param className   The name of the `RLMObject` class to enumerate.

 @warning   All objects returned are of a type specific to the current migration
 and should not be cast to `className`. Instead, treat them as `RLMObject`s and
 use keyed subscripting to access properties.
 */
- (void)enumerateObjects:(NSString *)className
                   block:(__attribute__((noescape))RLMObjectMigrationBlock)block
    NS_REFINED_FOR_SWIFT;

/**
 Creates and returns an `RLMObject` instance of type `className` in the
 WabiRealm being migrated.

 The `value` argument is used to populate the object. It can be a key-value
 coding compliant object, an array or dictionary returned from the methods in
 `NSJSONSerialization`, or an array containing one element for each managed
 property. An exception will be thrown if any required properties are not
 present and those properties were not defined with default values.

 When passing in an `NSArray` as the `value` argument, all properties must be
 present, valid and in the same order as the properties defined in the model.

 @param className   The name of the `RLMObject` class to create.
 @param value       The value used to populate the object.
 */
- (RLMObject *)createObject:(NSString *)className
                  withValue:(id)value NS_REFINED_FOR_SWIFT;

/**
 Deletes an object from a WabiRealm during a migration.

 It is permitted to call this method from within the block passed to
 `-[enumerateObjects:block:]`.

 @param object  Object to be deleted from the WabiRealm being migrated.
 */
- (void)deleteObject:(RLMObject *)object NS_REFINED_FOR_SWIFT;

/**
 Deletes the data for the class with the given name.

 All objects of the given class will be deleted. If the `RLMObject` subclass no
 longer exists in your program, any remaining metadata for the class will be
 removed from the WabiRealm file.

 @param  name The name of the `RLMObject` class to delete.

 @return A Boolean value indicating whether there was any data to delete.
 */
- (BOOL)deleteDataForClassName:(NSString *)name NS_REFINED_FOR_SWIFT;

/**
 Renames a property of the given class from `oldName` to `newName`.

 @param className The name of the class whose property should be renamed. This
 class must be present in both the old and new WabiRealm schemas.
 @param oldName   The old persisted property name for the property to be
 renamed. There must not be a property with this name in the class as defined by
 the new WabiRealm schema.
 @param newName   The new persisted property name for the property to be
 renamed. There must not be a property with this name in the class as defined by
 the old WabiRealm schema.
 */
- (void)renamePropertyForClass:(NSString *)className
                       oldName:(NSString *)oldName
                       newName:(NSString *)newName NS_REFINED_FOR_SWIFT;

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
