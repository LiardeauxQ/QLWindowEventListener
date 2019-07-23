//
//  RepeatingTimer.swift
//  WindowWatcher
//
//  Created by Quentin Liardeaux on 7/23/19.
//  Copyright © 2019 Quentin Liardeaux. All rights reserved.
//

import Foundation

class RepeatingTimer {

    private enum State {
        case suspended
        case resumed
    }

    let timeInterval: TimeInterval
    var timer: Timer?
    @objc var eventHandler: (() -> Void)?
    private var state: State = .suspended

    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }

    private func initTimer() {
        DispatchQueue.global(qos: .background).async {
            let runLoop = RunLoop.current

            self.timer = Timer.scheduledTimer(timeInterval: self.timeInterval, target: self,
                                              selector: #selector(self.sendEvent), userInfo: nil, repeats: true)
            runLoop.add(self.timer!, forMode: .default)
            runLoop.run()
         }
    }

    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        initTimer()
    }

    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer?.invalidate()
        timer = nil
    }

    @objc private func sendEvent() {
        eventHandler?()
    }

    deinit {
        timer?.invalidate()
        eventHandler = nil
    }
}
