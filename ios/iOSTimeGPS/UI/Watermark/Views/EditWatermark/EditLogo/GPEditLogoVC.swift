//
//  GPEditLogoVC.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/6.
//

import Foundation
import UIKit

class GPEditLogoVC: GPHalfBaseVC {
    
    lazy var replaceButton: GPButton = {
        let button = GPButton()
        button.backgroundColor = .white
        button.setTitle("k_replace".localized(), for: .normal)
        button.setTitleColor(.text_black_color, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(didClickReplace), for: .touchUpInside)
        return button
    }()
    
    lazy var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        view.alwaysBounceHorizontal = false
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            view.contentInsetAdjustmentBehavior = .never
        }
        return view
    }()
    
    let positionLabel: UILabel = {
        return UILabel(text: "k_logo_position_title".localized(), textColor: UIColor.fromHex("222222"), textFont: UIFont.Semibold(18))
    }()
    
    let postionView: GPEditLogoPositionView = {
        let postionV = GPEditLogoPositionView(frame: .zero)
        return postionV
    }()
    
    let bgLabel: UILabel = {
        return UILabel(text: "k_background".localized(), textColor: UIColor.fromHex("222222"), textFont: UIFont.Semibold(18))
    }()
    
    
    
    let removeBgView:GPRemoveBgView = {
        let rgView = GPRemoveBgView(frame: .zero)
        return rgView
    }()
    
    
    
    let sizeLabel: UILabel = {
        return UILabel(text: "k_logo_size_title".localized(), textColor: UIColor.fromHex("222222"), textFont: UIFont.Semibold(18))
    }()
    
    let sizeSliderView: GPSizeSliderBar = {
        return GPSizeSliderBar(frame: .zero)
    }()
    
    let alphaLabel: UILabel = {
        return UILabel(text: "k_logo_alpha_title".localized(), textColor: UIColor.fromHex("222222"), textFont: UIFont.Semibold(18))
    }()
    
    let alphaSliderView: GPSizeSliderBar = {
        return GPSizeSliderBar(frame: .zero)
    }()

    
    lazy var containerView = UIView()
    
    private var viewHeight: CGFloat = 0
    override var preferredContentSize: CGSize {
        
        get { .init(width: view.bounds.width, height: editWatermarkHeightRate * GPApp.screenHeight) }
        set {}
    }
    var complete: ((WatermarkLogoItem) -> Void)?
    var replaceAction: (() -> Void)?
    var logoItem: WatermarkLogoItem?
    
    init(logoItem: WatermarkLogoItem, complete: ((WatermarkLogoItem) -> Void)?, replaceAction: (() -> Void)?) {
        self.logoItem = logoItem
        self.complete = complete
        self.replaceAction = replaceAction
        self.viewHeight = editWatermarkHeightRate * GPApp.screenHeight
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        bgColor = .clear
        vcTitle = "k_edit_logo".localized()
        buildViews()
    }
    
    func handleComplate() {
        guard let logoItem else { return }
  
        complete?(logoItem)
    }
    
}

