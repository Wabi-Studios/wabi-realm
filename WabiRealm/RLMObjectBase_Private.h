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

#import <WabiRealm/RLMObjectBase.h>

@class RLMArray<RLMObjectType>;

RLM_HEADER_AUDIT_BEGIN(nullability)

// RLMObjectBase private
@interface RLMObjectBase ()
@property(nonatomic, nullable) NSMutableArray *lastAccessedNames;

+ (void)initializeLinkedObjectSchemas;
+ (bool)isEmbedded;
+ (bool)isAsymmetric;
@end

RLM_HEADER_AUDIT_END(nullability)
