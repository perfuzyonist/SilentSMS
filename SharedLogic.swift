//
//  SharedLogic.swift
//  SilentSMS
//
//  Created by Mustafa on 2/7/26.
//

import Foundation
import IdentityLookup

class FilterLogic: ObservableObject {
    static let shared = FilterLogic()
    
    // ÖNEMLİ: App Group ID'nizi buraya yazmalısınız.
    // Xcode'da: Project > Targets > Signing & Capabilities > + > App Groups
    private let suiteName = "group.com.mustafa.SilentSMS"
    
    @Published var blockedKeywords: [String] = []
    @Published var allowedKeywords: [String] = []
    @Published var totalBlockedCount: Int = 0
    @Published var lastBlockedDate: Date?
    
    private var userDefaults: UserDefaults? {
        return UserDefaults(suiteName: suiteName)
    }
    
    init() {
        loadRules()
    }
    
    func loadRules() {
        if let blocked = userDefaults?.array(forKey: "blockedKeywords") as? [String] {
            self.blockedKeywords = blocked
        } else {
            self.blockedKeywords = ["bahis", "casino", "bonus", "bet", "freespin", "iddaa", "slot"]
        }
        
        if let allowed = userDefaults?.array(forKey: "allowedKeywords") as? [String] {
            self.allowedKeywords = allowed
        } else {
            self.allowedKeywords = ["banka", "kargo", "onay", "şifre", "doğrulama"]
        }
        
        // İstatistikleri yükle
        self.totalBlockedCount = userDefaults?.integer(forKey: "totalBlockedCount") ?? 0
        if let date = userDefaults?.object(forKey: "lastBlockedDate") as? Date {
            self.lastBlockedDate = date
        }
        
        // Eğer ilk kez açılıyorsa kaydet
        if userDefaults?.object(forKey: "blockedKeywords") == nil {
            saveRules()
        }
    }
    
    func addKeyword(_ keyword: String, to list: inout [String]) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !list.contains(trimmed) {
            list.append(trimmed)
            saveRules()
        }
    }
    
    func removeKeyword(_ keyword: String, from list: inout [String]) {
        if let index = list.firstIndex(of: keyword) {
            list.remove(at: index)
            saveRules()
        }
    }
    
    private func saveRules() {
        userDefaults?.set(blockedKeywords, forKey: "blockedKeywords")
        userDefaults?.set(allowedKeywords, forKey: "allowedKeywords")
        // Note: Stats are saved immediately in their specific functions
    }
    
    func incrementBlockedCount() {
        // Main thread'de yayınlamak için (UI updates)
        DispatchQueue.main.async {
            self.totalBlockedCount += 1
            self.lastBlockedDate = Date()
        }
        
        // Extension veya arka plandan statik erişim için directe yaz
        let currentCount = userDefaults?.integer(forKey: "totalBlockedCount") ?? 0
        userDefaults?.set(currentCount + 1, forKey: "totalBlockedCount")
        userDefaults?.set(Date(), forKey: "lastBlockedDate")
    }
    
    // Core Filter Logic - Extension tarafından çağrılır
    func checkMessage(body: String?, sender: String?) -> ILMessageFilterAction {
        guard let body = body?.lowercased() else { return .none }
        let sender = sender?.lowercased() ?? ""
        
        // 1. Önce İZİN VERİLENLERİ kontrol et (Whitelist Priority)
        // Eğer mesaj içinde "banka", "onay kodu" gibi kritik kelimeler varsa ASLA engelleme.
        for allowed in allowedKeywords {
            if body.contains(allowed.lowercased()) || sender.contains(allowed.lowercased()) {
                return .allow
            }
        }
        
        // 2. Sonra YASAKLI KELİMELERİ kontrol et
        for blocked in blockedKeywords {
            if body.contains(blocked.lowercased()) || sender.contains(blocked.lowercased()) {
                return .junk
            }
        }
        
        // 3. Hiçbir kurala uymuyorsa izin ver
        return .none
    }
}
