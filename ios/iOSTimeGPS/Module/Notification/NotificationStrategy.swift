
import Foundation
import UserNotifications

/// Notification types our strategy can schedule
enum SEAReminderKind: String, Codable {
    case habit       // 规律提醒
    case dormant3d   // 3天未拍 轻提醒
    case dormant7d   // 7天未拍 风险提醒
    case dormant30d  // 30天未拍 强唤醒/回流
    case restart     // 假期后的重启提醒
    case summary     // 周/月度总结（这里保留占位，当前未调度）
}

/// Minute-of-day convenience
extension Date {
    var sea_minuteOfDay: Int {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: self)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }
    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

/// A simple EMA-based habit model with 96 quarter-hour bins, tracking last 14d
final class SEAHabitModel: Codable {
    private(set) var weights: [Double] = Array(repeating: 0, count: 96) // per 15min bin
    private(set) var lastUpdate: Date = Date(timeIntervalSince1970: 0)
    /// EMA alpha ~ 1 - exp(-1/14d) per day; but we update per event. Keep it slightly conservative.
    private let alpha: Double = 0.15
    
    func recordShot(at date: Date) {
        lastUpdate = Date()
        let minute = date.sea_minuteOfDay
        let bin = max(0, min(95, minute / 15))
        for i in 0..<weights.count {
            weights[i] *= (1.0 - alpha)
        }
        weights[bin] += alpha * 10.0  // boost per event to make peaks emerge faster
    }
    
    /// Returns up to 2 peak windows as (startMin, endMin). Each window ~45min wide around the local peak.
    func topWindows(limit: Int = 2) -> [(Int, Int)] {
        guard weights.contains(where: { $0 > 0.01 }) else { return [] }
        var peaks: [(idx: Int, val: Double)] = weights.enumerated().map { ($0, $1) }
        peaks.sort { $0.val > $1.val }
        var windows: [(Int, Int)] = []
        var used = Set<Int>()
        for p in peaks {
            if windows.count >= limit { break }
            if used.contains(p.idx) { continue }
            // 3-bin (45min) window centered on p.idx
            let indices = [p.idx-1, p.idx, p.idx+1].map { ($0 + 96) % 96 }
            indices.forEach { used.insert($0) }
            let startMin = ((indices.first! + 96) % 96) * 15
            let endMin = ((indices.last! + 96) % 96) * 15 + 15
            windows.append((startMin, endMin))
        }
        return windows
    }
    
    /// Simple night-shift detection: if strongest peak is between 22:00-06:00
    var isNightShift: Bool {
        guard let top = topWindows(limit: 1).first else { return false }
        let mid = (top.0 + top.1) / 2
        return mid >= 22*60 || mid < 6*60
    }
}

struct SEAState: Codable {
    var appLaunchCount: Int = 0
    var photoCount: Int = 0
    var lastPhotoAt: Date? = nil
    var lastScheduledAt: Date? = nil
    var lastFiredAt: Date? = nil
    var lastClickedAt: Date? = nil
    var ignoreCount: Int = 0
    var pauseUntil: Date? = nil   // 忽略两次 → 暂停3天
    var downgradeUntil: Date? = nil  // 暂停结束后7天仅周一/仅第一峰值窗
    
    var lastScheduledKind: SEAReminderKind? = nil
    var countryCode: String? = nil  // VN / ID / MY / TH / etc.
    var holidayYearCache: [String: [String]] = [:] // cache not used directly here
    var lastHolidayFlag: Bool = false
    var lastHolidayCheckedAt: Date? = nil
}

/// Nager.Date holidays provider with +2d buffer and disk cache
final class SEAHolidayProvider {
    static let shared = SEAHolidayProvider()
    private let cacheFolder: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("SEA_Holidays", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()
    
    func key(country: String, year: Int) -> String { "\(country)-\(year)" }
    
    func cached(country: String, year: Int) -> [Date]? {
        let url = cacheFolder.appendingPathComponent("\(country)-\(year).json")
        if let data = try? Data(contentsOf: url),
           let arr = try? JSONDecoder().decode([String].self, from: data) {
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withFullDate]
            return arr.compactMap { fmt.date(from: $0) }
        }
        return nil
    }
    
    func saveCache(country: String, year: Int, dates: [Date]) {
        let url = cacheFolder.appendingPathComponent("\(country)-\(year).json")
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        let strings = dates.map { fmt.string(from: $0) }
        if let data = try? JSONEncoder().encode(strings) {
            try? data.write(to: url)
        }
    }
    
    /// Fetch Nager.Date and buffer each holiday +2 days
    func fetch(country: String, year: Int, completion: @escaping ([Date]) -> Void) {
        if let c = cached(country: country, year: year) {
            completion(c)
            return
        }
        guard let url = URL(string: "https://date.nager.at/api/v3/PublicHolidays/\(year)/\(country)") else {
            completion([]); return
        }
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            var result: [Date] = []
            defer { DispatchQueue.main.async { completion(result) } }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withFullDate]
            var set = Set<Date>()
            for item in json {
                if let dateStr = item["date"] as? String,
                   let d = fmt.date(from: dateStr) {
                    for offset in 0...2 { // +2天缓冲
                        if let dd = Calendar.current.date(byAdding: .day, value: offset, to: d) {
                            set.insert(Calendar.current.startOfDay(for: dd))
                        }
                    }
                }
            }
            result = Array(set).sorted()
            self.saveCache(country: country, year: year, dates: result)
        }
        task.resume()
    }
    
    func isBufferedHoliday(_ date: Date, country: String, completion: @escaping (Bool) -> Void) {
        let y = Calendar.current.component(.year, from: date)
        fetch(country: country, year: y) { dates in
            let day = Calendar.current.startOfDay(for: date)
            completion(dates.contains(day))
        }
    }
}

/// Ramadan ranges for ID/MY (approximate, can be updated yearly)
struct SEARamadanProvider {
    // Year: (startISO, endISO) inclusive range (approximate civil calendar)
    // These can be refined server-side; keep a few years to avoid immediate staleness.
    static let id: [Int: (String, String)] = [
        2025: ("2025-02-28", "2025-03-29"),
        2026: ("2026-02-17", "2026-03-18"),
    ]
    static let my = id // approx same range window for MY
    
    static func isDuringRamadan(_ date: Date, country: String) -> Bool {
        let y = Calendar.current.component(.year, from: date)
        let dict = (country.uppercased() == "ID") ? id : (country.uppercased() == "MY" ? my : [:])
        guard let (s, e) = dict[y] else { return false }
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        guard let sd = fmt.date(from: s), let ed = fmt.date(from: e) else { return false }
        let d = date.startOfDay()
        return (sd.startOfDay() ... ed.startOfDay()).contains(d)
    }
}

/// The main orchestrator for SEA notification strategy
final class SEANotificationStrategy {
    static let shared = SEANotificationStrategy()
    
    private let center = UNUserNotificationCenter.current()
    private let queue = DispatchQueue(label: "SEA.NotificationStrategy", qos: .utility)
    private let storageKey = "SEA.Notification.State.v1"
    private(set) var state: SEAState
    private(set) var habit: SEAHabitModel
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let s = try? JSONDecoder().decode(SEAState.self, from: data),
           let hData = UserDefaults.standard.data(forKey: storageKey + ".habit"),
           let h = try? JSONDecoder().decode(SEAHabitModel.self, from: hData) {
            self.state = s
            self.habit = h
        } else {
            self.state = SEAState()
            self.habit = SEAHabitModel()
        }
    }
    
    private func persist() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        if let data = try? JSONEncoder().encode(habit) {
            UserDefaults.standard.set(data, forKey: storageKey + ".habit")
        }
    }
    
    // MARK: - Entry Points
    
    /// Call on app launch
    func onAppLaunch(countryOverride: String? = nil) {
        state.appLaunchCount += 1
        if let c = countryOverride { state.countryCode = c.uppercased() }
        else if state.countryCode == nil {
            state.countryCode = Locale.current.regionCode?.uppercased() ?? "VN"
        }
        persist()
        
        // 清除App图标小红点
        clearAppIconBadge()
        
        requestProvisionalIfNeeded()
        
        recalculateAndScheduleNextReminder()
    }
    
    /// 清除App图标小红点
    private func clearAppIconBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    /// Call when a valid photo is saved (successful capture)
    func recordPhotoShot(at date: Date = Date()) {
        state.photoCount += 1
        state.lastPhotoAt = date
        habit.recordShot(at: date)
        persist()
        
        requestFullIfEscalationPoint()
        
        // Cancel today's pending if any; user已完成
        cancelTodayPending { [weak self] in
            self?.recalculateAndScheduleNextReminder()
        }
    }
    
    /// AppDelegate通知点击时调用
    func onNotificationTapped(at date: Date = Date()) {
        state.lastClickedAt = date
        state.ignoreCount = 0 // reset ignore on click
        // 清除App图标小红点
        clearAppIconBadge()
        persist()
    }
    
    // Called periodically/foreground to infer ignore
    func onBecameActive(now: Date = Date()) {
        // 清除App图标小红点
        clearAppIconBadge()
        if let fired = state.lastFiredAt, state.lastClickedAt == nil || (state.lastClickedAt! < fired) {
            // If >1h since fired and no click recorded → treat as ignore
            if now.timeIntervalSince(fired) > 3600 {
                state.ignoreCount += 1
                if state.ignoreCount >= 2 {
                    // pause 3 days, then downgrade next 7 days
                    state.pauseUntil = Calendar.current.date(byAdding: .day, value: 3, to: now)
                    state.downgradeUntil = Calendar.current.date(byAdding: .day, value: 10, to: now) // 3天暂停 + 后续7天降级窗口
                    state.ignoreCount = 0
                }
                persist()
            }
        }
        recalculateAndScheduleNextReminder()
    }
    
    // MARK: - Permission
    
    private func requestProvisionalIfNeeded() {
        center.getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            if settings.authorizationStatus == .notDetermined {
                self.center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, _ in
                    // Provisional does not show prompt; granted indicates delivery to Notification Center.
                    // No-op; escalate later.
                }
            }
        }
    }
    
    // MARK: - Permission with Pre-prompt

    private func requestFullIfEscalationPoint() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            
            if #available(iOS 14.0, *) {
                if settings.authorizationStatus == .provisional || settings.authorizationStatus == .ephemeral {
                    self.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        if granted {
                            print("User granted full notification permission")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pre-prompt Management

    private struct SEAPermissionPrePromptState: Codable {
        var lastResponseDate: Date?
        var userAgreed: Bool?
        var promptShownCount: Int = 0
    }

    private var prePromptState: SEAPermissionPrePromptState {
        get {
            if let data = UserDefaults.standard.data(forKey: "SEA.PermissionPrePrompt.State"),
               let state = try? JSONDecoder().decode(SEAPermissionPrePromptState.self, from: data) {
                return state
            }
            return SEAPermissionPrePromptState()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "SEA.PermissionPrePrompt.State")
            }
        }
    }

    private func shouldShowPermissionPrePrompt() -> Bool {
        let state = prePromptState
        
        // If user already agreed, don't show again
        if state.userAgreed == true {
            return false
        }
        
        // If user chose "Later", wait 1 month before showing again
        if let lastResponseDate = state.lastResponseDate, state.userAgreed == false {
            let oneMonthLater = Calendar.current.date(byAdding: .month, value: 1, to: lastResponseDate) ?? Date()
            return Date() >= oneMonthLater
        }
        
        // First time or no response recorded
        return true
    }

    private func recordPermissionPrePromptResponse(agreed: Bool) {
        var state = prePromptState
        state.lastResponseDate = Date()
        state.userAgreed = agreed
        state.promptShownCount += 1
        prePromptState = state
    }

    // MARK: - Pre-prompt UI

    // MARK: - Pre-prompt UI

    private func showPermissionPrePrompt(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let cancelAction = ZLCustomAlertAction(title: "k_permission_later".localized(), style: .default) { _ in
                self.recordPermissionPrePromptResponse(agreed: false)
                completion(false)
            }
            let enableAction = ZLCustomAlertAction(title: "k_permission_enable_reminders".localized(), style: .tint) { _ in
                self.recordPermissionPrePromptResponse(agreed: true)
                completion(true)
            }
            showAlertController(title: "k_permission_title".localized(), message: "k_permission_message".localized(), shouldMessageLeft: false, style: .alert, actions: [enableAction, cancelAction], sender: GPApp.topViewController)
        }
    }

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
    
    // MARK: - Scheduling
    
    private let dailyIdentifier = "SEA.reminder.daily"
    
    /// Cancel only today's pending reminder
    private func cancelTodayPending(completion: (() -> Void)? = nil) {
        center.getPendingNotificationRequests { reqs in
            let todayStr = Self.dateKey(Date())
            let ids = reqs.filter { $0.identifier.hasPrefix(self.dailyIdentifier + "." + todayStr) }.map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
            completion?()
        }
    }
    
    static func dateKey(_ d: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd"
        fmt.timeZone = .current
        return fmt.string(from: d)
    }
    
    private func alreadyScheduledToday(_ completion: @escaping (Bool) -> Void) {
        center.getPendingNotificationRequests { reqs in
            let todayStr = Self.dateKey(Date())
            let has = reqs.contains { $0.identifier.hasPrefix(self.dailyIdentifier + "." + todayStr) }
            completion(has)
        }
    }
    
    /// Core orchestrator
    func recalculateAndScheduleNextReminder(now: Date = Date()) {
        let country = state.countryCode ?? (Locale.current.regionCode?.uppercased() ?? "VN")
        // Respect global pause
        if let pause = state.pauseUntil, now < pause { return }
        // 12h cooling after click
        if let lastClick = state.lastClickedAt, now.timeIntervalSince(lastClick) < 12*3600 { return }
        
        // Holiday pause / restart-only
        SEAHolidayProvider.shared.isBufferedHoliday(now, country: country) { [weak self] isHoliday in
            guard let self = self else { return }
            if isHoliday {
                // cancel today & mark holiday
                self.state.lastHolidayFlag = true
                self.state.lastHolidayCheckedAt = now
                self.persist()
                self.cancelTodayPending()
                return
            } else {
                // if yesterday (or last check) was holiday → schedule one-time restart reminder at next work start
                if self.state.lastHolidayFlag {
                    self.state.lastHolidayFlag = false
                    self.state.lastHolidayCheckedAt = now
                    self.persist()
                    let fire = self.nextWorkStart(after: now)
                    self.schedule(kind: .restart, at: fire, now: now)
                    return
                }
                self.scheduleConsideringPolicies(now: now, country: country)
            }
        }
    }
    
    private func scheduleConsideringPolicies(now: Date, country: String) {
        alreadyScheduledToday { [weak self] has in
            guard let self = self else { return }
            if has { return } // 一天最多1条
            
            // Decide which to schedule: habit > dormant
            let kindAndDate = self.computeBestReminder(now: now, country: country)
            guard let (kind, fireDate) = kindAndDate else { return }
            if !self.respectsDowngradePolicy(fireDate, isHabit: kind == .habit) { return }
            
            // Enforce silent hours
            if !self.habit.isNightShift {
                // default 21:00–06:00 silent
                let h = Calendar.current.component(.hour, from: fireDate)
                if h >= 21 || h < 6 { return }
            } else {
                // night shift → silence daytime 09:00–18:00
                let h = Calendar.current.component(.hour, from: fireDate)
                if (9...18).contains(h) { return }
            }
            
            self.schedule(kind: kind, at: fireDate, now: now)
        }
    }
    
    
    private func respectsDowngradePolicy(_ date: Date, isHabit: Bool) -> Bool {
        if let until = state.downgradeUntil, Date() < until {
            // only Monday AND only first window for habit reminders
            let wd = Calendar.current.component(.weekday, from: date) // 1=Sun ... 2=Mon
            let isMonday = (wd == 2)
            return isMonday && isHabit
        }
        return true
    }
private func computeBestReminder(now: Date, country: String) -> (SEAReminderKind, Date)? {
        // 1) Habit window +15min if not shot yet
        if let habitDate = nextHabitReminderDate(after: now, country: country) {
            return (.habit, habitDate)
        }
        // 2) Dormant wake-ups
        if let last = state.lastPhotoAt {
            let days = Calendar.current.dateComponents([.day], from: last.startOfDay(), to: now.startOfDay()).day ?? 0
            if days >= 30 {
                // strong reactivation; during Ramadan, reduce frequency to once per week (Mon)
                if SEARamadanProvider.isDuringRamadan(now, country: country) {
                    let wd = Calendar.current.component(.weekday, from: now) // Mon=2
                    if wd != 2 { return nil }
                }
                let fire = nextWorkStart(after: now)
                return (.dormant30d, fire)
            } else if days >= 7 {
                // reduce frequency during Ramadan
                if SEARamadanProvider.isDuringRamadan(now, country: country) {
                    // schedule every other day after day 7
                    if days % 2 == 1 { return nil }
                }
                let fire = nextWorkStart(after: now)
                return (.dormant7d, fire)
            } else if days >= 3 {
                if SEARamadanProvider.isDuringRamadan(now, country: country) {
                    // every 3 days → every 4-5 days
                    if days % 4 != 0 { return nil }
                }
                let fire = nextWorkStart(after: now)
                return (.dormant3d, fire)
            }
        } else {
            // brand-new user: soft nudge next morning 8:00
            let cal = Calendar.current
            let start = cal.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
            let fire = start > now ? start : cal.date(byAdding: .day, value: 1, to: start)!
            return (.dormant3d, fire)
        }
        return nil
    }
    
    private func nextHabitReminderDate(after now: Date, country: String) -> Date? {
        let windows = habit.topWindows(limit: 2)
        guard !windows.isEmpty else { return nil }
        
        // Adjust windows during Ramadan: allow shifts (±45min) and reduce dormant pressure handled elsewhere
        let ramadan = SEARamadanProvider.isDuringRamadan(now, country: country)
        let offsetMinutes = ramadan ? 30 : 15
        
        let limited = (state.downgradeUntil != nil && Date() < (state.downgradeUntil!))
        let iter = limited ? windows.prefix(1) : windows[0..<windows.count]
        for (startMin, _) in iter {
            // candidate today at (start + offset)
            let cal = Calendar.current
            var fire = cal.date(bySettingHour: startMin / 60, minute: startMin % 60, second: 0, of: now) ?? now
            fire = fire.adding(minutes: offsetMinutes)
            if fire < now {
                // if passed today, consider tomorrow same time
                fire = cal.date(byAdding: .day, value: 1, to: fire) ?? fire
            }
            // If user already shot today before fire, skip
            if let last = state.lastPhotoAt, cal.isDate(last, inSameDayAs: fire) {
                continue
            }
            return fire
        }
        return nil
    }
    
    private func nextWorkStart(after now: Date) -> Date {
        let cal = Calendar.current
        // Choose 08:00 local as baseline
        let base = cal.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now
        return base > now ? base : cal.date(byAdding: .day, value: 1, to: base)!
    }
    
    private func schedule(kind: SEAReminderKind, at fireDate: Date, now: Date) {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        // 设置小红点数量为1
        content.badge = 1
        
        switch kind {
        case .habit:
            content.title = "" // keep title minimal
            content.body = "k_notification_habit".localized()
        case .dormant3d:
            content.title = ""
            content.body = "k_notification_dormant3d".localized()
        case .dormant7d:
            content.title = ""
            content.body = "k_notification_dormant7d".localized()
        case .dormant30d:
            content.title = ""
            content.body = "k_notification_dormant30d".localized()
        case .restart:
            content.title = ""
            content.body = "k_notification_restart".localized()
        case .summary:
            content.title = ""
            content.body = "k_notification_summary".localized()
        }
        
        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        
        let id = dailyIdentifier + "." + Self.dateKey(fireDate) + "." + kind.rawValue
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        center.add(req) { [weak self] err in
            if err == nil {
                self?.state.lastScheduledAt = Date()
                self?.state.lastScheduledKind = kind
                self?.persist()
            }
        }
    }
}

/// AppDelegate glue code helpers
extension UNUserNotificationCenter {
    /// Must be called once in AppDelegate to forward tap events to strategy
    func sea_registerDelegateForwarder() {
        self.delegate = SEANotificationDelegateProxy.shared
    }
}

final class SEANotificationDelegateProxy: NSObject, UNUserNotificationCenterDelegate {
    static let shared = SEANotificationDelegateProxy()
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        SEANotificationStrategy.shared.onNotificationTapped()
        GPFirebaseManager.logEvent(event: "click_notification")
        completionHandler()
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([])
    }
}
