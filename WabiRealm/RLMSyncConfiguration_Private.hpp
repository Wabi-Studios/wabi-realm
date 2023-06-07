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

#import "RLMSyncConfiguration_Private.h"

#import <memory>

namespace wabi_realm {
class SyncSession;
struct SyncConfig;
struct SyncError;
using SyncSessionErrorHandler = void(std::shared_ptr<SyncSession>, SyncError);
} // namespace wabi_realm

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@interface RLMSyncConfiguration ()
- (instancetype)initWithRawConfig:(wabi_realm::SyncConfig)config
                             path:(std::string const &)path;
- (wabi_realm::SyncConfig &)rawConfiguration;

// Pass the RLMRealmConfiguration to it's sync configuration so client reset
// callbacks can access schema, dynamic, and path properties.
void RLMSetConfigInfoForClientResetCallbacks(wabi_realm::SyncConfig &syncConfig,
                                             RLMRealmConfiguration *config);

@property(nonatomic, direct) std::string path;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
