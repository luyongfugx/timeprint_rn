//
//  CalendarViewController.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/15.
//

import Foundation
import UIKit
import Photos

class CalendarViewController: UIViewController {
    var lastDateSelectionTime: Date?
    let calendar = Calendar.current
    var currentMonth: Date!
    var selectedPhotos = [PHAsset]()
    var date: Date?
    let titleLabel = UILabel()
    let maxCountOfPhotos = 20
    var groupedPhotos = [PHAsset]()
    
    let collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 4
        flowLayout.minimumInteritemSpacing = 4
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .black
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.registerCell(CalendarPhotoCell.self)
        collectionView.registerCell(CalendarView.self)
        collectionView.registerCell(EmptyPhotoCell.self)
        return collectionView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCalendarView()
        setupCollectionView()
        
    }
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topView.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
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
    private func setupCalendarView() {

        let  title =  GPDateFormat.localizedDateString(Date(), style: GPDateStyle.yearMonthDateSpecialCountry, is12Hours: false, isShowWeek: false, isShowTimezone: false,needSecond: true,onlyYearMonthDay:true)
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
        

        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        topView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backBtn)
        }
        //上报日志
        GPFirebaseManager.calendar_view()
    }
}

// Implement UICollectionViewDataSource and UICollectionViewDelegate methods
extension CalendarViewController: CLCalendarDelegate {


    func loadPhotosFromTimeprint(for date: Date) -> [PHAsset]? {
        // Fetch the "Timeprint" album
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "Timeprint")
        let album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions).firstObject
        
        guard let timeprintAlbum = album else { return nil }
        
        // Fetch assets from the "Timeprint" album created on the specified date
        let assetFetchOptions = PHFetchOptions()
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)
        assetFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        assetFetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", startOfDay as NSDate, endOfDay! as NSDate)
        let assets = PHAsset.fetchAssets(in: timeprintAlbum, options: assetFetchOptions)
        return assets.objects(at: IndexSet(integersIn: 0..<assets.count))
    }
    func didSelectDate(date: Date, in view: CalendarView) {
        lastDateSelectionTime = Date()
        self.date = date
        titleLabel.text =   GPDateFormat.localizedDateString(date, style: GPDateStyle.yearMonthDateSpecialCountry, is12Hours: false, isShowWeek: false, isShowTimezone: false,needSecond: true,onlyYearMonthDay:true)
        groupedPhotos = loadPhotosFromTimeprint(for: date) ?? []
       self.collectionView.reloadData()
    
    }
}


extension CalendarViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in _: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = groupedPhotos.count > 0 ? (groupedPhotos.count)+1 : 2
        return  count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.row == 0 {
            let cell = collectionView.dequeueCell(CalendarView.self, for: indexPath)
            cell.delegate = self
            return cell
        }
        else {
            if (groupedPhotos.count > 0 ){
                let cell = collectionView.dequeueCell(CalendarPhotoCell.self, for: indexPath)
                cell.delegate = self
                let index = indexPath.row-1
                if (groupedPhotos.count > 0 ){
                 let   asset = groupedPhotos[index]
                  cell.configAsset(asset)
                }
                return cell
            }
            else {
                //空
                let cell = collectionView.dequeueCell(EmptyPhotoCell.self, for: indexPath)
               // cell.delegate = self
                return cell
            }
 
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
   
            if indexPath.row >= 0 ,groupedPhotos.count > 0 {
                let index = indexPath.row-1
                let models = groupedPhotos.map { ZLPhotoModel(asset: $0) }
                let albumVC = AlbumViewController()
                albumVC.isFromTimeprint = true
                albumVC.arrDataSources = models
                albumVC.firstIndex = index
                albumVC.createDate = date
                navigationController?.pushViewController(albumVC, animated: true)
            }
            
    }
    
    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt : IndexPath) -> CGSize {
        if sizeForItemAt.row == 0 {
            let width = self.collectionView.bounds.width
            let weekCount =  7
            let minimumDifference = width.truncatingRemainder(dividingBy: CGFloat(weekCount))
            let maxWidth = width - minimumDifference
            return CGSize(width: maxWidth, height: maxWidth)
        }
        else {
            let numberOfColumns: CGFloat = 3
            let spacing: CGFloat = 4
            let totalSpacing = (numberOfColumns - 1) * spacing
            let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
            // 向下取整，比如135.3，最终取135
            let finalWidth = floor(width)
            return CGSize(width: finalWidth, height: finalWidth)
        }
        
    }
}

extension CalendarViewController: MultiPhotoSelectProtocol {
    func shouldSelectPhoto() -> Bool {
        selectedPhotos.count < maxCountOfPhotos
    }
    
    func selectedPhotosReachMaxCount() {
        GPToast.text("i_share_20_only".localized())
    }
}
