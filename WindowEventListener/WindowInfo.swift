//
//  WindowInfo.swift
//  WindowWatcher
//
//  Created by Quentin Liardeaux on 7/22/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved.
//

import Foundation

public protocol WindowInfo: Equatable {
    var alpha: Double { get }
    var layer: Int { get }
    var memoryUsage: UInt64 { get }
    var number: UInt { get }
    var ownerPid: Int { get }
    var sharingState: Int { get }
    var storageType: Int { get }
    var isOnScreen: Bool? { get }
    var name: String? { get }
    var ownerName: String? { get }
    var uuid: String { get }

    init?(data: [String: Any]?)
}

infix operator <=>

public class BasicWindow: WindowInfo {

    public var alpha: Double
    public var layer: Int
    public var memoryUsage: UInt64
    public var number: UInt
    public var ownerPid: Int
    public var sharingState: Int
    public var storageType: Int
    public var isOnScreen: Bool?
    public var name: String?
    public var ownerName: String?
    public var uuid: String

    init(_ alpha: Double, _ layer: Int, _ memoryUsage: UInt64,
         _ number: UInt, _ ownerPid: Int, _ sharingState: Int, _ storageType: Int,
         _ isOnScreen: Bool?, _ name: String?, _ ownerName: String?) {
        self.alpha = alpha
        self.layer = layer
        self.memoryUsage = memoryUsage
        self.number = number
        self.ownerPid = ownerPid
        self.sharingState = sharingState
        self.storageType = storageType
        self.isOnScreen = isOnScreen
        self.name = name
        self.ownerName = ownerName
        self.uuid = NSUUID().uuidString
    }

    public required init?(data: [String : Any]?) {
        guard let alpha = data?["kCGWindowAlpha"] as? Double,
            let layer = data?["kCGWindowLayer"] as? Int,
            let memoryUsage = data?["kCGWindowMemoryUsage"] as? UInt64,
            let number = data?["kCGWindowNumber"] as? UInt,
            let ownerPid = data?["kCGWindowOwnerPID"] as? Int,
            let sharingState = data?["kCGWindowSharingState"] as? Int,
            let storageType = data?["kCGWindowStoreType"] as? Int else {
            return nil
        }

        self.alpha = alpha
        self.layer = layer
        self.memoryUsage = memoryUsage
        self.number = number
        self.ownerPid = ownerPid
        self.sharingState = sharingState
        self.storageType = storageType
        self.isOnScreen = data?["kCGWindowIsOnscreen"] as? Bool
        self.name = data?["kCGWindowName"] as? String
        self.ownerName = data?["kCGWindowOwnerName"] as? String
        self.uuid = NSUUID().uuidString
    }

    static public func <=> (lhs: BasicWindow, rhs: BasicWindow) -> Bool { // soft equivalence (objects can be different)
        if lhs.ownerPid == rhs.ownerPid && lhs.number == rhs.number {
            return true
        }
        return false
    }

    static public func == (lhs: BasicWindow, rhs: BasicWindow) -> Bool { // stricte equivalence (objects have to be the same)
        if lhs.uuid == rhs.uuid {
            return true
        }
        return false
    }
}
