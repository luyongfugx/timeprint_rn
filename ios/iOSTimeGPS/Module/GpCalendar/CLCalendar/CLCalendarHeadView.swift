//
//  CLCalendarHeadView.swift
//  Created by waynelu on 2024/12/16.
//

import SnapKit
import UIKit


class CLCalendarHeadView: UICollectionReusableView {
    static let reuseIdentifier = "CLCalendarHeadView"

    private(set) lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.backgroundColor = .clear
        
        view.textColor = UIColor.fromHex("#333333")
        //view.font = .boldPingFangSC(14)
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


private extension CLCalendarHeadView {
    func configUI() {
        addSubview(titleLabel)
    }

    func makeConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
