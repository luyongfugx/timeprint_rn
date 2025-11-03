//
//  CircularCharacterView.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2025/6/24.
//

import Foundation
import UIKit

class CircularCharacterView: UIView {

    private var text: String = ""
    private var characterBackgroundColor: UIColor = .blue
    private var characterBackgroundColors: [UIColor]? = nil
    private var textColor: UIColor = .white
    private var textSize: CGFloat = 12.0
    private let circlePadding: CGFloat = 1.0
    private let circleSpacing: CGFloat = 2.0

    private let textAttributes: [NSAttributedString.Key: Any] = [:]

    // MARK: - Public API

    func setText(_ text: String) {
        self.text = text.replacingOccurrences(of: "⃣️", with: "").replacingOccurrences(of:" ", with: "")
        setNeedsDisplay()
        invalidateIntrinsicContentSize()
    }

    func setCharacterBackgroundColor(_ color: UIColor) {
        self.characterBackgroundColor = color
        self.characterBackgroundColors = nil
        setNeedsDisplay()
    }

    func setCharacterBackgroundColors(_ colors: [UIColor]) {
        self.characterBackgroundColors = colors
        setNeedsDisplay()
    }

    func setTextColor(_ color: UIColor) {
        self.textColor = color
        setNeedsDisplay()
    }

    func setTextSize(sp: CGFloat) {
        self.textSize = sp
        setNeedsDisplay()
        invalidateIntrinsicContentSize()
    }

    // MARK: - Size Calculation

    private func calculateRadius() -> CGFloat {
        let padding = circlePadding * UIScreen.main.scale
        let font = UIFont.systemFont(ofSize: textSize)
        let textHeight = font.lineHeight
        return max(textSize, textHeight) / 2 + padding
    }

     func calculateDesiredWidth() -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let radius = calculateRadius()
        let diameter = radius * 2
        let characterSpace = diameter + circleSpacing
        return CGFloat(text.count) * characterSpace
    }

     func calculateDesiredHeight() -> CGFloat {
        return calculateRadius() * 2
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: calculateDesiredWidth(), height: calculateDesiredHeight())
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard !text.isEmpty else { return }

        let radius = calculateRadius()
        let diameter = radius * 2
        let characterSpace = diameter + circleSpacing
       // let startX = (bounds.width - CGFloat(text.count) * characterSpace + circleSpacing) / 2 + radius
        let startX = radius
        let centerY = bounds.height / 2

        let font = UIFont.systemFont(ofSize: textSize)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        for (index, char) in text.enumerated() {
            let centerX = startX + CGFloat(index) * characterSpace
            let circleColor = characterBackgroundColors?[safe: index] ?? characterBackgroundColor

            // Draw circle
            let circlePath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY),
                                          radius: radius,
                                          startAngle: 0,
                                          endAngle: CGFloat.pi * 2,
                                          clockwise: true)
            circleColor.setFill()
            circlePath.fill()

            // Draw text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraph
            ]

            let charString = String(char)
            let size = charString.size(withAttributes: attributes)
            let textY = centerY - size.height / 2
            charString.draw(at: CGPoint(x: centerX - size.width / 2, y: textY), withAttributes: attributes)
        }
    }
}
