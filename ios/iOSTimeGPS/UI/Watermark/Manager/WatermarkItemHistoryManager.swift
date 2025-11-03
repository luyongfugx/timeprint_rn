//
//  WatermarkItemHistoryManager.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/5/13.
//

class WatermarkItemHistoryManager {
    
    // MARK: - Storage Helpers
    static func loadHistory(for entryId: String, type: WatermarkHistoryType) -> [WatermarkHistoryItem] {
        let key = "WatermarkHistory_\(entryId)_\(type.rawValue)"
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([WatermarkHistoryItem].self, from: data)
        } catch {
            print("Failed to decode history: \(error)")
            return []
        }
    }
    
    static func saveHistory(_ history: [WatermarkHistoryItem], for entryId: String, type: WatermarkHistoryType) {
        let key = "WatermarkHistory_\(entryId)_\(type.rawValue)"
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(history)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Failed to encode history: \(error)")
        }
    }
    
}
