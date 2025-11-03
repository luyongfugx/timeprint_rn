//
//  EditWatermarkVC.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/9/10.
//

import Foundation
import UIKit

let editWatermarkHeightRate: CGFloat = 0.6

typealias GPWatermarkEditCallback = (_ resultModel: BaseWatermarkModel, _ isModify: Bool, _ wmView: BaseWatermark) -> ()

// 编辑水印页面类型
enum EditWatermarkType {
    case edit
    case quickEdit
    case list
}

class EditWatermarkVC: UIViewController {
    
    @GPPersistance(key: "com.gpscamera.editWatermark.hasShowColorRedPoint", defaultValue: false)
    static var hasShowColorRedPoint: Bool
    
    // 水印列表的存储里的版本
    @GPPersistance(key: "com.gpscamera.key.watermarkCoverVer", defaultValue: 0)
    static var watermarkCoverVer: Int
    //当前水印截图版本，会拿这个跟watermarkVer 做比较，如果curwatermarkVer>watermarkVer,删除cover图片，让重新生成
    //需要更新cover图的时候，只需要增加这个curwatermarkVer就行
    var curWatermarkCoverVer = 7
    
    var startBottomViewY: CGFloat = 0
    var originWatermarkFrame = CGRect.zero
    var currentWatermarkView: BaseWatermark?
    var editThemeView: EditThemeView?
    var watermarkModel: BaseWatermarkModel?
    var complete: GPWatermarkEditCallback?
    var editViewHeight: CGFloat = 0
    var items: [WatermarkItem] {
        get {
            if editType == .quickEdit {
                return (watermarkModel?.items ?? []).filter({ !$0.idType.isBasicType() })
            } else {
                return watermarkModel?.items ?? []
            }
        }
    }
    
    // 水印列表
    var watermarkTemplateList: [WatermarkCoverModel] = []
    
    var _editType: EditWatermarkType = .edit
    
    var editType: EditWatermarkType = .edit {
        didSet {
            if editType == .edit || editType == .quickEdit {
                clickEditStamp()
            } else {
                clickChooseStamp()
            }
        }
    }
    
    var needAddCustom: Bool {
        get {
            return ![.ID9, .ID14].contains(watermarkModel?.baseID)
        }
    }

    weak var editLogoVC: GPEditLogoVC?
    var backgroundView: UIView = {
        let view = UIView(backgroundColor: .clear)
        view.isUserInteractionEnabled = true
        return view
    }()
    
    var contentView: UIView = {
        let view = UIView(backgroundColor: UIColor.white)
        return view
    }()
    
    var editWatermarkContentView: UIView = {
        let view = UIView(backgroundColor: UIColor.white)
        return view
    }()
    
    var watermarkListContentView: UIView = {
        let view = UIView(backgroundColor: UIColor.white)
        return view
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.tableHeaderView = UIView()
        tableView.backgroundColor = .white
        tableView.register(EditWatermarkCell.self, forCellReuseIdentifier: "EditWatermarkCell")
        tableView.register(AddWatermarkCell.self, forCellReuseIdentifier: "AddWatermarkCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 0)
        tableView.separatorColor = .table_line_color
        tableView.estimatedRowHeight = 70
        tableView.separatorStyle = .singleLine
        return tableView
    }()
        
    lazy var bottomBarView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        
        let lineView = UIView()
        view.addSubview(lineView)
        lineView.backgroundColor = .table_line_color
        lineView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        view.addSubview(colorBtn)
        
        colorBtn.snp.makeConstraints { make in
            make.top.equalTo(12)
            make.left.equalTo(16)
            make.width.equalTo(getColorBtnWidth())
            make.height.equalTo(44)
        }
        
        view.addSubview(doneBtn)
        doneBtn.snp.makeConstraints { make in
            make.top.equalTo(12)
            make.left.equalTo(colorBtn.snp.right).offset(12)
            make.right.equalTo(-16)
            make.height.equalTo(44)
        }
        return view
    }()
    
    lazy var eidtStampButton: AutoResizeButton = {
        let btn = AutoResizeButton(8)
        btn.setTitle("i_edit_stamp".localized(), for: .normal)
        btn.setTitleColor(UIColor.text_black_color, for: .normal)
        btn.titleLabel?.font = UIFont.Medium(20)
        btn.addTarget(self, action: #selector(clickEditStamp), for: .touchUpInside)
        return btn
    }()
    
    lazy var chooseStampButton: AutoResizeButton = {
        let btn = AutoResizeButton(8)
        btn.setTitle("i_choose_stamp".localized(), for: .normal)
        btn.setTitleColor(UIColor.text_grey_color, for: .normal)
        btn.titleLabel?.font = UIFont.Medium(17)
        btn.addTarget(self, action: #selector(clickChooseStamp), for: .touchUpInside)
        return btn
    }()
        
    lazy var topBarView: UIView = {
        let topBar = UIView(backgroundColor: UIColor.fromHex("#FAFAFA"))
        topBar.setBezierCornerRadius(position: [.topLeft, .topRight], cornerRadius: 8, roundedRect: CGRect(x: 0, y: 0, width: GPApp.screenWidth, height: 60))
        
        topBar.addSubview(eidtStampButton)
        eidtStampButton.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
        }
        
        topBar.addSubview(chooseStampButton)
        chooseStampButton.snp.makeConstraints { make in
            make.left.equalTo(eidtStampButton.snp.right).offset(2)
            make.centerY.equalToSuperview()
        }
        
        let closeBtn = GPButton(frame: .zero, fontSize: 22, iconType: .btn_close)
        closeBtn.setTitleColor(.black, for: .normal)
        closeBtn.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        topBar.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        return topBar
    }()
    
    private lazy var doneBtn: GPButton = {
        let button = GPButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .button_blue
        button.layer.cornerRadius = 8
        button.setTitle("i_finish".localized(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
        return button
    }()
    
    private lazy var colorBtn: GPButton = {
        let button = GPButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.setBorder(color: .border_medium, width: 1)
        button.layer.cornerRadius = 8
        button.setTitle("k_color_size".localized(), for: .normal)
        button.setTitleColor(.text_black_color, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.titleEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 8)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.addTarget(self, action: #selector(colorAction), for: .touchUpInside)
        return button
    }()
    
    lazy var wmListView: WatermarkListView = {
        let view = WatermarkListView()
        return view
    }()
    
    @discardableResult
    class func showEditVC(editType: EditWatermarkType, model: BaseWatermarkModel, wmView: BaseWatermark, complete: GPWatermarkEditCallback?) -> EditWatermarkVC {
        let vc = EditWatermarkVC()
        vc.watermarkModel = model
        vc.originWatermarkFrame = wmView.frame
        vc.currentWatermarkView = wmView
        vc.complete = complete
        vc._editType = editType
        
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .overCurrentContext //.overFullScreen
        GPApp.topViewController?.present(nav, animated: true, completion: nil)
        
        return vc
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        buildViews()
        self.editType = _editType
        if _editType == .quickEdit {
            // 快捷编辑时，修改标题
            eidtStampButton.setTitle("i_edit_note".localized(), for: .normal)
            chooseStampButton.isHidden = true
        }
        if !EditWatermarkVC.hasShowColorRedPoint {
            let colorWidth = getColorBtnWidth()
            colorBtn.showRedDot(isShow: true, point: .init(x: colorWidth - 16, y: 5))
        }
    }
    
    func buildViews() {
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        backgroundView.addTapGestureRecognizer(target: self, action: #selector(clickBG))
        navigationController?.view.backgroundColor = UIColor.clear
        view.backgroundColor = UIColor.clear

        view.addSubview(contentView)
        let startY = 0.4*GPApp.screenHeight
        editViewHeight = GPApp.screenHeight - startY
        contentView.snp.makeConstraints { make in
            make.top.equalTo(startY)
            make.left.right.bottom.equalToSuperview()
        }
        
        contentView.setBezierCornerRadius(position: [.topLeft, .topRight], cornerRadius: 8, roundedRect: CGRect(x: 0, y: 0, width: GPApp.screenWidth, height: GPApp.screenHeight * 0.6))
        
        contentView.addSubview(topBarView)
        topBarView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(60)
        }
        
        contentView.addSubview(watermarkListContentView)
        watermarkListContentView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(topBarView.snp.bottom)
        }
        
        contentView.addSubview(editWatermarkContentView)
        editWatermarkContentView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(topBarView.snp.bottom)
        }
        
        editWatermarkContentView.addSubview(bottomBarView)
        bottomBarView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(12+44+12+GPApp.tabBarBottomHeight)
        }
        
        buildTableView()
        
        startBottomViewY = startY
        firstChooseWatermark()
    }
    
    func getColorBtnWidth() -> CGFloat {
        "k_color_size".localized().size(WithFont: .systemFont(ofSize: 16), ConstrainedToWidth: GPApp.screenWidth).width + 32
    }
    
    func firstChooseWatermark() {
        
        guard let currentWatermarkView else {
           return
        }
        
        currentWatermarkView.delegate = nil
        currentWatermarkView.removeFromSuperview()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // delay
            self.reChooseWatermark()
        }
        
    }
    
    func reloadDatas() {
        self.tableView.reloadData()
        refreshCurrentWatermark()
    }
    
    func reloadItems(_ indexPath: IndexPath) {
        self.tableView.reloadRows(at: [indexPath], with: .none)
        refreshCurrentWatermark()
    }
    
    func reChooseWatermark() {
        var frame = CGRect.init(x: 0, y: startBottomViewY, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - GPApp.statusBarAndNavigationBarHeight)

        frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: startBottomViewY)
        
        if let currentWatermarkView {
            currentWatermarkView.removeFromSuperview()
        }
        // 预览水印
        currentWatermarkView = BaseWatermark.generateWatermarkView(watermarkModel: watermarkModel!, preview: true, frame: frame)
        backgroundView.addSubview(currentWatermarkView!)
        currentWatermarkView?.updateUI()
    }
}

extension EditWatermarkVC {

    
    @objc func clickEditStamp() {
        chooseButton(eidtStampButton)
        tableView.reloadData()
        editWatermarkContentView.isHidden = false
        watermarkListContentView.isHidden = true
    }
    
    @objc func clickChooseStamp() {
        chooseButton(chooseStampButton)
        // 使用新的水印列表
        buildWatermarkListView()
        editWatermarkContentView.isHidden = true
        watermarkListContentView.isHidden = false
    }
    
    private func chooseButton(_ btn: GPButton) {
        if eidtStampButton == btn {
            eidtStampButton.setTitleColor(.text_black_color, for: .normal)
            eidtStampButton.titleLabel?.font = UIFont.Medium(20)
            chooseStampButton.setTitleColor(.text_grey_color, for: .normal)
            chooseStampButton.titleLabel?.font = UIFont.Medium(17)
        } else {
            chooseStampButton.setTitleColor(.text_black_color, for: .normal)
            chooseStampButton.titleLabel?.font = UIFont.Medium(20)
            eidtStampButton.setTitleColor(.text_grey_color, for: .normal)
            eidtStampButton.titleLabel?.font = UIFont.Medium(17)
        }
    }
    
    @objc func closeButtonAction() {
        handleComplete()
    }
    
    @objc func clickBG() {
        handleComplete()
    }
    
    @objc func doneAction() {
        handleComplete()
    }
    
    @objc func colorAction() {
        EditWatermarkVC.hasShowColorRedPoint = true
        colorBtn.showRedDot(isShow: false)
        showEditTheme()
    }
    
    func handleComplete() {
        self.currentWatermarkView?.isHidden = true
        self.navigationController?.dismiss(animated: true)
        if let complete = complete, let watermarkModel = watermarkModel, let wmView = currentWatermarkView {
            wmView.frame = originWatermarkFrame
            complete(watermarkModel, true, wmView)
        }
    }
    
    func refreshCurrentWatermark() {
        currentWatermarkView?.updateUI()
    }
}
