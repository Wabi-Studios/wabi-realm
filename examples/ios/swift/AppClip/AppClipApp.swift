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

import SwiftUI
import WabiRealmKit

@main
struct AppClipApp: SwiftUI.App {
  var body: some Scene {
    WindowGroup {
      // This is ContentView.swift shared from AppClipParent
      ContentView(objects: demoObjects().list)
    }
  }

  private func demoObjects() -> DemoObjects {
    let config = WabiRealm.Configuration(fileURL: FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Constants.groupId)!.appendingPathComponent("default.realm"))
    let realm = try! WabiRealm(configuration: config)

    if let demoObjects = realm.object(ofType: DemoObjects.self, forPrimaryKey: 0) {
      return demoObjects
    } else {
      return try! realm.write { realm.create(DemoObjects.self, value: []) }
    }
  }
}
