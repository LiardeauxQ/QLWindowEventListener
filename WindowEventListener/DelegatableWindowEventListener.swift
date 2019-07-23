//
//  DelegatableWindowEventListener.swift
//  WindowEventListener
//
//  Created by Quentin Liardeaux on 7/23/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved.
//

import Foundation

private class DelegateInfo {
    var delegate: ApplicationBundleDelegate
    var bundleId: String
    
    init(_ delegate: ApplicationBundleDelegate, bundleId: String) {
        self.delegate = delegate
        self.bundleId = bundleId
    }
}

public class DelegatableWindowEventListener: WindowEventListener {
    private var applicationBundles: [DelegatableApplicationBundle]
    private var waitingDelegates: [DelegateInfo]
    private var registerDelegates: [DelegateInfo]

    override public init() {
        applicationBundles = []
        waitingDelegates = []
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
        updateDelegates()
        applicationBundles.forEach({ $0.raiseEvents() })
    }

    public func add(delegate: ApplicationBundleDelegate, toBundleIdentifier bundleId: String) {
        if registerDelegates.first(where: { $0.bundleId == bundleId }) != nil {
            return
        }
        
        let delegateInfo = DelegateInfo(delegate, bundleId: bundleId)
        
        registerDelegates.append(delegateInfo)
        add(info: delegateInfo)
    }
    
    private func add(info: DelegateInfo) {
        for bundle in applicationBundles {
            guard bundle.runningApp.bundleIdentifier == info.bundleId else {
                continue
            }
            bundle.delegate = info.delegate
            return
        }
        waitingDelegates.append(info)
    }
    
    public func remove(delegateWithBundleId bundleId: String) {
        guard let index = registerDelegates.firstIndex(where: { $0.bundleId == bundleId }) else {
            return
        }
        for bundle in applicationBundles {
            if bundle.runningApp.bundleIdentifier == registerDelegates[index].bundleId {
                bundle.delegate = nil
                break
            }
        }
        registerDelegates.remove(at: index)
    }
    
    private func updateDelegates() {
        var delegateBuffer: [DelegateInfo] = []
        
        for _ in 0 ..< waitingDelegates.count {
            delegateBuffer.append(waitingDelegates.removeFirst())
        }
        for info in delegateBuffer {
            add(info: info)
        }
    }
}
