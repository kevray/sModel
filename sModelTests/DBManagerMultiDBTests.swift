import XCTest
@testable import sModel

class DBManagerMultiDBTests: XCTestCase {

  override func setUp() {
    super.setUp()
    openDB()
  }

  override func tearDown() {
    DBManager.close()
    super.tearDown()
  }

  private func openDB() {
    var paths = DBManager.getDBDefFiles(bundle: Bundle(for: type(of: self)))!
    paths.sort()

    try! DBManager.open(nil, dbDefFilePaths: paths)
  }

  func testDatabaseStack() {
    insertThing("tid1", name: "thing 1")
    guard Thing.firstInstanceWhere("tid = ?", params: "tid1") != nil else {
      XCTFail("Thing should have had a value")
      return
    }

    openDB()

    guard Thing.firstInstanceWhere("tid = ?", params: "tid1") == nil else {
      XCTFail("Thing should not have value in new db")
      return
    }

    insertThing("tid2", name: "thing 2")
    guard Thing.firstInstanceWhere("tid = ?", params: "tid2") != nil else {
      XCTFail("Thing2 should have had a value")
      return
    }

    DBManager.close()

    guard Thing.firstInstanceWhere("tid = ?", params: "tid1") != nil else {
      XCTFail("Thing should have had a value")
      return
    }
    guard Thing.firstInstanceWhere("tid = ?", params: "tid2") == nil else {
      XCTFail("Thing2 should not have had a value")
      return
    }
  }

  @discardableResult
  private func insertThing(_ tid: String, name: String) -> Thing {
    let newThing = Thing()
    newThing.tid = tid
    newThing.name = name
    newThing.save()

    return newThing
  }
}
