import Foundation
import UIKit
import Photos

class FolderViewController: UIViewController {
    
    // MARK: - Properties
    private var assets: PHFetchResult<PHAsset>?
    private var displayedAssets: [PHAsset] = []
    private var filteredAssets: [PHAsset] = []
    private var isSearching: Bool = false
    private let imageManager = PHCachingImageManager()
    private let thumbnailSize = CGSize(width: 80, height: 80)
    private let pageSize = 20
    private var currentPage = 0
    private var hasMorePhotos = true
    lazy var topView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
        
    @objc func backBtnClick() {
        navigationController?.popViewController(animated: true)
    }
    
    lazy var backBtn: UIButton = {
        let btn = UIButton(type: .custom)
        var image = UIImage.zl.getImage("zl_navClose")
        if isRTL() {
            image = image?.imageFlippedForRightToLeftLayoutDirection()
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -10)
        } else {
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        }
        btn.setImage(image, for: .normal)
        btn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = .systemBackground
        table.register(PhotoCell.self, forCellReuseIdentifier: "PhotoCell")
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        return table
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refresh
    }()
    
    lazy var searchView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()
    
    lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "i_search_by_filename".localized()
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        return searchBar
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
            imageView.image = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: config)
            imageView.tintColor = .gray
        }
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "k_empty_folder".localized()
        label.textColor = .gray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.heightAnchor.constraint(equalToConstant: 100),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
        checkPhotoLibraryPermission()
        
        // 添加通知观察者
        NotificationCenter.default.addObserver(self, 
            selector: #selector(handleTimeprintAlbumUpdate), 
            name: AlbumViewController.timeprintAlbumDidUpdateNotification, 
            object: nil)
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    deinit {
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Setup
    private func setupUI() {
         title = "k_folder_name".localized()
//        title = "Timeprint"
        view.backgroundColor = .systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        view.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(GPApp.statusBarAndNavigationBarHeight)
        }
        
        topView.addSubview(backBtn)
        backBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
            make.height.equalTo(44)
            make.width.equalTo(44)
        }
        
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        topView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backBtn)
        }
        
        // Add search view
        view.addSubview(searchView)
        searchView.snp.makeConstraints { make in
            make.top.equalTo(topView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(56)
        }
        
        searchView.addSubview(searchBar)
        searchBar.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        }
        
        view.addSubview(tableView)
        tableView.snp.remakeConstraints { make in
            make.top.equalTo(searchView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        
        tableView.refreshControl = refreshControl
        
        view.addSubview(emptyStateView)
        emptyStateView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(200)
        }
    }
    
    private func setupData() {
        // Do nothing
    }
    
    private func checkPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    self?.loadPhotosFromTimeprint()
                }
            }
        }
    }
    
    private func loadPhotosFromTimeprint() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "Timeprint")
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let album = collections.firstObject {
            let assetsFetchOptions = PHFetchOptions()
            assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            assets = PHAsset.fetchAssets(in: album, options: assetsFetchOptions)
            updateEmptyStateVisibility()
            
            // 只有在不为空的情况下才加载下一页
            if !(assets?.count == 0 || assets == nil) {
                loadNextPage()
            }
        } else {
            assets = nil
            updateEmptyStateVisibility()
        }
    }
    
    private func updateEmptyStateVisibility() {
        let isEmpty = assets?.count == 0 || assets == nil
        LogDebug("FolderViewController - isEmpty: \(isEmpty), assets count: \(assets?.count ?? 0)")
        
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
    private func loadNextPage() {
        guard let assets = assets,
              hasMorePhotos else { return }
        
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, assets.count)
        
        guard startIndex < assets.count else {
            hasMorePhotos = false
            return
        }
        
        var newAssets: [PHAsset] = []
        for i in startIndex..<endIndex {
            let asset = assets[i]
            newAssets.append(asset)
        }
        
        filteredAssets.append(contentsOf: newAssets)
        
        if !isSearching {
            displayedAssets = filteredAssets
        } else if let searchText = searchBar.text, !searchText.isEmpty {
            // Apply current search filter to new assets
            displayedAssets = filteredAssets.filter { $0.originalFilename?.lowercased().contains(searchText.lowercased()) ?? false }
        }
        
        currentPage += 1
        hasMorePhotos = endIndex < assets.count
        
        tableView.reloadData()
    }
    
    @objc private func handleRefresh() {
        currentPage = 0
        hasMorePhotos = true
        assets = nil;
        filteredAssets.removeAll()
        displayedAssets.removeAll()
        loadPhotosFromTimeprint()
        // tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    // 处理相册更新通知
    @objc private func handleTimeprintAlbumUpdate() {
//        print("handleTimeprintAlbumUpdate")
        // 刷新文件夹视图
        DispatchQueue.main.async {
            self.handleRefresh()
        }
        
    }
    
    @objc private func handleTapOutside() {
        view.endEditing(true)
    }
}

// MARK: - PHAsset Extension
extension PHAsset {
    var originalFilename: String? {
        var filename: String?
        let resources = PHAssetResource.assetResources(for: self)
        if let resource = resources.first {
            filename = resource.originalFilename
        }
        return filename
    }
    
    static func fetchIndexInAssetCollection(asset: PHAsset, in fetchResult: PHFetchResult<PHAsset>) -> Int {
        // Find the index of the asset in the fetch result
        let index = fetchResult.index(of: asset)
        return index
    }
}

// MARK: - UITableViewDataSource
extension FolderViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedAssets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        guard indexPath.row < displayedAssets.count else {
            return cell
        }
        
        let asset = displayedAssets[indexPath.row]
        
        cell.configure(with: asset)
        
        // 检查是否需要加载更多
        if indexPath.row == displayedAssets.count - 1 && hasMorePhotos {
            loadNextPage()
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FolderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
//        let selectedAsset = displayedAssets[indexPath.row]
//        guard let assets = assets else { return }
        
        // Find the actual index of the asset in the original asset list
        //
//        let actualIndex = PHAsset.fetchIndexInAssetCollection(asset: selectedAsset, in: assets)
       // let actualIndex = PHAsset.fetchIndexInAssetCollection(asset: selectedAsset, in: assets)
        let actualIndex = indexPath.row
        let models = displayedAssets.map { ZLPhotoModel(asset: $0) }
        let albumVC = AlbumViewController()
        albumVC.isFromTimeprint = true
        albumVC.arrDataSources = models
        albumVC.firstIndex = actualIndex
        //print("actualIndex: \(actualIndex)")
        
        // add by waynelu 如果有搜索，则需要过滤
        if let searchText = searchBar.text, !searchText.isEmpty {
            // Apply current search filter to new assets
            albumVC.searchText = searchText
        }
        // print("firstIndex \(albumVC.firstIndex)")
        navigationController?.pushViewController(albumVC, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Load more photos when reaching the bottom
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let screenHeight = scrollView.bounds.height
        
        if offsetY > contentHeight - screenHeight * 2 && hasMorePhotos {
            loadNextPage()
        }
    }
}

// MARK: - UISearchBarDelegate
extension FolderViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            displayedAssets = filteredAssets
        } else {
            //上报搜索
            GPFirebaseManager.photo_search();
            isSearching = true
            displayedAssets = filteredAssets.filter { $0.originalFilename?.lowercased().contains(searchText.lowercased()) ?? false }
        }
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - PhotoCell
class PhotoCell: UITableViewCell {
    let photoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 3
        return imageView
    }()
    
    let playButton: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "play.circle.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.8
        imageView.isHidden = true
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .systemGray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        [photoImageView, playButton, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            photoImageView.widthAnchor.constraint(equalToConstant: 48),
            photoImageView.heightAnchor.constraint(equalToConstant: 48),
            
            playButton.centerXAnchor.constraint(equalTo: photoImageView.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: photoImageView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 26),
            playButton.heightAnchor.constraint(equalToConstant: 26),
            
            titleLabel.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }
    
    func configure(with asset: PHAsset) {
        // 设置播放按钮的可见性
        playButton.isHidden = asset.mediaType != .video
        
        // 获取缩略图
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            self?.photoImageView.image = image
        }
        
        // 设置标题（文件名）
        let resources = PHAssetResource.assetResources(for: asset)
        titleLabel.text = resources.first?.originalFilename
        
        // 设置副标题（创建时间）
        if let creationDate = asset.creationDate {
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
             //使用本地化时间格式
            subtitleLabel.text = GPDateFormat.localizedDateString(creationDate, style: GPDateStyle.yearMonthDateSpecialCountry, is12Hours: false, isShowWeek: false, isShowTimezone: false,needSecond: false)
           // subtitleLabel.text = dateFormatter.string(from: creationDate)
        }
    }
}
