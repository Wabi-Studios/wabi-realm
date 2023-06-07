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

#import <WabiRealm/RLMMigration.h>
#import <WabiRealm/RLMObjectBase.h>
#import <WabiRealm/RLMRealm.h>

namespace realm {
class Schema;
}

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@interface RLMMigration ()

@property(nonatomic, strong) RLMRealm *oldRealm;
@property(nonatomic, strong) RLMRealm *realm;

- (instancetype)initWithRealm:(RLMRealm *)realm
                     oldRealm:(RLMRealm *)oldRealm
                       schema:(realm::Schema &)schema;

- (void)execute:(RLMMigrationBlock)block objectClass:(_Nullable Class)cls;

@end

RLM_HEADER_AUDIT_END(nullability, sendability)
