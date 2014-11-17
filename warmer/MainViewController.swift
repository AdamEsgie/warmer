//
//  ViewController.swift
//  warmer
//
//  Created by Adam Salvitti-Gucwa on 11/10/14.
//  Copyright (c) 2014 Esgie. All rights reserved.
//

import UIKit
import CloudKit

class MainViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource{

  var locationMgr : CLLocationManager!
  var linkButton = UIButton()
  var contactIDArray = NSMutableArray()
  var contactRecordArray = NSMutableArray()
  var tableView: UITableView!
  
//MARK: View Setup
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.backgroundColor = UIColor.orangeColor()
    self.locationMgr = CLLocationManager()
    self.locationMgr.delegate = self
    self.locationMgr.desiredAccuracy = kCLLocationAccuracyBest
    self.locationMgr.requestAlwaysAuthorization()
    
    self.tableView = UITableView(frame: CGRectMake(0, 100, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 200), style: UITableViewStyle.Plain)
    self.tableView.delegate = self
    self.tableView.dataSource = self
    self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
    self.tableView.tableFooterView = UIView(frame: CGRectZero)
    self.tableView.backgroundColor = UIColor.clearColor()
    self.tableView.reloadData()
    self.view.addSubview(self.tableView)
    
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
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector:"findFriends", name: UIApplicationDidBecomeActiveNotification, object: nil)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

  }
  
  override func viewWillDisappear(animated: Bool) {
    NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
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

//MARK: TableView
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.contactRecordArray.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell: UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell
    var record = self.contactRecordArray.objectAtIndex(indexPath.row) as CKRecord
    
    var text = (record.objectForKey(NameField) as String)
    println(text)
    cell.textLabel.text = text
    cell.textLabel.textColor = UIColor.whiteColor()
    cell.backgroundColor = UIColor.clearColor()

    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
  }
  
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

//MARK: NSNotification
  func findFriends () {
    
    CloudManager.sharedInstance.getAllContactsOfUser( { (recordArray) -> () in
      
      for userInfo in recordArray as [CKDiscoveredUserInfo]{
        if userInfo.userRecordID.recordName != CloudManager.sharedInstance.currentUserRecord?.recordID.recordName {
          if !(self.contactIDArray.containsObject(userInfo.userRecordID)) {
            self.contactIDArray.addObject(userInfo.userRecordID)
            
            CloudManager.sharedInstance.fetchRecordWithID(userInfo.userRecordID, completionHandler: { (record) -> () in
              self.contactRecordArray.addObject(record)
              var indexPath = NSIndexPath(forRow:self.contactRecordArray.count-1, inSection: 0)
             
              dispatch_async(dispatch_get_main_queue(), {
                self.tableView.beginUpdates()
                self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                self.tableView.endUpdates()
              })

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
}

