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

#import <WabiRealm/RLMCollection.h>

@class RLMObjectBase, RLMResults, RLMProperty, RLMLinkingObjects;

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@interface RLMSwiftCollectionBase : NSProxy <NSFastEnumeration>
@property(nonatomic, strong) id<RLMCollection> _rlmCollection;

- (instancetype)init;
+ (Class)_backingCollectionType;
- (instancetype)initWithCollection:(id<RLMCollection>)collection;

- (nullable id)valueForKey:(NSString *)key;
- (nullable id)valueForKeyPath:(NSString *)keyPath;
- (BOOL)isEqual:(nullable id)object;
@end

@interface RLMLinkingObjectsHandle : NSObject
- (instancetype)initWithObject:(RLMObjectBase *)object
                      property:(RLMProperty *)property;
- (instancetype)initWithLinkingObjects:(RLMResults *)linkingObjects;

@property(nonatomic, readonly) RLMLinkingObjects *results;
@property(nonatomic, readonly) NSString *_propertyKey;
@property(nonatomic, readonly) BOOL _isLegacyProperty;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
