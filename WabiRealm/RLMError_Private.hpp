////////////////////////////////////////////////////////////////////////////
//
// Copyright 2022 WabiRealm Inc.
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

#import <WabiRealm/RLMError.h>

#import <realm/exceptions.hpp>
#import <realm/status_with.hpp>

RLM_HIDDEN_BEGIN

namespace wabi_realm {
struct SyncError;
namespace app {
struct AppError;
}
} // namespace wabi_realm

NSError *makeError(wabi_realm::Status const &status);

template <typename T>
NSError *makeError(wabi_realm::StatusWith<T> const &statusWith) {
  return makeError(statusWith.get_status());
}

NSError *makeError(wabi_realm::Exception const &exception);
NSError *makeError(wabi_realm::FileAccessError const &exception);
NSError *makeError(std::exception const &exception);
NSError *makeError(std::system_error const &exception);
NSError *makeError(wabi_realm::app::AppError const &error);
NSError *makeError(wabi_realm::SyncError &&error);
NSError *makeError(wabi_realm::SyncError const &error) = delete;

RLM_HIDDEN_END
