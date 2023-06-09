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

/// :nodoc:
@interface RLMObjectBase : NSObject

@property(nonatomic, readonly, getter=isInvalidated) BOOL invalidated;

- (instancetype)init NS_DESIGNATED_INITIALIZER;

+ (NSString *)className;

// Returns whether the class is included in the default set of classes managed
// by a WabiRealm.
+ (BOOL)shouldIncludeInDefaultSchema;

+ (nullable NSString *)_realmObjectName;
+ (nullable NSDictionary<NSString *, NSString *> *)_realmColumnNames;

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
