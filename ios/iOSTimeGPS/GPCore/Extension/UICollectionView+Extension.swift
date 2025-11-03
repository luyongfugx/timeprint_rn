//
//  UICollectionView+Extension.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/3.
//

import UIKit

// MARK: UIKit

extension UICollectionReusableView {
    static var xh_reuseIdentifier: String { "com.xhey.collectionview.element.reuseIdentifier.\(String(describing: self))" }
}

extension UICollectionView {
    func registerCell<Cell: UICollectionViewCell>(_ cellType: Cell.Type) {
        register(cellType, forCellWithReuseIdentifier: cellType.xh_reuseIdentifier)
    }

    func dequeueCell<Cell: UICollectionViewCell>(_ cellType: Cell.Type, for indexPath: IndexPath) -> Cell {
        guard let cell = dequeueReusableCell(withReuseIdentifier: cellType.xh_reuseIdentifier, for: indexPath) as? Cell else {
            fatalError("未注册")
        }
        return cell
    }

    func registerHeader<Header: UICollectionReusableView>(_ header: Header.Type) {
        register(header, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: header.xh_reuseIdentifier)
    }

    func dequeueHeader<Header: UICollectionReusableView>(_ header: Header.Type, for indexPath: IndexPath) -> Header {
        guard let header = dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: Header.xh_reuseIdentifier, for: indexPath) as? Header else {
            fatalError("header 未注册")
        }
        return header
    }

    // MARK: -

    /// 添加`elementKindSectionFooter`快捷注册方式
    /// - Authors: 周宏辉
    /// - Date: 2022-01-07
    /// - Version: 2.9.225
    func registerFooter<Footer: UICollectionReusableView>(_ footer: Footer.Type) {
        register(footer, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: footer.xh_reuseIdentifier)
    }

    func dequeueFooter<Footer: UICollectionReusableView>(_ footer: Footer.Type, for indexPath: IndexPath) -> Footer {
        guard let footer = dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: Footer.xh_reuseIdentifier, for: indexPath) as? Footer else {
            fatalError("footer 未注册")
        }
        return footer
    }
}

extension CGFloat {
    var fromPixel: CGFloat { self / UIScreen.main.scale }
    var toPixel: CGFloat { self * UIScreen.main.scale }
}

extension Int {
    var fromPixel: CGFloat { CGFloat(self).fromPixel }
    var toPixel: CGFloat { CGFloat(self).toPixel }
}

extension Double {
    var fromPixel: CGFloat { CGFloat(self).fromPixel }
    var toPixel: CGFloat { CGFloat(self).toPixel }
}


extension UICollectionView {
    func scrollToBottom(animated: Bool) {
        let contentSize = self.contentSize
        let boundsSize = self.frame.size
        guard contentSize.height > boundsSize.height else { return }
        let delta = contentSize.height - boundsSize.height
        setContentOffset(.init(x: contentOffset.x, y: delta), animated: animated)
    }
}

extension Array {
    /// 将一个数组按给定的宽度`count`进行分组
    /// 示例代码：
    ///
    ///     let source: [Int] = Array(repeating: 1, count: Int.random(in: 0...100)).map { $0 }
    ///     let count: Int = 4
    ///     let separatedList = source.seperate(by: count)
    ///     ...
    ///
    /// - Parameter count: 数量，如果`<=0`，则返回`[self]`
    /// - Returns: 分组好的数据，例如`[[1, 2], [11, 2], [1]]`
    func seperate(by count: Int) -> [[Element]] {
        if count <= 0 {
            return [self]
        }

        var result = [[Element]]()

        var tempCache = [Element]()
        for element in self {
            tempCache.append(element)
            if tempCache.count == count {
                result.append(tempCache)
                tempCache = []
            }
        }

        if !tempCache.isEmpty {
            result.append(tempCache)
        }
        return result
    }
}
