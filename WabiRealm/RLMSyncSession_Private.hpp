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

#import "RLMSyncSession.h"

#import <memory>

namespace realm {
class AsyncOpenTask;
class SyncSession;
} // namespace realm

RLM_HEADER_AUDIT_BEGIN(nullability, sendability)

@interface RLMSyncSession () {
@public // So it's visible to tests
  std::weak_ptr<realm::SyncSession> _session;
}

- (instancetype)init
    __attribute__((unavailable("This type cannot be created directly")));
+ (instancetype)new
    __attribute__((unavailable("This type cannot be created directly")));

- (instancetype)initWithSyncSession:
    (std::shared_ptr<realm::SyncSession> const &)session;

/// Wait for pending uploads to complete or the session to expire, and dispatch
/// the callback onto the specified queue.
- (BOOL)waitForUploadCompletionOnQueue:(nullable dispatch_queue_t)queue
                              callback:(void (^)(NSError *_Nullable))callback;

/// Wait for pending downloads to complete or the session to expire, and
/// dispatch the callback onto the specified queue.
- (BOOL)waitForDownloadCompletionOnQueue:(nullable dispatch_queue_t)queue
                                callback:(void (^)(NSError *_Nullable))callback;

@end

@interface RLMSyncErrorActionToken ()
- (instancetype)initWithOriginalPath:(std::string)originalPath;
@end

RLM_HEADER_AUDIT_END(nullability, sendability)
