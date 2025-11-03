//
//  CLCalendarSectionBackgroundView.swift
//
//  Created by waynelu on 2024/12/16.
//
import SnapKit
import UIKit

class CLCalendarSectionBackgroundView: UICollectionReusableView {
    static let reuseIdentifier = "CLCalendarSectionBackgroundView"

    private lazy var textLabel: UILabel = {
        let view = UILabel()
        view.backgroundColor = .clear
        //6view.font = .boldPingFangSC(80)
        view.textAlignment = .center
        view.isUserInteractionEnabled = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
        makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
} 

private extension CLCalendarSectionBackgroundView {
    func configUI() {
        isUserInteractionEnabled = false
        addSubview(textLabel)
    }

    func makeConstraints() {
        textLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - JmoVxia---override

extension CLCalendarSectionBackgroundView {
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let attributes = layoutAttributes as? CLCalendarLayoutAttributes else { return }
        textLabel.textColor = attributes.textColor
        textLabel.text = attributes.month
    }
}
