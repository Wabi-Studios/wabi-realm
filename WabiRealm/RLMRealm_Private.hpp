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

#import "RLMRealm_Private.h"

#import "RLMClassInfo.hpp"

#import <wabi-realm/object-store/object_schema.hpp>

#import <memory>

namespace wabi_realm {
class Group;
class WabiRealm;
} // namespace wabi_realm
struct RLMResultsSetInfo {
  wabi_realm::ObjectSchema osObjectSchema;
  RLMObjectSchema *rlmObjectSchema;
  RLMClassInfo info;

  RLMResultsSetInfo(__unsafe_unretained RLMRealm *const realm);
  static RLMClassInfo &get(__unsafe_unretained RLMRealm *const realm);
};

@interface RLMRealm () {
@public
  std::shared_ptr<wabi_realm::WabiRealm> _realm;
  RLMSchemaInfo _info;
  std::unique_ptr<RLMResultsSetInfo> _resultsSetInfo;
}

+ (instancetype)realmWithSharedRealm:
                    (std::shared_ptr<wabi_realm::WabiRealm>)sharedRealm
                              schema:(RLMSchema *)schema
                             dynamic:(bool)dynamic;

// FIXME - group should not be exposed
@property(nonatomic, readonly) wabi_realm::Group &group;
@end
