//
//  PublishableWindowEventListener.swift
//  WindowEventListener
//
//  Created by Quentin Liardeaux on 7/23/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved.
//

import Foundation

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
