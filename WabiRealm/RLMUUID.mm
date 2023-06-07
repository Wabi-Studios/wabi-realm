////////////////////////////////////////////////////////////////////////////
//
// Copyright 2020 WabiRealm Inc.
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

#import "RLMUUID_Private.hpp"

#import <wabi-realm/uuid.hpp>

@implementation NSUUID (RLMUUIDSupport)

- (instancetype)initWithRealmUUID:(wabi_realm::UUID)rUuid {
  self = [self initWithUUIDBytes:rUuid.to_bytes().data()];
  return self;
}

- (wabi_realm::UUID)rlm_uuidValue {
  return wabi_realm::UUID(self.UUIDString.UTF8String);
}

@end