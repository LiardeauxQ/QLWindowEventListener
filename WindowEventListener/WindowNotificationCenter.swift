//
//  WindowNotificationCenter.swift
//  WindowWatcher
//
//  Created by Quentin Liardeaux on 7/22/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved.
//

import Foundation

public protocol Subscriber {
    func notify(_ userInfo: [String: Any]?)
}

public protocol Publisher {
    var notificationCenter: WindowNotificationCenter? { get }
}

public struct TopicIdentifier: Equatable {
    var id: String
    var subid: String?
    
    init(id: String, subid: String? = nil) {
        self.id = id
        self.subid = subid
    }
}

private struct Topic {
    var identifier: TopicIdentifier
    var subscribers: [Subscriber]

    func notifyAll(_ userInfo: [String: Any]?) {
        subscribers.forEach({ $0.notify(userInfo) })
    }
}

public class WindowNotificationCenter {
    public static var shared = WindowNotificationCenter()
    private var topics = [Topic]()

    public func subscribe(_ sub: Subscriber, toTopic topic: TopicIdentifier) {
        guard let index = topics.firstIndex(where: { $0.identifier == topic }) else {
            topics.append(Topic(identifier: topic, subscribers: [sub]))
            return
        }
        topics[index].subscribers.append(sub)
    }

    public func notify(topic: TopicIdentifier, userInfo: [String: Any]? = nil) {
        if let hardIndex = topics.firstIndex(where: { $0.identifier == topic }) {
            topics[hardIndex].notifyAll(userInfo)
            return
        }
        for value in topics {
            if value.identifier.id == topic.id {
                value.notifyAll(userInfo)
            }
        }
    }
}
