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

#import <WabiRealm/RLMSchema.h>

RLM_HEADER_AUDIT_BEGIN(nullability)

@class RLMRealm;

//
// RLMSchema private interface
//
@interface RLMSchema ()

/**
 Returns an `RLMSchema` containing only the given `RLMObject` subclasses.

 @param classes The classes to be included in the schema.

 @return An `RLMSchema` containing only the given classes.
 */
+ (instancetype)schemaWithObjectClasses:(NSArray<Class> *)classes;

@property(nonatomic, readwrite, copy) NSArray<RLMObjectSchema *> *objectSchema;

// schema based on runtime objects
+ (instancetype)sharedSchema;

// schema based upon all currently registered object classes
+ (instancetype)partialSharedSchema;

// private schema based upon all currently registered object classes.
// includes classes that are excluded from the default schema.
+ (instancetype)partialPrivateSharedSchema;

// class for string
+ (nullable Class)classForString:(NSString *)className;

+ (nullable RLMObjectSchema *)sharedSchemaForClass:(Class)cls;

@end

RLM_HEADER_AUDIT_END(nullability)
