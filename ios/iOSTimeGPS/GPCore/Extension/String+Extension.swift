//
//  String+Extension.swift
//  XCamera
//
//  Copyright © 2021 xhey. All rights reserved.
//

import Foundation
import UIKit

func isNotEmpty<T: Collection>(_ collection: T?) -> Bool {
    guard let collection else { return false }
    return !collection.isEmpty
}

func isNotEmpty<T: Collection>(_ collection: T) -> Bool {
    return !collection.isEmpty
}

func timeDifferenceInSeconds(startTime: String, endTime: String, timeFormat: String = "yyyy-MM-dd HH:mm:ss.SSS") -> TimeInterval? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = timeFormat
    guard let startDate = dateFormatter.date(from: startTime),
          let endDate = dateFormatter.date(from: endTime) else {
        return nil
    }
    let timeInterval = endDate.timeIntervalSince(startDate)
    return timeInterval
}


public extension String {
    
    func nsRange(from range: Range<String.Index>) -> NSRange? {
        let utf16view = self.utf16
        if let from = range.lowerBound.samePosition(in: utf16view), let to = range.upperBound.samePosition(in: utf16view) {
            return NSMakeRange(utf16view.distance(from: utf16view.startIndex, to: from), utf16view.distance(from: from, to: to))
        }
        return nil
    }
    
    /// 从String中截取出参数
    var urlParameters2: [String: Any]? {
        // 截取是否有参数
        guard let urlComponents = NSURLComponents(string: self), let queryItems = urlComponents.queryItems else {
            return nil
        }
        // 参数字典
        var parameters = [String: Any]()
        
        for item in queryItems {
            if let stringValue = item.value, stringValue.count > 0 {
                if let boolValue = Bool(stringValue) {
                    parameters[item.name] = boolValue
                } else {
                    parameters[item.name] = stringValue
                }
            }
        }
        return parameters
    }
    
    /// 去掉首尾空格
    var removeHeadAndTailSpace:String {
        let whitespace = NSCharacterSet.whitespaces
        return self.trimmingCharacters(in: whitespace)
    }
    
    /// 去掉首尾空格 包括后面的换行 \n
    var removeHeadAndTailSpacePro: String {
        let whitespace = NSCharacterSet.whitespacesAndNewlines
        return self.trimmingCharacters(in: whitespace)
    }
    
    /// 从字符串获取url
    var url: URL? { .init(string: self) }
    
    /// 去掉所有空格
    var removeAllSpaces: String {
        return self.replacingOccurrences(of: " ", with: "", options: .literal, range: nil)
    }
    
    /// 判断是否包含文件名不支持的特殊符号
    var containsInvalidChars: Bool {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        return self.rangeOfCharacter(from: invalidCharacters) != nil
    }
    
    /// 判断是否包含换行符
    var containsNewline: Bool {
        contains { $0.isNewline }
    }
    
    /// 去掉首尾空格 后 指定开头空格数
    func beginSpaceNum(num: Int) -> String {
        var beginSpace = ""
        for _ in 0..<num {
            beginSpace += " "
        }
        return beginSpace + self.removeHeadAndTailSpacePro
    }

    func urlEncode() -> String {
        let mstring = self.replacingOccurrences(of: " ", with: "+")

        // 这个集合中的字符会被转移成百分号
        let set = CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]{}").inverted
        return mstring.addingPercentEncoding(withAllowedCharacters: set) ?? ""
    }
    
    /// 对字符串进行base64编码
    func encodebase64String() -> String {
        return self.data(using: .utf8)?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) ?? ""
    }
    
    /// 计算字符串中，汉字的数量
    func chineseCount() -> Int {
        var count = 0
        for c in self where ("\u{4E00}" <= c  && c <= "\u{9FA5}") {
            count += 1
        }
        return count
    }
    
    // 是否包含数字
    func containsNumber() -> Bool {
        let range = NSRange(location: 0, length: self.utf16.count)
        let regex = try! NSRegularExpression(pattern: #"\d"#)
        return regex.firstMatch(in: self, options: [], range: range) != nil
    }
}

extension String {

    func addBlank_fix(per: Int = 1) -> String {
        var newString = self
        guard !self.isEmpty else { return newString }
        let spaceCount = Int(count / per)
        for i in 1 ..< spaceCount {
            newString.insert(contentsOf: " ", at: newString.index(newString.startIndex, offsetBy: per * i + i - 1))
        }
        return newString
    }
}

extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    // 适配iOS16，需要加上Swift.Range，否则报错specialize non-generic type 'Range'
    func substring(with r: Swift.Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
}

extension String {
    
    // V2.0.55: 计算有行间距的Label高度
    func boundingRect(with constrainedSize: CGSize, font: UIFont, lineSpacing: CGFloat? = nil) -> CGSize {
        let attritube = NSMutableAttributedString(string: self)
        let range = NSRange(location: 0, length: attritube.length)
        attritube.addAttributes([NSAttributedString.Key.font: font], range: range)
        if lineSpacing != nil {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing!
            attritube.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)
        }
        
        let rect = attritube.boundingRect(with: constrainedSize, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        var size = rect.size
        
        if let currentLineSpacing = lineSpacing {
            // 文本的高度减去字体高度小于等于行间距，判断为当前只有1行
            let spacing = size.height - font.lineHeight
            if spacing <= currentLineSpacing && spacing > 0 {
                size = CGSize(width: size.width, height: font.lineHeight)
            }
        }
        
        return size
    }
    
    // V2.0.55: 计算有行间距、有行数限制的Label高度
    func boundingRect(with constrainedSize: CGSize, font: UIFont, lineSpacing: CGFloat? = nil, lines: Int) -> CGSize {
        if lines < 0 {
            return .zero
        }
        
        let size = boundingRect(with: constrainedSize, font: font, lineSpacing: lineSpacing)
        if lines == 0 {
            return size
        }
        
        let currentLineSpacing = (lineSpacing == nil) ? (font.lineHeight - font.pointSize) : lineSpacing!
        let maximumHeight = font.lineHeight*CGFloat(lines) + currentLineSpacing*CGFloat(lines - 1)
        if size.height >= maximumHeight {
            return CGSize(width: size.width, height: maximumHeight)
        }
        
        return size
    }

}

extension String {
    /// 指定关键词高亮
    /// - Parameter keyWords: 关键词
    /// - Parameter color: 高亮颜色
    func highlight(keyWords: String?, highlightColor color: UIColor) -> NSAttributedString {
        let string: String = self
        let attributeString = NSMutableAttributedString(string: string)
        guard let keyWords = keyWords else { return attributeString }
        let attribute: [NSAttributedString.Key: Any] = [.foregroundColor: color]
        // 需要改变的文本
        let ranges = ranges(of: keyWords, options: .caseInsensitive)
        for range in ranges where range.location + range.length <= string.count {
            attributeString.addAttributes(attribute, range: range)
        }
        return attributeString
    }
    
    /// 查找字符串中子字符串的NSRange
    /// - Parameters:
    ///   - substring: 子字符串
    ///   - options: 匹配选项
    ///   - locale: 本地化
    /// - Returns: 子字符串的NSRange数组
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [NSRange] {
        var ranges: [Range<Index>] = []
        while let range = range(of: substring, options: options, range: (ranges.last?.upperBound ?? self.startIndex)..<self.endIndex, locale: locale) {
            ranges.append(range)
        }
        // [range]转换为[NSRange]返回
        return ranges.compactMap({NSRange($0, in: self)})
    }
    
    /// range转换为NSRange
    func toNSRange(from range: Range<String.Index>) -> NSRange {
        return NSRange(range, in: self)
    }
}

extension String {
    var containEmoji: Bool {
        
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
            0x1F300...0x1F5FF, // Misc Symbols and Pictographs
            0x1F680...0x1F6FF, // Transport and Map
            0x1F1E6...0x1F1FF, // Regional country flags
            0x2600...0x26FF, // Misc symbols
            0x2700...0x27BF, // Dingbats
            0xE0020...0xE007F, // Tags
            0xFE00...0xFE0F, // Variation Selectors
            0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
            127000...127600, // Various asian characters
            65024...65039, // Variation selector
            9100...9300, // Misc items
            8400...8447: // Combining Diacritical Marks for Symbols
                return true
            default:
                continue
            }
        }
        return false
    }
    static func processEmojiCode(_ string: String) -> String {
        var result = ""
        var currentIndex = string.startIndex
        
        while currentIndex < string.endIndex {
            if string[currentIndex] == "{" {
                // 找到左括号，尝试找到右括号
                if let endIndex = string[currentIndex...].firstIndex(of: "}") {
                    // 提取大括号内的内容
                    let unicodeString = String(string[string.index(after: currentIndex)..<endIndex])
                    // 将大括号内的内容转换为对应的Unicode字符
                    if let unicodeValue = Int(unicodeString, radix: 16),
                       let scalar = Unicode.Scalar(unicodeValue)
                    {
                        result.append(Character(scalar))
                    }
                    // 移动当前索引到右括号之后
                    currentIndex = string.index(after: endIndex)
                } else {
                    // 如果没有右括号，直接追加左括号
                    result.append(string[currentIndex])
                    currentIndex = string.index(after: currentIndex)
                }
            } else {
                // 非大括号内容直接追加
                result.append(string[currentIndex])
                currentIndex = string.index(after: currentIndex)
            }
        }
        return result
    }
}

extension String {
    // 根据字符串计算宽度或高度
    func size(WithFont font: UIFont, ConstrainedToWidth width: CGFloat) -> CGSize {
        
        let size = CGSize.init(width: width, height: 99999.0)
        
        let attributes = [NSAttributedString.Key.font : font]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let rect:CGRect = self.boundingRect(with: size, options:option, attributes: attributes,context:nil)
        
        return rect.size
    }
    
    func size(WithFont font: UIFont, ConstrainedToHeight height: CGFloat) -> CGSize {
        
        let size = CGSize.init(width: 999999.0, height: height)
        let attributes = [NSAttributedString.Key.font : font]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let rect:CGRect = self.boundingRect(with: size, options:option, attributes: attributes,context:nil)
        
        return rect.size
    }
    
    // 利用UILabel计算宽度或高度
    func getStringSizeByLabel(WithFont font: UIFont, ConstrainedToWidth width: CGFloat, lineBreakMode: NSLineBreakMode = .byCharWrapping) -> CGSize {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = font
        label.lineBreakMode = lineBreakMode
        label.text = self
        label.preferredMaxLayoutWidth = width
        let contentSize = label.sizeThatFits(CGSize.init(width: width, height: CGFloat.greatestFiniteMagnitude))
        if contentSize.height < 0.5 {
           return self.size(WithFont: font, ConstrainedToWidth: width)
        }
        return contentSize
    }
    
}
