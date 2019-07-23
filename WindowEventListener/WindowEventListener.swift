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
