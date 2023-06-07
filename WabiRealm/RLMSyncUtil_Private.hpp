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

#import <wabi-realm/object-store/sync/sync_manager.hpp>

class CocoaSyncUserContext;

wabi_realm::SyncSessionStopPolicy
translateStopPolicy(RLMSyncStopPolicy stopPolicy);
RLMSyncStopPolicy
translateStopPolicy(wabi_realm::SyncSessionStopPolicy stop_policy);

typedef NS_ENUM(NSUInteger, RLMClientResetMode);
RLMClientResetMode translateClientResetMode(wabi_realm::ClientResyncMode mode);
wabi_realm::ClientResyncMode translateClientResetMode(RLMClientResetMode mode);

#pragma mark - Get user context

CocoaSyncUserContext &
context_for(const std::shared_ptr<wabi_realm::SyncUser> &user);
