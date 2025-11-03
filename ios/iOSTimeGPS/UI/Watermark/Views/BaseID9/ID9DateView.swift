//
//  ID9DateView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/12/14.
//

import Foundation

class ID9DateView: GPContentView {

    var imgList: [UIImageView] = []
    let numImgDic: [Int: String] = [-1: "clock_point",
                                     0: "clock_0",
                                     1: "clock_1",
                                     2: "clock_2",
                                     3: "clock_3",
                                     4: "clock_4",
                                     5: "clock_5",
                                     6: "clock_6",
                                     7: "clock_7",
                                     8: "clock_8",
                                     9: "clock_9"]
    
    override func buildUI() {
        super.buildUI()
        for _ in 0...9 {
            let imgV = UIImageView()
            imgV.contentMode = .scaleAspectFit
            addSubview(imgV)
            imgList.append(imgV)
        }
    }
    
    func updateDate(dataList: [Int]) {
        var startX = 0.0
        let padding = 2.0
        let numImgW = 43/4.0
        let imgH = 62/4.0
        let dotImgW = 13/4.0
        var viewW = 0.0
        for (index, item) in dataList.enumerated() {
            if item > -2 && item < 10 && index < 10 {
                let imgV = imgList[index]
                imgV.image = UIImage(named: numImgDic[item] ?? "")
                let imgW = (item == -1) ? dotImgW : numImgW
                imgV.frame = .init(x: startX, y: 0, width: imgW, height: imgH)
                startX = startX + padding + imgW
            }
        }
        self.width = startX
        self.height = imgH
    }
}

