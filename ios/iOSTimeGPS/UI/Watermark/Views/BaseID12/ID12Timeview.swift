//
//  ID12Timeview.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2025/2/26.
//

import Foundation


class ID12TimeView: GPContentView {

    var imgList: [UIImageView] = []
    let numImgDic: [Int: String] = [-1: "grey_colon",
                                     0: "grey_0",
                                     1: "grey_1",
                                     2: "grey_2",
                                     3: "grey_3",
                                     4: "grey_4",
                                     5: "grey_5",
                                     6: "grey_6",
                                     7: "grey_7",
                                     8: "grey_8",
                                     9: "grey_9"]
        
    override func buildUI() {
        super.buildUI()
        for _ in 0...4 {
            let imgV = UIImageView()
            imgV.contentMode = .scaleAspectFit
            addSubview(imgV)
            imgList.append(imgV)
        }
    }
    
    func updateDate(dataList: [Int], textColor: UIColor, rate: CGFloat = 3.4) {
        var startX = 0.0
        let padding = 4.0
        let numImgW = 48/rate
        let imgH = 81/rate
        let dotImgW = 18/rate
        for (index, item) in dataList.enumerated() {
            if item > -2 && item < 10 && index < 10 {
                let imgV = imgList[index]
                imgV.image = UIImage(named: numImgDic[item] ?? "")?.withTintColor(textColor)
                let imgW = (item == -1) ? dotImgW : numImgW
                imgV.frame = .init(x: startX, y: 0, width: imgW, height: imgH)
                startX = startX + padding + imgW
            }
        }
        self.width = startX
        self.height = imgH
    }
}
