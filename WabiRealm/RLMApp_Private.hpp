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

#import <WabiRealm/RLMApp_Private.h>

#import <wabi-realm/object-store/sync/app.hpp>

#import <memory>

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

RLM_DIRECT_MEMBERS
@interface RLMAppConfiguration ()
- (wabi_realm::app::App::Config &)config;
- (instancetype)initWithConfig:(const wabi_realm::app::App::Config &)config;
@end

RLM_DIRECT_MEMBERS
@interface RLMApp ()
- (std::shared_ptr<wabi_realm::app::App>)_realmApp;
- (instancetype)initWithApp:(std::shared_ptr<wabi_realm::app::App>)app;
@end

NSError *makeError(wabi_realm::app::AppError const &appError);

RLM_HEADER_AUDIT_END(nullability, sendability)
