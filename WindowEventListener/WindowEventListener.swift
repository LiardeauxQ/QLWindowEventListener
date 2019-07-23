//
//  WindowWatcher.swift
//  WindowWatcher
//
//  Created by Quentin Liardeaux on 7/22/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved.
//

import Foundation

public class WindowEventListener {
    var watchingBundleIdentifiers: [String]
    var refreshTime: TimeInterval = 5
    var actionTimer: RepeatingTimer

    public init() {
        watchingBundleIdentifiers = []
        actionTimer = RepeatingTimer(timeInterval: self.refreshTime)
    }

    public func startListening() {
        actionTimer.eventHandler = {
            self.fetchOpenApplications()
        }
        actionTimer.resume()
    }

    func fetchOpenApplications() {
    }

    public func add(bundleIdentifierToWatch bundleId: String) {
        watchingBundleIdentifiers.append(bundleId)
    }

    public func stopListening() {
        actionTimer.suspend()
    }
}

public class PublisherWindowEventListener: WindowEventListener {
    private var applicationBundles: [PublisherApplicationBundle]

    override public init() {
        applicationBundles = []
        super.init()
    }

    override func fetchOpenApplications() {
        let windowInfosRef = CGWindowListCopyWindowInfo(CGWindowListOption.optionOnScreenOnly, CGWindowID(0))
        let windowInfos = windowInfosRef as? [[String: Any]] ?? []

        for windowInfo in windowInfos {
            guard let pid = windowInfo["kCGWindowOwnerPID"] as? Int else {
                continue
            }
            guard let bundle = applicationBundles.first(where: { $0.pid == pid}) else {
                guard let app = try? PublisherApplicationBundle(pid: pid),
                    watchingBundleIdentifiers.contains(app.runningApp.bundleIdentifier ?? "") else {
                        continue
                }
                if let window = BasicWindow(data: windowInfo) {
                    app.addToBuffer(window: window)
                }
                applicationBundles.append(app)
                continue
            }
            if watchingBundleIdentifiers.contains(bundle.runningApp.bundleIdentifier ?? ""),
                let window = BasicWindow(data: windowInfo) {
                bundle.addToBuffer(window: window)
            }
        }
        applicationBundles.forEach({ $0.raiseEvents() })
    }
}

public class DelegatableWindowEventListener: WindowEventListener {
    private var applicationBundles: [DelegatableApplicationBundle]
    private var waitingDelegate: [(ApplicationBundleDelegate, String)]
    private var registerDelegates: [ApplicationBundleDelegate]

    override public init() {
        applicationBundles = []
        waitingDelegate = []
        registerDelegates = []
        super.init()
    }

    override func fetchOpenApplications() {
        let windowInfosRef = CGWindowListCopyWindowInfo(CGWindowListOption.optionOnScreenOnly, CGWindowID(0))
        let windowInfos = windowInfosRef as? [[String: Any]] ?? []

        for windowInfo in windowInfos {
            guard let pid = windowInfo["kCGWindowOwnerPID"] as? Int else {
                continue
            }
            guard let bundle = applicationBundles.first(where: { $0.pid == pid}) else {
                guard let app = try? DelegatableApplicationBundle(pid: pid),
                    watchingBundleIdentifiers.contains(app.runningApp.bundleIdentifier ?? "") else {
                        continue
                }
                if let window = BasicWindow(data: windowInfo) {
                    app.addToBuffer(window: window)
                }
                applicationBundles.append(app)
                continue
            }
            if watchingBundleIdentifiers.contains(bundle.runningApp.bundleIdentifier ?? ""),
                let window = BasicWindow(data: windowInfo) {
                bundle.addToBuffer(window: window)
            }
        }
        updateDelegate()
        applicationBundles.forEach({ $0.raiseEvents() })
    }

    public func add(delegate: ApplicationBundleDelegate, toBundleIdentifier bundleId: String) {
        for bundle in applicationBundles {
            if bundle.runningApp.bundleIdentifier == bundleId {
                registerDelegates.append(delegate)
                bundle.delegate = delegate
                return
            }
        }
        waitingDelegate.append((delegate, bundleId))
    }

    private func updateDelegate() {
        var delegateBuffer: [(ApplicationBundleDelegate, String)] = []

        for _ in 0 ..< waitingDelegate.count {
            delegateBuffer.append(waitingDelegate.removeFirst())
        }
        for value in delegateBuffer {
            add(delegate: value.0, toBundleIdentifier: value.1)
        }
    }
}
