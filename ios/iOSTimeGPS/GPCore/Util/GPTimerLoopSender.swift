//
//  GPTimerLoopSender.swift
//  XCamera
//
//  Copyright © 2018 xhey. All rights reserved.
//

import UIKit

class GPTimerLoopSender: NSObject {

    private var currentTime:TimeInterval = 0
    private var xhey_internal:TimeInterval = 0.03
    
    private var timer:Timer?
    
    typealias callBack = (_ count:Int,_ interval:Double)->()
    var timerloopCallBack: callBack?
    var count = 0
    init(interval:Double) {
        super.init()
        xhey_internal = interval
        timer = Timer.init(fire: Date(), interval: xhey_internal, repeats: true, block: { [weak self](timer) in
            if let wSelf = self,let timerloopCallBack = self?.timerloopCallBack{
                wSelf.currentTime  = wSelf.currentTime + wSelf.xhey_internal
                let num = Int(wSelf.currentTime / wSelf.xhey_internal)
                wSelf.count = num
                timerloopCallBack(num,wSelf.xhey_internal)
            }

        })
        if let timer = timer{
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        }
        
    }
    func stop(){
        if let tempTimer = self.timer {
            tempTimer.fireDate = .distantFuture
        }
    }
    func start(){
        if let tempTimer = self.timer {
            tempTimer.fireDate = Date()
            tempTimer.fire()
        }
    }
}
