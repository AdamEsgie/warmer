//
//  ViewController.swift
//  warmer
//
//  Created by Adam Salvitti-Gucwa on 11/10/14.
//  Copyright (c) 2014 Esgie. All rights reserved.
//

import UIKit
import CloudKit

let CellIdentifier: String = "cell"

class MainViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource{

  var locationMgr : CLLocationManager!
  var linkButton = UIButton()
  var contactIDArray = NSMutableArray()
  var contactRecordArray = NSMutableArray()
  var tableView = UITableView()
  
//MARK: View Setup
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = UIColor.orangeColor()
    self.locationMgr = CLLocationManager()
    self.locationMgr.delegate = self
    self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
    self.locationMgr.requestAlwaysAuthorization()
    
    self.tableView.delegate = self
    self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
    
    if (!CloudManager.sharedInstance.hasSavedCurrentAccount()) {
      
      CloudManager.sharedInstance.requestDiscoverabilityPermission { (status) -> () in
       
        if status == true {
          
          CloudManager.sharedInstance.getCurrentUserRecord({ (status) -> () in
            
            if status == true {
              self.locationMgr.startUpdatingLocation()
              println("success")
            } else {
              println("error")
            }
          
          })
        }
      }
    } else {
      
      self.locationMgr.startUpdatingLocation()
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    self.linkButton.frame = CGRectMake(CGRectGetWidth(self.view.bounds) / 2 - 100, CGRectGetHeight(self.view.bounds) - 110, 200, 100)
    self.linkButton.backgroundColor = UIColor.whiteColor()
    self.linkButton.addTarget(self, action:"linkAction:", forControlEvents:UIControlEvents.TouchUpInside)
    self.view.addSubview(self.linkButton)

  }

//MARK: Core Location Delegate
  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    
    var locationsArray = locations as NSArray
    var locationObj = locationsArray.lastObject as CLLocation
    
    CloudManager.sharedInstance.updateWarmerUserLocation(locationObj, completionHandler: { (updated) -> () in
      println(updated)
    })
  }
  
  func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
    println(error)
  
  }

//MARK: IBAction
  func linkAction(sender: UIButton) {
   CloudManager.sharedInstance.getAllContactsOfUser( { (recordArray) -> () in
    
    for userInfo in recordArray as [CKDiscoveredUserInfo]{
      if userInfo.userRecordID.recordName != CloudManager.sharedInstance.currentUserRecord?.recordID.recordName {
        if !(self.contactIDArray.containsObject(userInfo.userRecordID)) {
          self.contactIDArray.addObject(userInfo.userRecordID)
          
          CloudManager.sharedInstance.fetchRecordWithID(userInfo.userRecordID, completionHandler: { (record) -> () in
            self.contactRecordArray.addObject(record)
            
            //add back if have more users
            
//            CloudManager.sharedInstance.setupNickname(record, completionHandler: { (status) -> () in
//              println(status)
//            })
          })
        }
      }
    }
   })
  }

//MARK: TableView
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.contactRecordArray.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    var cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell
    
    var record = self.contactRecordArray.objectAtIndex(indexPath.row) as CKRecord 
    
    return cell
  
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }


}

