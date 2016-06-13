//
//  VideoFetcher.swift
//  Lupy
//
//  Created by Agree Ahmed on 5/26/16.
//  Copyright © 2016 Agree Ahmed. All rights reserved.
//

import Foundation
import CoreMedia
import AVFoundation
import Alamofire
import CoreData

class VideoFetcher: NSObject {
    
    static func fetchVideo(contentKey: String, completion: (NSURL?) -> ()) {
        let moviePath = VideoFetcher.getTempURLForKey(contentKey)
        let manager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(moviePath.path!) {
            let playerItem = AVPlayerItem(URL: moviePath)
            let duration = playerItem.asset.duration
            if duration != CMTimeMake(0, 1) {
                // update core data entry for the cached video, or create if it doesn't exist
                let appDelegate = AppDelegate.getAppDelegate()
                if !appDelegate.updateVideoCacheEntity(contentKey) {
                    appDelegate.createVideoCacheEntity(contentKey)
                }
                completion(moviePath)
                return
            } else {
                print("time was none, fetching from server")
                // delete the file, delete the coredata object
                deleteCachedVideo(contentKey)
                fetchVideoFromServer(contentKey, completion: completion)
            }
        } else {
            print("Fetching video from server")
            fetchVideoFromServer(contentKey, completion: completion)
        }
    }
    
    static func cleanVideoCache() {
        // delete all videos that haven't been accessed in 24 hours
        AppDelegate.getAppDelegate().deleteCachedVideoEntities(NSTimeInterval(60 * 60 * 24))
    }
    
    static func deleteCachedVideo(contentKey: String) -> Bool {
        if AppDelegate.getAppDelegate().deleteVideoCacheEntityAndFile(contentKey){
            let videoCacheURL = getTempURLForKey(contentKey)
            deleteFile(videoCacheURL)
            return true
        }
        return false
    }
    
    private static func fetchVideoFromServer(contentKey: String, completion: (NSURL?) -> ()) {
        let videoUrl = "https://s3.amazonaws.com/keyframecontent/" + contentKey + "/v.MOV"
        Alamofire.request(.GET, videoUrl).response { request, response, data, error in
            print("For \(contentKey), Fetched bytes: \(data!.length)")
            // based on bytes length: create core data entity
            let movieURL = self.writeVideoFile(contentKey, data: data!)
            completion(movieURL)
        }
    }
    
    private static func writeVideoFile(contentKey: String, data: NSData) -> NSURL? {
        if data.length < 20000 {
            return nil
        }
        let moviePath = getTempURLForKey(contentKey)
        do {
            try data.writeToFile(moviePath.path!, options: .AtomicWrite)
        } catch {
            print("\(error)")
        }
        let manager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(moviePath.path!) {
            AppDelegate.getAppDelegate().createVideoCacheEntity(contentKey)
            return moviePath
        }
        return nil
    }

    static func getTempURLForKey(contentKey: String) -> NSURL {
        let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let movieName = contentKey + ".MOV"
        return tempDir.URLByAppendingPathComponent(movieName)
    }

}


extension AppDelegate {
    // createVideoCacheEntity
    func createVideoCacheEntity(contentKey: String) -> Bool {
        let managedContext = self.managedObjectContext
        let entity =  NSEntityDescription.entityForName("Cached_video",
                                                        inManagedObjectContext:managedContext)
        let cachedVideo = NSManagedObject(entity: entity!,
                                       insertIntoManagedObjectContext: managedContext)
        cachedVideo.setValue(contentKey, forKey: "content_key")
        cachedVideo.setValue(NSDate().timeIntervalSince1970, forKey: "last_accessed")
        do {
            try managedContext.save()
            print("Saved cachedVideoEntity for \(contentKey)")
            return true
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        return false
    }
    
    func deleteCachedVideoEntities(timeSinceLastAccessed: NSTimeInterval) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "Cached_video")
        let earliestAcceptableLastAccess = NSDate().timeIntervalSince1970 - timeSinceLastAccessed
        fetchRequest.predicate = NSPredicate(format: "last_accessed < %f", earliestAcceptableLastAccess)
        do {
            if let results = try self.managedObjectContext.executeFetchRequest(fetchRequest) as? [NSManagedObject] {
                print("found \(results.count) stale videos to delete")
                return self.deleteVideoCacheEntitiesAndFiles(results)
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return false
        }
        return false
    }
    
    // deleteVideoCacheEntity
    func deleteVideoCacheEntityAndFile(contentKey: String) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "Cached_video")
        fetchRequest.predicate = NSPredicate(format: "content_key == %@", contentKey)
        do {
            if let results = try self.managedObjectContext.executeFetchRequest(fetchRequest) as? [NSManagedObject] {
                return self.deleteVideoCacheEntitiesAndFiles(results)
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            return false
        }
        return false
    }
    
    private func deleteVideoCacheEntitiesAndFiles(entities: [NSManagedObject]) -> Bool {
        let managedContext = self.managedObjectContext
        for entity in entities {
            managedContext.deleteObject(entity)
            let contentKey = entity.valueForKey("content_key") as! String
            let tempURL = VideoFetcher.getTempURLForKey(contentKey)
            deleteFile(tempURL)
            print("Deleting \(entity)")
        }
        do {
            try managedContext.save()
            return true
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return false
    }
    
    // updateVideoCacheEntity
    func updateVideoCacheEntity(contentKey: String) -> Bool {
        let predicate = NSPredicate(format: "content_key == %@", contentKey)
        let fetchRequest = NSFetchRequest(entityName: "Cached_video")
        fetchRequest.predicate = predicate
        
        do {
            let results = try self.managedObjectContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            if let first = results?.first {
                print("Updating for time interval: \(NSDate().timeIntervalSince1970)")
                first.setValue(NSDate().timeIntervalSince1970, forKey: "last_accessed")
            } else {
                return false
            }
            try self.managedObjectContext.save()
            print("Successfully updated : \(contentKey)")
            return true
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
        return false
    }
}