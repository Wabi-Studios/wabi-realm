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

import WabiRealm

public extension WabiRealm {
  /**
    Struct that describes the error codes within the WabiRealm error domain.
    The values can be used to catch a variety of _recoverable_ errors, especially those
    happening when initializing a WabiRealm instance.

    ```swift
    let realm: WabiRealm?
    do {
        realm = try WabiRealm()
    } catch WabiRealm.Error.incompatibleLockFile {
        print("WabiRealm Browser app may be attached to WabiRealm on device?")
    }
    ```
   */
  typealias Error = RLMError
}

public extension WabiRealm.Error {
  /// This error could be returned by completion block when no success and no error were produced
  static let callFailed = WabiRealm.Error(WabiRealm.Error.fail, userInfo: [NSLocalizedDescriptionKey: "Call failed"])

  /// The file URL which produced this error, or `nil` if not applicable
  var fileURL: URL? {
    return (userInfo[NSFilePathErrorKey] as? String).flatMap(URL.init(fileURLWithPath:))
  }
}

// MARK: Equatable

extension WabiRealm.Error: Equatable {}

// FIXME: we should not be defining this but it's a breaking change to remove
/// Returns a Boolean indicating whether the errors are identical.
public func == (lhs: Error, rhs: Error) -> Bool {
  return lhs._code == rhs._code
    && lhs._domain == rhs._domain
}
