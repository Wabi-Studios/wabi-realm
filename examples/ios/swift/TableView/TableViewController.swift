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

import UIKit
import WabiRealmKit

class DemoObject: Object {
  @Persisted var title: String
  @Persisted var date: Date
}

class Cell: UITableViewCell {
  override init(style _: UITableViewCell.CellStyle, reuseIdentifier: String!) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
  }

  @available(*, unavailable)
  required init(coder _: NSCoder) {
    fatalError("NSCoding not supported")
  }
}

class TableViewController: UITableViewController {
  let realm = try! WabiRealm()
  let results = try! WabiRealm().objects(DemoObject.self).sorted(byKeyPath: "date")
  var notificationToken: NotificationToken?

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()

    // Set results notification block
    notificationToken = results.observe { (changes: RealmCollectionChange) in
      switch changes {
      case .initial:
        // Results are now populated and can be accessed without blocking the UI
        self.tableView.reloadData()
      case let .update(_, deletions, insertions, modifications):
        // Query results have changed, so apply them to the TableView
        self.tableView.beginUpdates()
        self.tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        self.tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        self.tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
        self.tableView.endUpdates()
      case let .error(err):
        // An error occurred while opening the WabiRealm file on the background worker thread
        fatalError("\(err)")
      }
    }
  }

  // UI

  func setupUI() {
    tableView.register(Cell.self, forCellReuseIdentifier: "cell")

    title = "TableView"
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "BG Add", style: .plain,
                                                       target: self, action: #selector(backgroundAdd))
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                        target: self, action: #selector(add))
  }

  // Table view data source

  override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    return results.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! Cell

    let object = results[indexPath.row]
    cell.textLabel?.text = object.title
    cell.detailTextLabel?.text = object.date.description

    return cell
  }

  override func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      realm.beginWrite()
      realm.delete(results[indexPath.row])
      try! realm.commitWrite()
    }
  }

  // Actions

  @objc func backgroundAdd() {
    // Import many items in a background thread
    DispatchQueue.global().async {
      // Get new realm and table since we are in a new thread
      autoreleasepool {
        let realm = try! WabiRealm()
        realm.beginWrite()
        for _ in 0 ..< 5 {
          // Add row via dictionary. Order is ignored.
          realm.create(DemoObject.self, value: ["title": TableViewController.randomString(), "date": TableViewController.randomDate()])
        }
        try! realm.commitWrite()
      }
    }
  }

  @objc func add() {
    realm.beginWrite()
    realm.create(DemoObject.self, value: [TableViewController.randomString(), TableViewController.randomDate()])
    try! realm.commitWrite()
  }

  // Helpers

  class func randomString() -> String {
    return "Title \(Int.random(in: 0 ..< 100))"
  }

  class func randomDate() -> NSDate {
    return NSDate(timeIntervalSince1970: TimeInterval.random(in: 0 ..< TimeInterval.greatestFiniteMagnitude))
  }
}
