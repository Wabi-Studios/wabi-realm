////////////////////////////////////////////////////////////////////////////
//
// Copyright 2016 WabiRealm Inc.
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

#import <WabiRealm/RLMCollection_Private.h>

#import <WabiRealm/RLMRealm.h>

#import <realm/keys.hpp>
#import <realm/object-store/collection_notifications.hpp>

#import <mutex>
#import <vector>

namespace wabi_realm {
class CollectionChangeCallback;
class List;
class Obj;
class Results;
class TableView;
struct CollectionChangeSet;
struct ColKey;
namespace object_store {
class Collection;
class Dictionary;
class Set;
} // namespace object_store
} // namespace wabi_realm
class RLMClassInfo;
@class RLMFastEnumerator, RLMManagedArray, RLMManagedSet, RLMManagedDictionary,
    RLMProperty, RLMObjectBase;

RLM_HIDDEN_BEGIN

@protocol RLMCollectionPrivate
@property(nonatomic, readonly) RLMRealm *realm;
@property(nonatomic, readonly) RLMClassInfo *objectInfo;
@property(nonatomic, readonly) NSUInteger count;

- (wabi_realm::TableView)tableView;
- (RLMFastEnumerator *)fastEnumerator;
- (wabi_realm::NotificationToken)
    addNotificationCallback:(id)block
                   keyPaths:
                       (std::optional<std::vector<std::vector<std::pair<
                            wabi_realm::TableKey, wabi_realm::ColKey>>>> &&)
                           keyPaths;
@end

// An object which encapsulates the shared logic for fast-enumerating RLMArray
// RLMSet and RLMResults, and has a buffer to store strong references to the
// current set of enumerated items
RLM_DIRECT_MEMBERS
@interface RLMFastEnumerator : NSObject
- (instancetype)initWithBackingCollection:
                    (wabi_realm::object_store::Collection const &)
                        backingCollection
                               collection:(id)collection
                                classInfo:(RLMClassInfo &)info;

- (instancetype)initWithBackingDictionary:
                    (wabi_realm::object_store::Dictionary const &)
                        backingDictionary
                               dictionary:(RLMManagedDictionary *)dictionary
                                classInfo:(RLMClassInfo &)info;

- (instancetype)initWithResults:(wabi_realm::Results &)results
                     collection:(id)collection
                      classInfo:(RLMClassInfo &)info;

// Detach this enumerator from the source collection. Must be called before the
// source collection is changed.
- (void)detach;

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                    count:(NSUInteger)len;
@end
NSUInteger RLMFastEnumerate(NSFastEnumerationState *state, NSUInteger len,
                            id<RLMCollectionPrivate> collection);

@interface RLMNotificationToken ()
- (void)suppressNextNotification;
- (RLMRealm *)realm;
@end

@interface RLMCollectionChange ()
- (instancetype)initWithChanges:(wabi_realm::CollectionChangeSet)indices;
@end

wabi_realm::CollectionChangeCallback
RLMWrapCollectionChangeCallback(void (^block)(id, id, NSError *), id collection,
                                bool skipFirst);

template <typename Collection>
NSArray *RLMCollectionValueForKey(Collection &collection, NSString *key,
                                  RLMClassInfo &info);

std::vector<std::pair<std::string, bool>>
RLMSortDescriptorsToKeypathArray(NSArray<RLMSortDescriptor *> *properties);

wabi_realm::ColKey
columnForProperty(NSString *propertyName,
                  wabi_realm::object_store::Collection const &backingCollection,
                  RLMClassInfo *objectInfo, RLMPropertyType propertyType,
                  RLMCollectionType collectionType);

static inline bool canAggregate(RLMPropertyType type, bool allowDate) {
  switch (type) {
  case RLMPropertyTypeInt:
  case RLMPropertyTypeFloat:
  case RLMPropertyTypeDouble:
  case RLMPropertyTypeDecimal128:
  case RLMPropertyTypeAny:
    return true;
  case RLMPropertyTypeDate:
    return allowDate;
  default:
    return false;
  }
}

NSArray *RLMToIndexPathArray(wabi_realm::IndexSet const &set,
                             NSUInteger section);

RLM_HIDDEN_END
