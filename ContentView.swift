//
//  ContentView.swift
//  SilentSMS
//
//  Created by Mustafa on 2/7/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var logic = FilterLogic.shared
    @State private var selection = 0
    
    init() {
        // TabBar görünümünü özelleştir
        UITabBar.appearance().backgroundColor = UIColor.systemBackground
    }
    
    var body: some View {
        TabView(selection: $selection) {
            DashboardView(logic: logic)
                .tabItem {
                    Label("Genel Bakış", systemImage: "chart.bar.fill")
                }
                .tag(0)
            
            RulesView(logic: logic, type: .blocked)
                .tabItem {
                    Label("Engellenenler", systemImage: "hand.raised.fill")
                }
                .tag(1)
                
            RulesView(logic: logic, type: .allowed)
                .tabItem {
                    Label("İzinliler", systemImage: "checkmark.shield.fill")
                }
                .tag(2)
            
            TestView(logic: logic)
                .tabItem {
                    Label("Test Et", systemImage: "flask.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @ObservedObject var logic: FilterLogic
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SilentSMS Aktif")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("Siz keyfinize bakın, spam mesajlar otomatik olarak filtreleniyor.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Engellenen", value: "\(logic.totalBlockedCount)", icon: "shield.slash.fill", color: .red)
                        StatCard(title: "Son Engelleme", value: timeAgoDisplay(), icon: "clock.fill", color: .orange)
                        StatCard(title: "Yasaklı Kelime", value: "\(logic.blockedKeywords.count)", icon: "list.bullet", color: .blue)
                        StatCard(title: "İzinli Kelime", value: "\(logic.allowedKeywords.count)", icon: "checkmark.circle", color: .green)
                    }
                    .padding(.horizontal)
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Engellenen Mesajlar Nerede?")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            Text("Engellenen mesajlar silinmez. iPhone'unuzun **Mesajlar** uygulamasında **'Bilinmeyen ve İstenmeyen'** sekmesi altında saklanır.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Durum Merkezi")
        }
    }
    
    func timeAgoDisplay() -> String {
        guard let date = logic.lastBlockedDate else { return "-" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Rules View (Shared for Blocked & Allowed)
struct RulesView: View {
    @ObservedObject var logic: FilterLogic
    let type: RuleType
    @State private var newKeyword = ""
    
    enum RuleType {
        case blocked, allowed
        
        var title: String { return self == .blocked ? "Engellenenler" : "İzin Verilenler" }
        var color: Color { return self == .blocked ? .red : .green }
        var icon: String { return self == .blocked ? "hand.raised.fill" : "checkmark.shield.fill" }
        var placeholder: String { return self == .blocked ? "Örn: Bahis, Casino" : "Örn: Banka, Kargo" }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Add New Input
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField(type.placeholder, text: $newKeyword)
                    
                    Button(action: addRule) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(type.color)
                    }
                    .disabled(newKeyword.isEmpty)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                .padding()
                
                // List
                List {
                    let keywords = type == .blocked ? logic.blockedKeywords : logic.allowedKeywords
                    if keywords.isEmpty {
                        Text("Henüz kural eklenmemiş.")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(keywords, id: \.self) { keyword in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(keyword)
                                    .font(.body)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteRule)
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle(type.title)
        }
    }
    
    func addRule() {
        if type == .blocked {
            logic.addKeyword(newKeyword, to: &logic.blockedKeywords)
        } else {
            logic.addKeyword(newKeyword, to: &logic.allowedKeywords)
        }
        newKeyword = ""
    }
    
    func deleteRule(offsets: IndexSet) {
        offsets.forEach { index in
            if type == .blocked {
                logic.removeKeyword(logic.blockedKeywords[index], from: &logic.blockedKeywords)
            } else {
                logic.removeKeyword(logic.allowedKeywords[index], from: &logic.allowedKeywords)
            }
        }
    }
}

// MARK: - Test View
struct TestView: View {
    @ObservedObject var logic: FilterLogic
    @State private var sender = ""
    @State private var bodyText = ""
    @State private var resultMessage: String?
    @State private var resultColor: Color = .gray
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Simülasyon")) {
                    TextField("Gönderen (Opsiyonel)", text: $sender)
                    ZStack(alignment: .topLeading) {
                        if bodyText.isEmpty {
                            Text("Mesaj içeriğini buraya yazın...")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $bodyText)
                            .frame(minHeight: 100)
                    }
                }
                
                Section {
                    Button(action: runTest) {
                        HStack {
                            Spacer()
                            Text("Filtreyi Test Et")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color.blue)
                }
                
                if let message = resultMessage {
                    Section(header: Text("Sonuç")) {
                        HStack {
                            Spacer()
                            Text(message)
                                .font(.headline)
                                .foregroundColor(resultColor)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Filtre Testi")
        }
    }
    
    func runTest() {
        let action = logic.checkMessage(body: bodyText, sender: sender)
        
        switch action {
        case .junk:
            resultMessage = "⛔️ ENGELLENDİ\n(Junk Klasörüne Gider)"
            resultColor = .red
        case .allow:
            resultMessage = "✅ İZİN VERİLDİ\n(Gelen Kutusuna Düşer)"
            resultColor = .green
        case .none:
            resultMessage = "⚪️ NÖTR\n(Gelen Kutusuna Düşer)"
            resultColor = .gray
        default:
            break
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
