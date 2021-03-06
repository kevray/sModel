//
//  sModelPublicInterfaceTests.swift
//  sModel
//
//  Created by Stephen Lynn on 11/22/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import XCTest
import sModel

class sModelPublicInterfaceTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    
    var paths = DBManager.getDBDefFiles(bundle: Bundle(for: type(of: self)))!
    paths.sort()
    
    try! DBManager.open(nil, dbDefFilePaths: paths)
  }
  
  override func tearDown() {
    DBManager.close()
    super.tearDown()
  }
  
  func testGetDBDefFiles() {
    guard let paths = DBManager.getDBDefFiles(bundle: Bundle(for: type(of: self))) else {
      XCTFail("Should have found .sql files in test project")
      return
    }
    
    XCTAssertEqual(2, paths.count)
  }
  
  func testGenerateUUID() {
    let uuid = Thing.generateUUID()
    XCTAssertTrue(!uuid.isEmpty)
  }
  
  func testInsertAndFirstInstance() {
    let newThing = insertThing("tid1", name: "thing 1")
    XCTAssertEqual(newThing.existsInDatabase, true)
    
    let thingFromDB = Thing.firstInstanceWhere("tid = ?", params: "tid1")
    XCTAssertNotNil(thingFromDB)
    XCTAssertEqual(thingFromDB?.tid, "tid1")
    XCTAssertEqual(thingFromDB?.name, "thing 1")
  }
  
  func testInsertAndInstancesWhere() {
    insertABunchOfThings(10)
    
    let thingsFromDB = Thing.instancesWhere("tid = ?", params: "tid3")
    XCTAssertNotNil(thingsFromDB)
    let thing = thingsFromDB[0]
    XCTAssertEqual(thing.tid, "tid3")
    XCTAssertEqual(thing.name, "thing 3")
  }
  
  func testUpdateInstance() {
    let newThing = insertThing("tid1", name: "thing 1")
    
    newThing.name = "otherThing 1"
    newThing.save()
    
    XCTAssertEqual(newThing.name, "otherThing 1")
    
    let thingFromDB = Thing.firstInstanceWhere("tid = ?", params: "tid1")
    XCTAssertEqual(thingFromDB?.name, "otherThing 1")
  }
  
  func testReload() {
    let newThing = insertThing("tid1", name: "thing 1")
    newThing.name = "changedName"
    
    newThing.reload()
    
    XCTAssertEqual(newThing.name, "thing 1")
  }
  
  func testInstancesWhere() {
    insertABunchOfThings(10)
    
    let things = Thing.instancesWhere("tid in (?, ?)", params: "tid1", "tid2")
    
    XCTAssertEqual(things.count, 2)
    XCTAssertEqual(things[0].name, "thing 1")
    XCTAssertEqual(things[1].name, "thing 2")
  }
  
  func testInstances() {
    insertABunchOfThings(10)
    
    let things = Thing.instances("Select * FROM Thing WHERE tid IN (?, ?)", params: "tid1", "tid2")
    
    XCTAssertEqual(things.count, 2)
    XCTAssertEqual(things[0].name, "thing 1")
    XCTAssertEqual(things[1].name, "thing 2")
  }
  
  func testInstancesOrderedBy() {
    insertABunchOfThings(10)
    
    let things = Thing.instancesOrderedBy("tid ASC")
    
    XCTAssertEqual(things.count, 10)
    XCTAssertEqual(things[0].name, "thing 0")
    
    let moreThings = Thing.instancesOrderedBy("tid DESC")
    
    XCTAssertEqual(moreThings.count, 10)
    XCTAssertEqual(moreThings[0].name, "thing 9")
  }
  
  func testAllInstances() {
    insertABunchOfThings(10)
    
    let things = Thing.allInstances()
    
    XCTAssertEqual(things.count, 10)
    XCTAssertEqual(things[0].name, "thing 0")
  }
  
  func testDeleteInstance() {
    let newThing = insertThing("tid1", name: "thing 1")
    XCTAssertFalse(newThing.isDeleted)
    XCTAssertFalse(newThing.calledDidDelete)
    
    let thingFromDB = Thing.firstInstanceWhere("tid = ?", params: "tid1")
    XCTAssertNotNil(thingFromDB)
    
    newThing.delete()
    
    XCTAssertTrue(newThing.isDeleted)
    XCTAssertTrue(newThing.calledDidDelete)
    
    let thingAgainFromDB = Thing.firstInstanceWhere("tid = ?", params: "tid1")
    XCTAssertNil(thingAgainFromDB)
  }
  
  func testDeleteAllInstances() {
    insertABunchOfThings(10)
    
    let things = Thing.allInstances()
    XCTAssertEqual(things.count, 10)
    
    Thing.deleteAllInstances()
    
    let leftThings = Thing.allInstances()
    XCTAssertEqual(leftThings.count, 0)
  }
  
  func testDeleteWhere() {
    insertABunchOfThings(10)
    
    let things = Thing.allInstances()
    XCTAssertEqual(things.count, 10)
    
    Thing.deleteWhere("tid = ?", params: "tid1")
    
    let leftThings = Thing.allInstances()
    XCTAssertEqual(leftThings.count, 9)
  }
  
  func testNumberOfInstancesWhere() {
    insertABunchOfThings(10)
    
    let count = Thing.numberOfInstancesWhere("tid = ?", params: "tid1")
    XCTAssertEqual(count, 1)
  }
  
  func testNumberOfInstancesWhere_noWhereClause() {
    insertABunchOfThings(10)
    
    let count = Thing.numberOfInstancesWhere(nil)
    XCTAssertEqual(count, 10)
  }
  
  func testGenericQuery() {
    insertABunchOfThings(10)
    
    DBManager.executeUpdateQuery("DELETE FROM THING")
    
    let leftThings = Thing.allInstances()
    XCTAssertEqual(leftThings.count, 0)
  }
  
  //MARK: Private helpers
  private func insertABunchOfThings(_ count: Int) {
    for i in 0..<count {
      insertThing("tid\(i)", name: "thing \(i)")
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
