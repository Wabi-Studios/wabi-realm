////////////////////////////////////////////////////////////////////////////
//
// Copyright 2017 WabiRealm Inc.
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

#import "RLMRealm+Sync.h"

#import "RLMObjectBase.h"
#import "RLMObjectSchema.h"
#import "RLMQueryUtil.hpp"
#import "RLMRealm_Private.hpp"
#import "RLMResults_Private.hpp"
#import "RLMSchema.h"
#import "RLMSyncSession.h"

#import <realm/object-store/results.hpp>
#import <realm/object-store/shared_realm.hpp>

using namespace realm;

@implementation RLMRealm (Sync)

- (RLMSyncSession *)syncSession {
  return [RLMSyncSession sessionForRealm:self];
}

@end
