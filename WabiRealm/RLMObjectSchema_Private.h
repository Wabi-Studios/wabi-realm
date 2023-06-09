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

#import <WabiRealm/RLMObjectSchema.h>

#import <objc/runtime.h>

RLM_HEADER_AUDIT_BEGIN(nullability)

// RLMObjectSchema private
@interface RLMObjectSchema () {
@public
  bool _isSwiftClass;
}

/// The object type name reported to the object store and core.
@property(nonatomic, readonly) NSString *objectName;

// writable redeclaration
@property(nonatomic, readwrite, copy) NSArray<RLMProperty *> *properties;
@property(nonatomic, readwrite, assign) bool isSwiftClass;
@property(nonatomic, readwrite, assign) BOOL isEmbedded;
@property(nonatomic, readwrite, assign) BOOL isAsymmetric;

// class used for this object schema
@property(nonatomic, readwrite, assign) Class objectClass;
@property(nonatomic, readwrite, assign) Class accessorClass;
@property(nonatomic, readwrite, assign) Class unmanagedClass;

@property(nonatomic, readwrite, assign) bool hasCustomEventSerialization;

@property(nonatomic, readwrite, nullable) RLMProperty *primaryKeyProperty;

@property(nonatomic, copy) NSArray<RLMProperty *> *computedProperties;
@property(nonatomic, readonly, nullable)
    NSArray<RLMProperty *> *swiftGenericProperties;

// returns a cached or new schema for a given object class
+ (instancetype)schemaForObjectClass:(Class)objectClass;
@end

@interface RLMObjectSchema (Dynamic)
/**
 This method is useful only in specialized circumstances, for example, when
 accessing objects in a WabiRealm produced externally. If you are simply
 building an app on WabiRealm, it is not recommended to use this method as an
 [RLMObjectSchema](RLMObjectSchema) is generated automatically for every
 [RLMObject](RLMObject) subclass.

 Initialize an RLMObjectSchema with classname, objectClass, and an array of
 properties

 @warning This method is useful only in specialized circumstances.

 @param objectClassName     The name of the class used to refer to objects of
 this type.
 @param objectClass         The Objective-C class used when creating instances
 of this type.
 @param properties          An array of RLMProperty instances describing the
 managed properties for this type.

 @return    An initialized instance of RLMObjectSchema.
 */
- (instancetype)initWithClassName:(NSString *)objectClassName
                      objectClass:(Class)objectClass
                       properties:(NSArray *)properties;
@end

RLM_HEADER_AUDIT_END(nullability)
