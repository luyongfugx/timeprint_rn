import UIKit
import SnapKit

struct WatermarkHistoryItem: Codable {
    let id: String
    let type: WatermarkHistoryType // title or content
    var text: String
    var date: Date
    var isFavorite: Bool = false
}

enum WatermarkHistoryType: String, Codable {
    case title
    case content
}

class WatermarkEditViewController: UIViewController {
    
    // MARK: - Properties
    private let entryId: String
    private var titleText: String
    private var contentText: String
    private var sureHandler:((String, String)->())?

    private var titleHistory: [WatermarkHistoryItem] = []
    private var contentHistory: [WatermarkHistoryItem] = []
    
    private var currentShowingHistoryType: WatermarkHistoryType = .content {
        didSet {
            if currentShowingHistoryType == .content {
                contentTextView.layer.borderColor = UIColor.systemBlue.cgColor
                titleTextView.layer.borderColor = UIColor.lightGray.cgColor
            } else {
                contentTextView.layer.borderColor = UIColor.lightGray.cgColor
                titleTextView.layer.borderColor = UIColor.systemBlue.cgColor
            }
        }
    }
    let maxTitleWidth = 100.0
    private var tableViewTopConstraint: Constraint?

    // 计算最大高度（4行高度 + 上下边距）
    private var maxTextViewHeight: CGFloat {
        let lineHeight = titleTextView.font?.lineHeight ?? 20
        return lineHeight * 4 + titleTextView.textContainerInset.top + titleTextView.textContainerInset.bottom
    }
    
    // MARK: - UI Components
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "k_title".localized()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = .gray
        return label
    }()
    
    private lazy var titleTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = .text_strong
        textView.backgroundColor = .white // 固定白色背景
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 6
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.delegate = self
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.placeholder = "k_Input".localized()
        textView.isScrollEnabled = true
        return textView
    }()
    
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.text = "k_content".localized()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = .gray
        label.textAlignment = .right
        return label
    }()
    
    private lazy var contentTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.textColor = .text_strong
        textView.backgroundColor = .white // 固定白色背景
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 6
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.delegate = self
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.placeholder = "k_please_input".localized()
        textView.isScrollEnabled = true
        return textView
    }()
    
    private lazy var clearContentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(clearContent), for: .touchUpInside)
        return button
    }()
    
    private lazy var topBGView: UIView = {
        let v = UIView()
        v.addGestureRecognizer(tapGesture)
        v.backgroundColor = .white // 固定白色背景
        return v
    }()
    
    private lazy var historyTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(HistoryCell.self, forCellReuseIdentifier: "HistoryCell")
        tableView.register(TitleHistoryCell.self, forCellReuseIdentifier: "TitleHistoryCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .white // 固定白色背景
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return tableView
    }()
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        gesture.cancelsTouchesInView = false
        return gesture
    }()
    
    // MARK: - Initialization
    init(entryId: String, title: String, content: String, sureHandler:((String, String)->())?) {
        self.entryId = entryId
        self.titleText = title
        self.contentText = content
        self.sureHandler = sureHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
        setupNotifications()
        
        // 默认选中内容输入框并弹出键盘
        contentTextView.becomeFirstResponder()
//        view.addGestureRecognizer(tapGesture)
    }
    
    private func setupUI() {
        overrideUserInterfaceStyle = .light
        view.backgroundColor = .white
        title = "k_edit_item".localized()
        
        // Add subviews
        view.addSubview(topBGView)
        view.addSubview(titleLabel)
        view.addSubview(titleTextView)
        view.addSubview(contentLabel)
        view.addSubview(contentTextView)
        view.addSubview(clearContentButton)
        view.addSubview(historyTableView)
        
        // Layout with SnapKit
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20) // 增加左边距
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel)
            make.leading.equalTo(titleTextView.snp.trailing).offset(12)
        }
        
        titleTextView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(20) // 增加左边距
            make.width.equalTo(maxTitleWidth) // 稍微增加宽度
            make.height.equalTo(36) // 初始高度增加
        }
        
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(8)
            make.leading.equalTo(titleTextView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-20) // 增加右边距
            make.height.equalTo(36) // 初始高度增加
        }
        
        clearContentButton.snp.makeConstraints { make in
            make.centerY.equalTo(contentTextView)
            make.trailing.equalTo(contentTextView).offset(-10) // 调整位置
            make.width.height.equalTo(20)
        }
        
        historyTableView.snp.makeConstraints { make in
            tableViewTopConstraint = make.top.equalTo(titleTextView.snp.bottom).offset(20).constraint // 保持20px间距
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        topBGView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(historyTableView.snp.top)
        }
        
        // Set initial values
        titleTextView.text = titleText
        contentTextView.text = contentText
    }
    
    private func setupNavigationBar() {
        
        let closeBtn = GPButton(frame: .init(x: 0, y: 0, width: 40, height: 40), fontSize: 22, iconType: .btn_close)
        closeBtn.setTitleColor(.black, for: .normal)
        closeBtn.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        let closeButton = UIBarButtonItem(customView: closeBtn)
        navigationItem.leftBarButtonItem = closeButton
        
        
        let doneBtn = GPButton()
        doneBtn.setTitleColor(.systemBlue, for: .normal)
        doneBtn.setTitle("i_finish".localized(), for: .normal)
        doneBtn.titleLabel?.font = .boldSystemFont(ofSize: 18)
        doneBtn.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        let hasDoneButton = UIBarButtonItem(customView: doneBtn)
        navigationItem.rightBarButtonItem = hasDoneButton
    }
    
    private func loadData() {
        // Load history from storage
        titleHistory = WatermarkItemHistoryManager.loadHistory(for: entryId, type: .title)
        contentHistory = WatermarkItemHistoryManager.loadHistory(for: entryId, type: .content)
        
        // Sort history
        titleHistory = sortedHistory(titleHistory)
        contentHistory = sortedHistory(contentHistory)
        
        titleTextView.text = titleText
        contentTextView.text = contentText
        saveCurrentTitle()
        saveCurrentContent()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // delay
            self.updateTextViewHeight()
            self.historyTableView.reloadData()
        }
    }
    
    private func sortedHistory(_ history: [WatermarkHistoryItem]) -> [WatermarkHistoryItem] {
        return history.sorted {
            if $0.isFavorite != $1.isFavorite {
                return $0.isFavorite && !$1.isFavorite
            }
            return $0.date > $1.date
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    @objc private func clearContent() {
        contentTextView.text = ""
        contentText = ""
        updateTextViewHeight()
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func doneButtonTapped() {
        // Save current text to history
        if !titleText.isEmpty {
            saveCurrentTitle()
        }
        
        if !contentText.isEmpty {
            saveCurrentContent()
        }
        
        sureHandler?(titleText, contentText)
        
        // Dismiss the view controller
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        
        historyTableView.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(-keyboardSize.height)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        historyTableView.snp.updateConstraints { make in
            make.bottom.equalToSuperview()
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Data Management
    private func saveCurrentTitle() {
        guard !titleText.isEmpty else { return }
        
        // Check if this text already exists in history
        if let existingIndex = titleHistory.firstIndex(where: { $0.text == titleText }) {
            // Update existing item
            var existingItem = titleHistory[existingIndex]
            existingItem.date = Date()
            titleHistory[existingIndex] = existingItem
        } else {
            // Create new item
            let newItem = WatermarkHistoryItem(
                id: UUID().uuidString,
                type: .title,
                text: titleText,
                date: Date(),
                isFavorite: false
            )
            titleHistory.insert(newItem, at: 0)
        }
        
        WatermarkItemHistoryManager.saveHistory(titleHistory, for: entryId, type: .title)
        titleHistory = sortedHistory(titleHistory)
        historyTableView.reloadData()
    }
    
    private func saveCurrentContent() {
        guard !contentText.isEmpty else { return }
        
        // Check if this text already exists in history
        if let existingIndex = contentHistory.firstIndex(where: { $0.text == contentText }) {
            // Update existing item
            var existingItem = contentHistory[existingIndex]
            existingItem.date = Date()
            contentHistory[existingIndex] = existingItem
        } else {
            // Create new item
            let newItem = WatermarkHistoryItem(
                id: UUID().uuidString,
                type: .content,
                text: contentText,
                date: Date(),
                isFavorite: false
            )
            contentHistory.insert(newItem, at: 0)
        }
        
        WatermarkItemHistoryManager.saveHistory(contentHistory, for: entryId, type: .content)
        contentHistory = sortedHistory(contentHistory)
        historyTableView.reloadData()
    }
    
    private func toggleFavorite(for item: WatermarkHistoryItem) {
        guard item.type == .content else { return }
        
        if let index = contentHistory.firstIndex(where: { $0.id == item.id }) {
            // 更新收藏状态和时间
            contentHistory[index].isFavorite.toggle()
            contentHistory[index].date = Date()
            
            WatermarkItemHistoryManager.saveHistory(contentHistory, for: entryId, type: .content)
            contentHistory = sortedHistory(contentHistory)
            historyTableView.reloadData()
        }
    }
    
    private func deleteHistoryItem(_ item: WatermarkHistoryItem) {
        if item.type == .title {
            titleHistory.removeAll { $0.id == item.id }
            WatermarkItemHistoryManager.saveHistory(titleHistory, for: entryId, type: .title)
        } else {
            contentHistory.removeAll { $0.id == item.id }
            WatermarkItemHistoryManager.saveHistory(contentHistory, for: entryId, type: .content)
        }
        historyTableView.reloadData()
    }
    
    // MARK: - TextView Height Adjustment
    private func updateTextViewHeight() {
        
        func calHeight(maxWidth: CGFloat, textView: UITextView) -> CGFloat {
            let newSize = textView.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
            let newHeight = min(newSize.height, maxTextViewHeight)
            return newHeight
        }
        let maxContentWidth = GPApp.screenWidth - maxTitleWidth - 20*2 - 12
        let titleHeight = calHeight(maxWidth: maxTitleWidth, textView: titleTextView)
        let contentHeight = calHeight(maxWidth: maxContentWidth, textView: contentTextView)
        
        titleTextView.snp.updateConstraints { make in
            make.height.equalTo(titleHeight)
        }
        
        contentTextView.snp.updateConstraints { make in
            make.height.equalTo(contentHeight)
        }
        
        // 更新约束时
        if titleHeight > contentHeight {
            tableViewTopConstraint?.deactivate() // 先失效旧约束
            historyTableView.snp.makeConstraints { make in
                // 创建新约束并存储
                tableViewTopConstraint = make.top.equalTo(titleTextView.snp.bottom).offset(20).constraint
            }
        } else {
            tableViewTopConstraint?.deactivate()
            historyTableView.snp.makeConstraints { make in
                tableViewTopConstraint = make.top.equalTo(contentTextView.snp.bottom).offset(20).constraint
            }
        }
        
        self.view.forceRefresh()

    }
    
}

// MARK: - UITextViewDelegate
extension WatermarkEditViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == titleTextView {
            currentShowingHistoryType = .title
        } else {
            currentShowingHistoryType = .content
        }
        historyTableView.reloadData()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView == titleTextView {
            titleText = textView.text
        } else {
            contentText = textView.text
        }
        
        updateTextViewHeight()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
//        if textView == titleTextView {
//            saveCurrentTitle()
//        } else {
//            saveCurrentContent()
//        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        
        if updatedText.isEmpty {
            return true
        }
        
        let numberOfLines = updatedText.components(separatedBy: .newlines).count
        return numberOfLines <= 4
    }
}

extension WatermarkEditViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        titleTextView.resignFirstResponder()
        contentTextView.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension WatermarkEditViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentShowingHistoryType {
        case .title: return titleHistory.count
        case .content: return contentHistory.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if currentShowingHistoryType == .title {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TitleHistoryCell", for: indexPath) as! TitleHistoryCell
            let item = titleHistory[indexPath.row]
            cell.configure(with: item, isSelect: item.text == titleText)
            cell.onDelete = { [weak self] in
                self?.deleteHistoryItem(item)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! HistoryCell
            let item = contentHistory[indexPath.row]
            cell.configure(with: item, isSelect: item.text == contentText)
            cell.onFavorite = { [weak self] in
                self?.toggleFavorite(for: item)
            }
            cell.onDelete = { [weak self] in
                self?.deleteHistoryItem(item)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item: WatermarkHistoryItem
        if currentShowingHistoryType == .title {
            item = titleHistory[indexPath.row]
            titleTextView.text = item.text
            titleText = item.text
            titleTextView.becomeFirstResponder()
        } else {
            item = contentHistory[indexPath.row]
            contentTextView.text = item.text
            contentText = item.text
            contentTextView.becomeFirstResponder()
        }
        updateTextViewHeight()
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// MARK: - Title History Cell (没有收藏按钮)
class TitleHistoryCell: UITableViewCell {
    var onDelete: (() -> Void)?
    
    private lazy var textLabelWrapper: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white // 固定白色背景
        contentView.addSubview(textLabelWrapper)
        contentView.addSubview(deleteButton)
        
        textLabelWrapper.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(deleteButton.snp.leading).offset(-16)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-24)
            make.width.height.equalTo(18)
        }
    }
    
    func configure(with item: WatermarkHistoryItem, isSelect: Bool) {
        textLabelWrapper.text = item.text
        textLabelWrapper.textColor = isSelect ? .systemBlue : .text_strong
    }
    
    @objc private func deleteTapped() {
        onDelete?()
    }
}

// MARK: - Content History Cell (有收藏按钮)
class HistoryCell: UITableViewCell {
    var onFavorite: (() -> Void)?
    var onDelete: (() -> Void)?
    
    private lazy var textLabelWrapper: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "star"), for: .normal)
        button.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white // 固定白色背景
        contentView.addSubview(textLabelWrapper)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(deleteButton)
        
        textLabelWrapper.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(favoriteButton.snp.leading).offset(-16)
        }
        
        favoriteButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(deleteButton.snp.leading).offset(-16)
            make.width.height.equalTo(20)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-24)
            make.width.height.equalTo(18)
        }
    }
    
    func configure(with item: WatermarkHistoryItem, isSelect: Bool) {
        textLabelWrapper.text = item.text
        textLabelWrapper.textColor = isSelect ? .systemBlue : .text_strong

        // Update favorite button image
        let imageName = item.isFavorite ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = item.isFavorite ? .systemYellow : .lightGray
    }
        
    @objc private func favoriteTapped() {
        onFavorite?()
    }
    
    @objc private func deleteTapped() {
        onDelete?()
    }
}
