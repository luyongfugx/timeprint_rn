//
//  CalendarView.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/16.
//

import Foundation

import DateToolsSwift
import SnapKit
import UIKit
import Photos

class CalendarView: UICollectionViewCell {
    private var currentPage = 0;
    private var  firstScroll = true;
    private var lastContentOffset: CGPoint = .zero
    private lazy var collectionView: UICollectionView = {
        let layout = CLCalendarFlowLayout()
        layout.scrollDirection = .horizontal //横向滚动
        //layout.headerReferenceSize = CGSize(width: 0, height: config.headerHight)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .black
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.decelerationRate = .fast
        view.register(CLCalendarCell.self, forCellWithReuseIdentifier: CLCalendarCell.reuseIdentifier)
        return view
    }()

    private lazy var mainStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.distribution = .fill
        view.alignment = .fill
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = .zero
        view.spacing = 0
        return view
    }()

    private lazy var topStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        view.insetsLayoutMarginsFromSafeArea = false
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = .zero
        view.spacing = 0
        return view
    }()

    weak var delegate: CLCalendarDelegate?


    private let todayDate = Date()

    private let weekArrayAcount = 7

    private var config = CLCalendarConfig()

    private var startIndexPath: IndexPath?

    private var monthsArray = [CLCalendarMonthModel]()

    private(set) var beginDate: Date?

    private(set) var endDate: Date?

    private var itemSize = CGSize.zero

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.config = CLCalendarConfig()
        configUI()
        makeConstraints()
        initDataSource()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension CalendarView {
    func configUI() {
        backgroundColor = config.color.background
        mainStackView.layoutMargins = config.layoutMargins
        mainStackView.insetsLayoutMarginsFromSafeArea = config.insetsLayoutMarginsFromSafeArea
        contentView.addSubview(mainStackView)
        mainStackView.addArrangedSubview(topStackView)
        mainStackView.addArrangedSubview(collectionView)
        for i in 0 ..< weekArrayAcount {
            let label = UILabel()
            label.backgroundColor = config.color.topToolBackground
            label.text = GPDateFormat.calendarWeekLocal(with: i)
            label.textAlignment = .center
            
            label.textColor = i == 0 || i == 6 ? config.color.topToolTextWeekend : config.color.topToolText
            topStackView.addArrangedSubview(label)
        }
    }

    func makeConstraints() {
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        topStackView.snp.makeConstraints { make in
            make.height.equalTo(35)
        }
    }
}

extension CalendarView {
    func initDataSource() {
        func scrollToStartIndexPath() {
            guard !monthsArray.isEmpty else { return }
            collectionView.reloadData()
            collectionView.setNeedsLayout()
            collectionView.layoutIfNeeded()
            guard let startIndexPath else { return }
            let startIndexPathRow = startIndexPath.row;
            if(startIndexPathRow < collectionView.numberOfItems(inSection: 0)){
                collectionView.scrollToItem(at: startIndexPath, at: .top, animated: false)
                collectionView.contentOffset = CGPoint(x: collectionView.contentOffset.x, y: 0)
            } else {
                return
            }

        }

      func groupAssetsByCreationDate(assets: PHFetchResult<PHAsset>) -> [String: [PHAsset]] {
            var groupedAssets = [String: [PHAsset]]()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd" // Set the date format

            // Iterate through each asset in the fetch result
            assets.enumerateObjects { (asset, _, _) in
                // Get the creation date of the asset
                if let creationDate = asset.creationDate {
                    // Format the creation date to "yyyymmdd"
                    let dateKey = dateFormatter.string(from: creationDate)
                    
                    // Append the asset to the corresponding date key in the dictionary
                    if groupedAssets[dateKey] != nil {
                        groupedAssets[dateKey]?.append(asset)
                    } else {
                        groupedAssets[dateKey] = [asset]
                    }
                }
            }

            return groupedAssets // Return the grouped dictionary
        }
        func loadMonthPhotosFromTimeprint(for date: Date) -> PHFetchResult<PHAsset>? {
            let calendar = Calendar.current
            
            // Get the year and month from the provided date
            let year = calendar.component(.year, from: date)
            let month = calendar.component(.month, from: date)
            
            // Create date range for the entire month
            let startDateComponents = DateComponents(year: year, month: month, day: 1)
            let startDate = calendar.date(from: startDateComponents)!
            
            let endDateComponents = DateComponents(year: year, month: month + 1, day: 1)
            let endDate = calendar.date(from: endDateComponents)!
            
            // Fetch options for the Timeprint album
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", "Timeprint")
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            if let album = collections.firstObject {
                let assetsFetchOptions = PHFetchOptions()
                assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                
                // Add date range predicate to fetch assets created within the specified month
                assetsFetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", startDate as NSDate, endDate as NSDate)
                
                let assets = PHAsset.fetchAssets(in: album, options: assetsFetchOptions)
                return assets // Return the fetched assets
            } else {
                return nil // Return nil if the album is not found
            }
        }
        func month() -> [CLCalendarMonthModel] {
            func day(with date: Date, section: Int) -> [CLCalendarDayModel] {
                var newDate = date
                guard let assets =  loadMonthPhotosFromTimeprint(for: date) else {
                    return []
                }
                let groupedAssets = groupAssetsByCreationDate(assets: assets)
                let startDate = date;
                let tatalDay = newDate.daysInMonth
                let firstDay = max(0, newDate.weekday - 1)
                let columns = Int(ceil(CGFloat(tatalDay + firstDay) / CGFloat(weekArrayAcount)))
                let actColumns = 6
                let isColumnsLast = actColumns == columns ? true : false
                var resultArray = [CLCalendarDayModel]()
                for weekDay in 0 ..< weekArrayAcount {
                    for column in 0 ..< actColumns {
                        if column == 0,weekDay <= firstDay - 1 {
                            resultArray.append(CLCalendarDayModel())
                        }
                        else if !isColumnsLast, column == columns-1 { // 倒数第二行
                            newDate = startDate + (column*7+weekDay-firstDay).days
                            if(newDate.day < 8) {
                                resultArray.append(CLCalendarDayModel())
                            }
                            else {
                                let type: CLCalendarDayModel.CLCalendarDayType = {
                                    guard !newDate.isToday else { return .today }
                                    guard newDate.compare(todayDate) == .orderedDescending else { return .future }
                                    return .past
                                }()
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyyMMdd"
                                let dateKey = dateFormatter.string(from: newDate)
                                let gAssets = groupedAssets[dateKey]
                                let dayModel = CLCalendarDayModel(title: "\(newDate.day)", date: newDate, type: type,assets:gAssets)
                                resultArray.append(dayModel)
                                
                            }
                            
                        }
                        else if isColumnsLast, column == columns { // 最后一行，且
                            newDate = startDate + (column*7+weekDay-firstDay).days
                            if(newDate.day < 28) {
                                resultArray.append(CLCalendarDayModel())
                            }
                            else {
                                
                                let type: CLCalendarDayModel.CLCalendarDayType = {
                                    guard !newDate.isToday else { return .today }
                                    guard newDate.compare(todayDate) == .orderedDescending else { return .future }
                                    return .past
                                }()
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyyMMdd"
                                let dateKey = dateFormatter.string(from: newDate)
                                let gAssets = groupedAssets[dateKey]
                                let dayModel = CLCalendarDayModel(title: "\(newDate.day)", date: newDate, type: type,assets:gAssets)
                                resultArray.append(dayModel)
                                
                            }
                            
                        }
                        else if  column == actColumns-1 { // 最后一行，且
                            newDate = startDate + (column*7+weekDay-firstDay).days
                            if(newDate.day < 28) {
                                resultArray.append(CLCalendarDayModel())
                            }
                            else {
                                let type: CLCalendarDayModel.CLCalendarDayType = {
                                    guard !newDate.isToday else { return .today }
                                    guard newDate.compare(todayDate) == .orderedDescending else { return .future }
                                    return .past
                                }()
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyyMMdd"
                                let dateKey = dateFormatter.string(from: newDate)
                                let gAssets = groupedAssets[dateKey]
                                let dayModel = CLCalendarDayModel(title: "\(newDate.day)", date: newDate, type: type,assets:gAssets)
                                resultArray.append(dayModel)
                            }
                            
                        }
                        else if column >= columns,!isColumnsLast { // 如果当月只有5行，第六行补空
                            let dayModel = CLCalendarDayModel(title: "0", date: newDate, type: .future)
                            resultArray.append(dayModel)
                            resultArray.append(CLCalendarDayModel())
                        }
                        else {
                            newDate = startDate + (column*7+weekDay-firstDay).days
                            let type: CLCalendarDayModel.CLCalendarDayType = {
                                guard !newDate.isToday else { return .today }
                                guard newDate.compare(todayDate) == .orderedDescending else { return .future }
                                return .past
                            }()
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyyMMdd"
                            let dateKey = dateFormatter.string(from: newDate)
                            let gAssets = groupedAssets[dateKey]
                            let dayModel = CLCalendarDayModel(title: "\(newDate.day)", date: newDate, type: type,assets:gAssets)
                            resultArray.append(dayModel)
                        }
                    }
                }
                return resultArray
            }

            var resultArray = [CLCalendarMonthModel]()

            let start = config.beginDate
            let maxMonths = config.endDate.monthsLater(than: config.beginDate)
//            print("start \(start) maxMonths: \(maxMonths)")
            for i in 0 ... maxMonths {
                let date = start + i.months
//                print("start + i.months: \(date)")
                let headerModel = CLCalendarMonthModel(headerText: date.format(with: "yyyy年MM月"),
                                                       month: date.format(with: "MM"),
                                                       daysArray: day(with: Date(year: date.year, month: date.month, day: 1), section: i))
                if config.position.year == date.year,
                   config.position.month == date.month
                {
                    startIndexPath = .init(row: 0, section: i)
                }
                resultArray.append(headerModel)
            }
            return resultArray
        }

        DispatchQueue.global().async {
            self.beginDate = self.config.selectBegin
            self.endDate = self.config.selectEnd
            let tempDataArray = month()
            DispatchQueue.main.async {
                let width = self.collectionView.bounds.width
                let minimumDifference = width.truncatingRemainder(dividingBy: CGFloat(self.weekArrayAcount))
                let maxWidth = width - minimumDifference
                let cellWidth = maxWidth / CGFloat(self.weekArrayAcount)
                self.itemSize = CGSize(width: cellWidth, height: cellWidth)
                
                self.mainStackView.layoutMargins = .init(top: self.config.layoutMargins.top,
                                                         left: self.config.layoutMargins.left + CGFloat(minimumDifference) * 0.5,
                                                         bottom: self.config.layoutMargins.bottom,
                                                         right: self.config.layoutMargins.right + CGFloat(minimumDifference) * 0.5)
                
                let layoutDirection = UIApplication.shared.userInterfaceLayoutDirection
                //左到右布局
                if(layoutDirection == .leftToRight) {
                    self.monthsArray = tempDataArray
                }
                else { //右到左布局，比如阿拉伯人,倒过来
                    self.monthsArray = tempDataArray.reversed()
                }
               // layoutDirection == .leftToRight
              
                scrollToStartIndexPath()
            }
        }
    }
}

extension CalendarView: CLCalendarDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
     
        guard let dataCell = collectionView.dequeueReusableCell(withReuseIdentifier: CLCalendarCell.reuseIdentifier, for: indexPath) as? CLCalendarCell else { return UICollectionViewCell(frame: .zero) }
        
        
        var  model = monthsArray[indexPath.section].daysArray[indexPath.row]
        let layoutDirection = UIApplication.shared.userInterfaceLayoutDirection
        //左到右布局
        if(layoutDirection == .rightToLeft) {
            let monthIndex = monthsArray.count - indexPath.section-1
            model  = monthsArray[monthIndex].daysArray[indexPath.row]
        }

        dataCell.refreshData(model, config: config, startDate: beginDate, endDate: endDate,itemSize:itemSize)
        return dataCell
    }
    func dateWithSameYearAndMonth(as inputDate: Date) -> Date? {
        let calendar = Calendar.current
        
        // Extract year and month from the input date
        let year = calendar.component(.year, from: inputDate)
        let month = calendar.component(.month, from: inputDate)
        
        // Get today's date and extract the day
        let today = Date()
        let day = calendar.component(.day, from: today)
        
        // Create a new date with the same year and month, but today's day
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        return calendar.date(from: components)
    }
    //左右移动
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //判断当前用户习惯是向左还是向右布局 比如阿拉伯人是从右向左滚动
//        .leftToRight: 从左向右布局
//        .rightToLeft: 从右向左布局，
        
        let layoutDirection = UIApplication.shared.userInterfaceLayoutDirection
       // layoutDirection == .leftToRight
        let contentOffset = scrollView.contentOffset
       // print("scrollViewDidScroll === contentOffset.x: \(contentOffset.x) ) layoutDirection: \(layoutDirection)")
        
        let width = scrollView.frame.size.width
        let scrollPage = Int(contentOffset.x / width)
//        print("scrollViewDidScroll === contentOffset.x: \(contentOffset.x) scrollPage: \(scrollPage) monthsArray.count: \(monthsArray.count) layoutDirection: \(layoutDirection)")
        if scrollPage < 0 || scrollPage >= monthsArray.count {
            return
        }
        let headerItem = monthsArray[scrollPage]
        firstScroll = false
        let middleIndex = Int(headerItem.daysArray.count/2)
        // 自动跳转到今天
        let calendarItem = headerItem.daysArray[middleIndex]
        //print("calendarItem: \(calendarItem) ) layoutDirection: \(layoutDirection)")
        if let newDate = dateWithSameYearAndMonth(as: calendarItem.date! ) {
           // print("newDate: \(newDate) ) layoutDirection: \(layoutDirection)")
            func reloadDate() {
                defer {
                    delegate?.didSelectDate(date: newDate, in: self)
                }
                if config.selectType == .single {
                    beginDate = newDate
                } else {
                    guard let start = beginDate else { return beginDate = newDate }
                    guard endDate != nil || newDate < start else { return endDate = newDate }
                    beginDate = newDate
                    endDate = nil
                }
            }
            reloadDate()
            collectionView.reloadData()
        }
       
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let headerItem = monthsArray[indexPath.section]
        let calendarItem = headerItem.daysArray[indexPath.row]
        guard let date = calendarItem.date else { return }
        func reloadDate() {
            defer {
                delegate?.didSelectDate(date: date, in: self)
            }
            if config.selectType == .single {
                beginDate = date
            } else {
                guard let start = beginDate else { return beginDate = date }
                guard endDate != nil || date < start else { return endDate = date }
                beginDate = date
                endDate = nil
            }
        }
        reloadDate()
        collectionView.reloadData()
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, textColorForSectionAt section: Int) -> UIColor {
        config.color.sectionBackgroundText
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }
}

extension CalendarView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        monthsArray.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       
        let layoutDirection = UIApplication.shared.userInterfaceLayoutDirection
        if(layoutDirection == .rightToLeft) { //阿拉伯人
            let monthIndex = monthsArray.count - section-1
            return monthsArray[monthIndex].daysArray.count
        }
        else {
          return   monthsArray[section].daysArray.count
        }
    
    }
}
