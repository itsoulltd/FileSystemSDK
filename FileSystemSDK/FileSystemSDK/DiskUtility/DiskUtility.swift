//
//  DiskUtility.swift
//  Jamahook
//
//  Created by Towhid on 12/22/15.
//  Copyright © 2017 Next Generation Object Ltd. All rights reserved.
//

import UIKit

@objc(SpaceIn)
public enum SpaceIn: Int{
    case bytes, kb, mb, gb, tb
}

@objc(DiskUtility)
open class DiskUtility: NSObject {
    
    open class func documentDirectoryPath() -> NSString{
        let array = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true) as NSArray
        return array.lastObject as! NSString
    }

    fileprivate class func diskSpace(byKey key: String) -> NSNumber?{
        let path = DiskUtility.documentDirectoryPath()
        do{
            if let info = try FileManager.default.attributesOfFileSystem(forPath: path as String) as NSDictionary?{
                let sizeInBytes = info.object(forKey: key) as? NSNumber
                return sizeInBytes
            }
        } catch let error as NSError{
            print("\(#function) at line \(#line) \(error.debugDescription)")
        }
        return nil
    }
    
    open class func totalSpaceIn(_ space: SpaceIn = .bytes) -> Double{
        if let total = DiskUtility.diskSpace(byKey: FileAttributeKey.systemSize.rawValue){
            let divisor: Double = DiskUtility.getValue(total.doubleValue, space: space)
            return divisor
        }
        return 0.0
    }
    
    open class func freeSpaceIn(_ space: SpaceIn = .bytes) -> Double{
        if let free = DiskUtility.diskSpace(byKey: FileAttributeKey.systemFreeSize.rawValue){
            let divisor: Double = DiskUtility.getValue(free.doubleValue, space: space)
            return divisor
        }
        return 0.0
    }
    
    fileprivate class func getValue(_ value: Double, space: SpaceIn) -> Double{
        var factor: Double = 1.0
        switch space{
        case .tb:
            factor = value / 1024.0 / 1024.0 / 1024.0 / 1024.0
            break
        case .gb:
            factor = value / 1024.0 / 1024.0 / 1024.0
            break
        case .mb:
            factor = value / 1024.0 / 1024.0
            break
        case .kb:
            factor = value / 1024.0
            break
        default:
            factor = value
        }
        return factor
    }
    
}
