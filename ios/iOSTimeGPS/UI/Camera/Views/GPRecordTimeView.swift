//
//  GPRecordTimeView.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/19.
//

import Foundation
import UIKit
import SnapKit

class GPRecordTimeView: UIView {
    
    var label: UILabel?
    var more60sTiplabel: UILabel?
    var timer: Timer?
    var currentInterval: Double = 0
    let repeatDuration: Double = 0.5
    let dataFormat: DateFormatter
    var cornerRadius:CGFloat = 8
    var ellipseColor: UIColor = UIColor.white
    
    // 大于一个小时的回调，大于60分钟的时候停止录制
    var moreThanAnHourHandler: (() -> ())?
    // 大于50s，小于60s的回调
    var moreThan50sHandler: (() -> ())?
    
    // 视频最大长度
    let videoMaxlength: Double = 60*60

    override init(frame: CGRect) {
        dataFormat = DateFormatter.dateFormat_xh()
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        dataFormat = DateFormatter.dateFormat_xh()
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        
        self.backgroundColor = UIColor.UIColorFromRGBA(0, g: 0, b: 0, a: 0.35)
        label = UILabel()
        label?.backgroundColor = UIColor.clear
        label?.font = UIFont.boldSystemFont(ofSize: 18)
        label?.textColor = UIColor.white
        label?.textAlignment = .center
        label?.text = "0:00"
        addSubview(label!)
        label?.snp.makeConstraints({ (maker) in
            maker.edges.equalTo(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        })
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        
        more60sTiplabel = UILabel()
        more60sTiplabel?.backgroundColor = UIColor.clear
        more60sTiplabel?.font = UIFont.Semibold(14)
        more60sTiplabel?.textColor = UIColor.white
        more60sTiplabel?.textAlignment = .center
        more60sTiplabel?.text = "超过20分钟，将无法同步"
        more60sTiplabel?.isHidden = true
        addSubview(more60sTiplabel!)
        more60sTiplabel?.snp.makeConstraints({ (maker) in
            maker.width.equalTo(180)
            maker.bottom.equalTo(0)
            maker.height.equalTo(30)
            maker.centerX.equalToSuperview()
        })
        
    }
    func updateTime(progress:Double) {
        currentInterval = progress
    }
    @objc private func updateTimer(_ timer: Timer) {
//        currentInterval += repeatDuration
        
        label?.snp.makeConstraints({ (maker) in
            maker.edges.equalTo(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        })
        
        if currentInterval < 60{
            if self.width != 60 {
                self.width = 60
                self.centerX = GPApp.screenWidth * 0.5
            }
            if currentInterval < 10{
                label?.text = "0:0\(Int(currentInterval))"
            }else{
                label?.text = "0:\(Int(currentInterval))"
            }
            
        }else if currentInterval < 3600{
            var minuteStr = ""
            var secondsStr = ""
            let minute = Int(currentInterval/60)
            let seconds = Int(currentInterval) - minute*60
            if minute < 10{
                minuteStr = "0\(minute)"
            }else{
                minuteStr = "\(minute)"
            }
            if seconds < 10{
                secondsStr = "0\(seconds)"
            }else{
                secondsStr = "\(seconds)"
            }
            if self.width != 70 {
                self.width = 70
            }
            label?.text = "\(minuteStr):\(secondsStr)"
        }else{
            var minuteStr = ""
            var secondsStr = ""
            let hour = Int(currentInterval/3600)
            let minute = Int(Int(currentInterval) - hour * 3600)/60
            let seconds = Int(currentInterval) - minute * 60 - hour * 3600
            if minute < 10{
                minuteStr = "0\(minute)"
            }else{
                minuteStr = "\(minute)"
            }
            if seconds < 10{
                secondsStr = "0\(seconds)"
            }else{
                secondsStr = "\(seconds)"
            }
            if self.width != 90 {
                self.width = 90
            }
            label?.text = "\(hour):\(minuteStr):\(secondsStr)"
        }
        
        self.centerX = GPApp.screenWidth * 0.5

        
        // XHLogDebug("[视频录制调试] - 视频录制的时长:[\(currentInterval)]")
        
        if let handler = self.moreThanAnHourHandler, currentInterval >= videoMaxlength {
            self.stop()
            handler()
        }
        if let handler = self.moreThan50sHandler {
            handler()
        }
        
    }
    
    func start() {
        reset()
        timer?.invalidate()
        timer = Timer(timeInterval: repeatDuration, target: self, selector: #selector(updateTimer(_:)), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
    }
    func pause() {
//        timer?.invalidate()
//        timer = nil
    }
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    func resume() {
//        currentInterval = currentInterval+repeatDuration
//        timer?.invalidate()
//        timer = Timer(timeInterval: repeatDuration, target: self, selector: #selector(updateTimer(_:)), userInfo: nil, repeats: true)
//        RunLoop.current.add(timer!, forMode: RunLoop.Mode.common)
    }
    
    func reset() {
        currentInterval = 0
        dataFormat.dateFormat = "m:ss"
        label?.text = "0:00"
    }
}

