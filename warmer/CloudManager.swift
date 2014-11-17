
import Foundation
import CloudKit


class CloudManager : NSObject {
  
  var container = CKContainer.defaultContainer()
  var publicDB : CKDatabase!
  var privateDB : CKDatabase!
  var currentUserInfo: CKDiscoveredUserInfo?
  var currentUserRecord : CKRecord?
  
//MARK: Singleton Setup
  class var sharedInstance: CloudManager {
    struct Static {
      static let instance: CloudManager = CloudManager()
    }
    return Static.instance
  }
  
  override init() {
    self.publicDB = container.publicCloudDatabase
    self.privateDB = container.privateCloudDatabase
  }
  
//MARK: Permission
  func requestDiscoverabilityPermission (completionHandler:(Bool) -> ()) {
    
    self.container.requestApplicationPermission(CKApplicationPermissions.PermissionUserDiscoverability, completionHandler: { (applicationPermissionStatus, error) in
        
        if error != nil {
          println("An error occured: \(error!.localizedDescription)");
        } else {
         completionHandler(applicationPermissionStatus == CKApplicationPermissionStatus.Granted)
        }
    })
  }
 
//MARK: Record Fetch
  func getCurrentUserRecord (completionHandler:(Bool) -> ()) {
    
    self.container.fetchUserRecordIDWithCompletionHandler { (fetchedRecordID, error) in
    
      self.publicDB.fetchRecordWithID(fetchedRecordID, completionHandler: { (fetchedRecord, error) in
        
        self.currentUserRecord = fetchedRecord
        
        self.setupNickname(fetchedRecord, completionHandler: { (status) -> () in
          completionHandler(status)
        })
      })
    }
  }
  
  func getAllContactsOfUser(completionHandler:(Array<AnyObject>) -> ())  {
    
    self.container.discoverAllContactUserInfosWithCompletionHandler { (userInfos:[AnyObject]!, error: NSError!) -> Void in
      completionHandler(userInfos)
    }
  }
  
  func fetchRecordWithID(recordID:CKRecordID, completionHandler:(CKRecord) -> ()) {
    self.publicDB.fetchRecordWithID(recordID, completionHandler: { (fetchedRecord, error) in
      completionHandler(fetchedRecord)
    })
  }

//MARK: Saving Operations
  func updateWarmerUserLocation(location: CLLocation, completionHandler:(Bool) -> ())  {
    
    self.container.publicCloudDatabase.fetchRecordWithID(self.currentUserRecord?.recordID, completionHandler: { (fetchedRecord, error) in
      
      if error != nil {
        
        println("An error occured: \(error!.localizedDescription)");
        completionHandler (false)
      
      } else {
        
        fetchedRecord.setObject(location, forKey:LocationField)
        self.publicDB.saveRecord(fetchedRecord, completionHandler: { (savedRecord, error) in
          completionHandler(true)
          println("location updated")
        })
      }
    })
  }
  
  func setupNickname(record:CKRecord, completionHandler:(Bool) -> ()) {
    self.container.discoverUserInfoWithUserRecordID(record.recordID, completionHandler: { (userInfo, error) in
      
      userInfo as CKDiscoveredUserInfo
      var lastChar = userInfo.lastName[0]
      
      self.currentUserRecord?.setObject("\(userInfo.firstName) \(lastChar).", forKey: NameField)
      self.publicDB.saveRecord(self.currentUserRecord, completionHandler: { (savedRecord, error) in
        completionHandler(true)
      })
    })
  }
  
//MARK: MISC
  func hasSavedCurrentAccount() -> Bool {
    if self.currentUserRecord != nil {
      return true
    } else {
      return false
    }
  }

}


