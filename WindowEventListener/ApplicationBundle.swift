//
//  ApplicationBundle.swift
//  WindowWatcher
//
//  Created by Quentin Liardeaux on 7/22/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved.
//

import Foundation

public protocol ApplicationBundle {
    associatedtype T: WindowInfo
    
    var windowBuffer: [T] { get }
    var windows: [T] { get }
    var pid: Int { get }
    var runningApp: NSRunningApplication { get }

    func addToBuffer(window: T)
    func raiseEvents()
}

public class PublisherApplicationBundle: ApplicationBundle, Publisher {
    public weak var notificationCenter: WindowNotificationCenter?
    public typealias T = BasicWindow

    public var windowBuffer: [BasicWindow]
    public var windows: [BasicWindow]
    public var pid: Int
    public var runningApp: NSRunningApplication

    public init(pid: Int) throws {
        self.windows = []
        self.windowBuffer = []
        self.pid = pid
        guard let app = NSRunningApplication(processIdentifier: pid_t(pid)) else {
            throw NSError(domain: "Invalid pid", code: 0, userInfo: nil)
        }
        self.runningApp = app
        self.notificationCenter = WindowNotificationCenter.shared
    }

    public func addToBuffer(window: BasicWindow) {
        windowBuffer.append(window)
    }

    public func raiseEvents() {
        for window in windowBuffer
            where !windows.contains(where: { $0 <=> window }) {
            notificationCenter?.notify(topic: TopicIdentifier(id: "open", subid: nil), userInfo: nil)
        }
        for window in windows
            where !windowBuffer.contains(where: { $0 <=> window }) {
            notificationCenter?.notify(topic: TopicIdentifier(id: "open", subid: nil), userInfo: nil)
        }
        for window in windowBuffer
            where !windows.contains(window) {
            windows.append(window)
        }
        windowBuffer.removeAll()
    }
}

public protocol ApplicationBundleDelegate: class {
    func appBundle(_ app: DelegatableApplicationBundle, createWindowWithUuid uuid: String)
    func appBundle(_ app: DelegatableApplicationBundle, openWindowWithUuid uuid: String)
    func appBundle(_ app: DelegatableApplicationBundle, closeWindowWithUuid uuid: String)
}

public class DelegatableApplicationBundle: ApplicationBundle {
    public typealias T = BasicWindow
    
    public var windowBuffer: [BasicWindow]
    public var windows: [BasicWindow]
    public var pid: Int
    public var runningApp: NSRunningApplication
    public weak var delegate: ApplicationBundleDelegate?
    
    public init(pid: Int) throws {
        self.windows = []
        self.windowBuffer = []
        self.pid = pid
        guard let app = NSRunningApplication(processIdentifier: pid_t(pid)) else {
            throw NSError(domain: "Invalid pid", code: 0, userInfo: nil)
        }
        self.runningApp = app
    }
    
    public func addToBuffer(window: BasicWindow) {
        windowBuffer.append(window)
    }
    
    public func raiseEvents() {
        for window in windowBuffer {
            if windows.contains(where: { $0 <=> window}) {
                continue
            }
            delegate?.appBundle(self, openWindowWithUuid: window.uuid)
            windows.append(window)
        }
        for window in windows {
            if windowBuffer.contains(where: { $0 <=> window }) {
                continue
            }
            delegate?.appBundle(self, closeWindowWithUuid: window.uuid)
        }
        windowBuffer.removeAll()
    }
}
