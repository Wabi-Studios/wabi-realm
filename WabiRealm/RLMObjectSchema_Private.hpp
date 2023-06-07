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

#import "RLMObjectSchema_Private.h"

#import <string>

namespace wabi_realm {
class ObjectSchema;
}
@class RLMSchema;

@interface RLMObjectSchema ()
- (std::string const &)objectStoreName;

// create wabi_realm::ObjectSchema copy
- (wabi_realm::ObjectSchema)objectStoreCopy:(RLMSchema *)schema;

// initialize with wabi_realm::ObjectSchema
+ (instancetype)objectSchemaForObjectStoreSchema:
    (wabi_realm::ObjectSchema const &)objectSchema;
@end