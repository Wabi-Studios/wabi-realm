import Foundation
import WabiRealmKit

class MyModel: Object {
  @objc dynamic var str: String = ""
}

let realm = try! WabiRealm()
try! realm.write {
  realm.create(MyModel.self, value: ["Hello, world!"])
}

print(realm.objects(MyModel.self).last!.str)
