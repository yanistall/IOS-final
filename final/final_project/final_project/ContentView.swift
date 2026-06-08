//
//  ContentView.swift
//  final_project
//
//  Created by tsen on 2026/6/8.
//

import SwiftUI

struct DecisionOption: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var notes: String
}

struct DecisionFactor: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var weight: Double
}

struct OptionScore: Identifiable {
    let id = UUID()
    let option: DecisionOption
    let score: Int
    let strengths: [String]
    let cautions: [String]
}

struct DecisionResult {
    let scores: [OptionScore]
    let recommendation: OptionScore?
    let summary: String
}

struct DecisionHistoryItem: Identifiable {
    let id = UUID()
    let question: String
    let category: String
    let recommendation: String
    let score: Int
    let createdAt: Date
}

private enum AppPalette {
    static let sage = Color(red: 0.36, green: 0.61, blue: 0.54)
    static let moss = Color(red: 0.20, green: 0.39, blue: 0.35)
    static let coral = Color(red: 0.89, green: 0.48, blue: 0.42)
    static let lavender = Color(red: 0.55, green: 0.49, blue: 0.78)
    static let sky = Color(red: 0.56, green: 0.73, blue: 0.88)
    static let ink = Color(red: 0.13, green: 0.18, blue: 0.20)
    static let softText = Color(red: 0.38, green: 0.43, blue: 0.45)
}

struct ContentView: View {
    private static let positiveWords: [String] = ["喜歡", "想要", "適合", "成長", "穩定", "自由", "方便", "便宜", "省錢", "划算", "高薪", "近", "安全", "有趣", "值得", "機會", "健康", "營養", "清爽", "飽", "好吃", "快速", "實用", "耐用"]
    private static let negativeWords: [String] = ["怕", "擔心", "風險", "貴", "遠", "累", "壓力", "不確定", "麻煩", "浪費", "後悔", "低薪", "不喜歡", "困難", "油", "太甜", "不健康", "負擔", "衝動", "用不到"]
    private static let healthWords: [String] = ["健康", "營養", "清淡", "蔬菜", "蛋白質", "低糖", "少油", "新鮮", "均衡"]
    private static let moneyWords: [String] = ["便宜", "省錢", "划算", "預算", "折扣", "免費", "值得", "耐用"]

    @State private var question = ""
    @State private var hesitation = ""
    @State private var options: [DecisionOption] = [
        DecisionOption(name: "", notes: ""),
        DecisionOption(name: "", notes: "")
    ]
    @State private var factors: [DecisionFactor] = [
        DecisionFactor(name: "健康", weight: 4),
        DecisionFactor(name: "金錢", weight: 4),
        DecisionFactor(name: "時間", weight: 3),
        DecisionFactor(name: "心情", weight: 3),
        DecisionFactor(name: "長期影響", weight: 3)
    ]
    @State private var history: [DecisionHistoryItem] = []
    @State private var result: DecisionResult?
    @State private var showMissingInput = false
    @State private var showReport = false

    var body: some View {
        NavigationStack {
            ZStack {
                HealingBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        headerView
                        questionSection
                        optionSection
                        factorSection
                        analyzeButton
                        resultSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("決策分析")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showReport = true
                    } label: {
                        Label("報表", systemImage: "doc.text.magnifyingglass")
                    }
                    .foregroundStyle(AppPalette.moss)
                }
            }
            .sheet(isPresented: $showReport) {
                ReportView(history: history)
            }
            .alert("請至少輸入兩個選項", isPresented: $showMissingInput) {
                Button("知道了", role: .cancel) { }
            } message: {
                Text("每個選項都需要名稱，才能進行比較與評分。")
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .font(.headline)
                    .foregroundStyle(AppPalette.sage)
                    .frame(width: 34, height: 34)
                    .background(.white.opacity(0.72), in: Circle())

                Text("選擇困難助手")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.moss)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("大事小事，都能慢慢選")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("早餐、晚餐、購物或人生方向都可以輸入。我會幫你整理健康、金錢、時間和心情等重點，找出目前最適合的選擇。")
                    .font(.body)
                    .foregroundStyle(AppPalette.softText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("你的決策", icon: "questionmark.circle.fill", color: AppPalette.lavender)

            TextField("例如：早餐吃什麼？晚餐吃什麼？要買哪一個？", text: $question, axis: .vertical)
                .textFieldStyle(SoftTextFieldStyle())
                .lineLimit(2...4)

            TextField("你猶豫的部分，例如：想吃飽但怕不健康、想省錢但又想買好一點", text: $hesitation, axis: .vertical)
                .textFieldStyle(SoftTextFieldStyle())
                .lineLimit(3...6)
        }
        .modifier(PanelStyle())
    }

    private var optionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("選項", icon: "square.stack.3d.up.fill", color: AppPalette.sky)

                Spacer()

                Button {
                    options.append(DecisionOption(name: "", notes: ""))
                } label: {
                    Label("新增", systemImage: "plus")
                }
                .buttonStyle(SoftButtonStyle(tint: AppPalette.sage))
            }

            ForEach($options) { $option in
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 10) {
                        TextField("選項名稱，例如：飯糰、沙拉、耳機 A", text: $option.name)
                            .textFieldStyle(SoftTextFieldStyle())

                        if options.count > 2 {
                            Button(role: .destructive) {
                                options.removeAll { $0.id == option.id }
                            } label: {
                                Image(systemName: "trash")
                                    .frame(width: 34, height: 34)
                            }
                            .buttonStyle(QuietIconButtonStyle())
                            .accessibilityLabel("刪除選項")
                        }
                    }

                    TextField("補充：價格、健康程度、方便度、喜不喜歡、會不會後悔", text: $option.notes, axis: .vertical)
                        .textFieldStyle(SoftTextFieldStyle())
                        .lineLimit(2...5)
                }

                if option.id != options.last?.id {
                    Divider()
                        .overlay(AppPalette.sage.opacity(0.16))
                }
            }
        }
        .modifier(PanelStyle())
    }

    private var factorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("在意因素", icon: "slider.horizontal.3", color: AppPalette.coral)

                Spacer()

                Button {
                    factors.append(DecisionFactor(name: "", weight: 3))
                } label: {
                    Label("新增", systemImage: "plus")
                }
                .buttonStyle(SoftButtonStyle(tint: AppPalette.coral))
            }

            ForEach($factors) { $factor in
                VStack(alignment: .leading, spacing: 9) {
                    HStack(spacing: 10) {
                        TextField("因素名稱", text: $factor.name)
                            .textFieldStyle(SoftTextFieldStyle())

                        Button(role: .destructive) {
                            factors.removeAll { $0.id == factor.id }
                        } label: {
                            Image(systemName: "minus.circle")
                                .frame(width: 34, height: 34)
                        }
                        .buttonStyle(QuietIconButtonStyle())
                        .accessibilityLabel("刪除因素")
                    }

                    HStack(spacing: 12) {
                        Text("重要度")
                            .font(.subheadline)
                            .foregroundStyle(AppPalette.softText)

                        Slider(value: $factor.weight, in: 1...5, step: 1)
                            .tint(AppPalette.sage)

                        Text("\(Int(factor.weight))")
                            .font(.subheadline.monospacedDigit().weight(.bold))
                            .foregroundStyle(AppPalette.moss)
                            .frame(width: 26)
                    }
                }

                if factor.id != factors.last?.id {
                    Divider()
                        .overlay(AppPalette.coral.opacity(0.14))
                }
            }
        }
        .modifier(PanelStyle())
    }

    private var analyzeButton: some View {
        Button {
            analyzeDecision()
        } label: {
            Label("開始分析", systemImage: "wand.and.stars")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppPalette.moss)
        .controlSize(.large)
    }

    @ViewBuilder
    private var resultSection: some View {
        if let result {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("分析結果", icon: "chart.bar.xaxis", color: AppPalette.sage)

                if let recommendation = result.recommendation {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("推薦選擇", systemImage: "heart.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppPalette.coral)

                        HStack(alignment: .center, spacing: 12) {
                            Text(recommendation.option.name)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(AppPalette.ink)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()

                            ScoreBadge(score: recommendation.score)
                        }

                        Text(result.summary)
                            .font(.body)
                            .foregroundStyle(AppPalette.softText)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(15)
                    .background(
                        LinearGradient(
                            colors: [AppPalette.sage.opacity(0.18), AppPalette.sky.opacity(0.16), .white.opacity(0.76)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.65), lineWidth: 1)
                    )
                }

                ForEach(result.scores) { score in
                    ScoreRow(score: score)
                }
            }
            .modifier(PanelStyle())
        }
    }

    private func sectionTitle(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.13), in: Circle())

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.ink)
        }
    }

    private func analyzeDecision() {
        let validOptions = options.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard validOptions.count >= 2 else {
            showMissingInput = true
            return
        }

        let activeFactors = factors.filter { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let scores = validOptions.map { option in
            score(option: option, factors: activeFactors)
        }
        .sorted { $0.score > $1.score }

        let top = scores.first
        let runnerUp = scores.dropFirst().first
        let category = categoryForCurrentQuestion()
        let summary: String

        if let top, let runnerUp, top.score - runnerUp.score <= 6 {
            summary = "最高分與第二名接近，代表這題很看當下狀態。建議先選 \(top.option.name)，但把你最在意的條件再確認一次。"
        } else if let top {
            summary = summaryFor(category: category, recommendation: top.option.name)
        } else {
            summary = "請補上更多選項內容，分析會更準確。"
        }

        result = DecisionResult(scores: scores, recommendation: top, summary: summary)

        if let top {
            let title = question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未命名決策" : question
            history.insert(
                DecisionHistoryItem(
                    question: title,
                    category: category,
                    recommendation: top.option.name,
                    score: top.score,
                    createdAt: Date()
                ),
                at: 0
            )
        }
    }

    private func score(option: DecisionOption, factors: [DecisionFactor]) -> OptionScore {
        let text = "\(option.name) \(option.notes)".lowercased()
        let hesitationText = hesitation.lowercased()
        var rawScore = 55.0
        var strengths: [String] = []
        var cautions: [String] = []

        for factor in factors {
            let name = factor.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let normalizedName = name.lowercased()
            let weight = factor.weight

            if text.contains(normalizedName) {
                rawScore += weight * 4
                strengths.append("符合你重視的「\(name)」")
            }

            if normalizedName.contains("健康") {
                let matches = Self.healthWords.filter { text.contains($0) }
                if !matches.isEmpty {
                    rawScore += weight * 3
                    strengths.append("健康面有加分：\(matches.prefix(2).joined(separator: "、"))")
                }
                if text.contains("油") || text.contains("太甜") || text.contains("不健康") {
                    rawScore -= weight * 3
                    cautions.append("健康面可能不是最理想")
                }
            }

            if normalizedName.contains("金錢") || normalizedName.contains("錢") || normalizedName.contains("成本") || normalizedName.contains("價格") {
                let matches = Self.moneyWords.filter { text.contains($0) }
                if !matches.isEmpty {
                    rawScore += weight * 3
                    strengths.append("金錢面有加分：\(matches.prefix(2).joined(separator: "、"))")
                }
                if text.contains("貴") || text.contains("超預算") || text.contains("衝動") {
                    rawScore -= weight * 3
                    cautions.append("金錢面需要再確認是否值得")
                }
            }
        }

        for word in Self.positiveWords where text.contains(word) {
            rawScore += 4
        }

        for word in Self.negativeWords where text.contains(word) {
            rawScore -= 5
            cautions.append("提到「\(word)」，需要先確認是否能接受")
        }

        if !hesitationText.isEmpty {
            let overlap = hesitationText
                .components(separatedBy: CharacterSet(charactersIn: " ，,。.!！?？\n"))
                .filter { $0.count >= 2 && text.contains($0) }

            if overlap.isEmpty {
                rawScore += 5
                strengths.append("較少碰到你目前寫下的猶豫點")
            } else {
                rawScore -= Double(overlap.count * 4)
                cautions.append("和你的猶豫內容有重疊：\(overlap.prefix(3).joined(separator: "、"))")
            }
        }

        if option.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            rawScore -= 8
            cautions.append("資訊不足，分數保守估計")
        }

        if strengths.isEmpty {
            strengths.append("沒有明顯扣分項，適合作為可行選項保留")
        }

        if cautions.isEmpty {
            cautions.append("目前沒有明顯風險，但仍建議補充成本與後果")
        }

        let finalScore = min(100, max(0, Int(rawScore.rounded())))
        return OptionScore(option: option, score: finalScore, strengths: Array(unique(strengths).prefix(3)), cautions: Array(unique(cautions).prefix(3)))
    }

    private func categoryForCurrentQuestion() -> String {
        let text = "\(question) \(hesitation)".lowercased()

        if text.contains("早餐") || text.contains("早上") {
            return "早餐"
        }

        if text.contains("晚餐") || text.contains("宵夜") || text.contains("午餐") || text.contains("吃什麼") || text.contains("餐") {
            return "飲食"
        }

        if text.contains("買") || text.contains("購物") || text.contains("商品") || text.contains("要不要入手") {
            return "購物"
        }

        if text.contains("工作") || text.contains("職涯") || text.contains("薪水") || text.contains("公司") {
            return "工作"
        }

        if text.contains("旅行") || text.contains("旅遊") || text.contains("去哪") {
            return "旅行"
        }

        return "生活"
    }

    private func summaryFor(category: String, recommendation: String) -> String {
        switch category {
        case "早餐":
            return "今天早餐建議選 \(recommendation)。它在健康、金錢和方便度之間比較平衡，適合作為不用想太久的早晨選擇。"
        case "飲食":
            return "這餐建議選 \(recommendation)。它比較能兼顧你現在的食慾、負擔和實際條件。"
        case "購物":
            return "購物上建議選 \(recommendation)。它目前看起來比較符合預算與實用性，也比較不容易變成衝動消費。"
        case "工作":
            return "\(recommendation) 在目前資訊下最符合你的重點。它的整體風險較可控，也更能回應你列出的猶豫點。"
        default:
            return "\(recommendation) 在目前資訊下最符合你的重點。它能比較好地平衡你的在意因素和猶豫點。"
        }
    }

    private func unique(_ items: [String]) -> [String] {
        var seen: Set<String> = []
        return items.filter { seen.insert($0).inserted }
    }
}

struct ReportView: View {
    let history: [DecisionHistoryItem]
    @Environment(\.dismiss) private var dismiss

    private var groupedHistory: [(category: String, items: [DecisionHistoryItem])] {
        let order = ["早餐", "飲食", "購物", "工作", "旅行", "生活"]
        let grouped = Dictionary(grouping: history, by: { $0.category })

        return order.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HealingBackground()

                if history.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(AppPalette.sage)

                        Text("還沒有分析紀錄")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppPalette.ink)

                        Text("完成一次分析後，這裡會依早餐、飲食、購物、工作等類別統整你問過的問題。")
                            .font(.body)
                            .foregroundStyle(AppPalette.softText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            reportSummary

                            ForEach(groupedHistory, id: \.category) { group in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Label(group.category, systemImage: icon(for: group.category))
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(AppPalette.ink)

                                        Spacer()

                                        Text("\(group.items.count) 次")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(AppPalette.moss)
                                    }

                                    ForEach(group.items) { item in
                                        HistoryRow(item: item)
                                    }
                                }
                                .modifier(PanelStyle())
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("問題報表")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundStyle(AppPalette.moss)
                }
            }
        }
    }

    private var reportSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("你問過 \(history.count) 個問題")
                .font(.title2.weight(.bold))
                .foregroundStyle(AppPalette.ink)

            Text("目前最常出現的是「\(mostCommonCategory)」。這份報表可以幫你看見自己最近最常卡住的生活情境。")
                .font(.body)
                .foregroundStyle(AppPalette.softText)
                .lineSpacing(3)
        }
        .modifier(PanelStyle())
    }

    private var mostCommonCategory: String {
        Dictionary(grouping: history, by: { $0.category })
            .max { $0.value.count < $1.value.count }?
            .key ?? "生活"
    }

    private func icon(for category: String) -> String {
        switch category {
        case "早餐":
            return "sunrise.fill"
        case "飲食":
            return "fork.knife"
        case "購物":
            return "bag.fill"
        case "工作":
            return "briefcase.fill"
        case "旅行":
            return "map.fill"
        default:
            return "sparkles"
        }
    }
}

struct HistoryRow: View {
    let item: DecisionHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(item.question)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Text("\(item.score)分")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppPalette.sage, in: Capsule())
            }

            Text("推薦：\(item.recommendation)")
                .font(.footnote)
                .foregroundStyle(AppPalette.moss)

            Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(AppPalette.softText)
        }
        .padding(12)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct HealingBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.91, green: 0.96, blue: 0.94),
                Color(red: 0.95, green: 0.94, blue: 0.99),
                Color(red: 0.98, green: 0.93, blue: 0.91)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct ScoreBadge: View {
    let score: Int

    var body: some View {
        Text("\(score)分")
            .font(.headline.monospacedDigit().weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(scoreColor, in: Capsule())
            .shadow(color: scoreColor.opacity(0.24), radius: 8, x: 0, y: 4)
    }

    private var scoreColor: Color {
        switch score {
        case 80...100:
            return AppPalette.sage
        case 60..<80:
            return AppPalette.sky
        case 40..<60:
            return AppPalette.coral
        default:
            return .red.opacity(0.82)
        }
    }
}

struct ScoreRow: View {
    let score: OptionScore

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .center, spacing: 12) {
                Text(score.option.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                ScoreBadge(score: score.score)
            }

            ProgressView(value: Double(score.score), total: 100)
                .tint(AppPalette.sage)

            VStack(alignment: .leading, spacing: 6) {
                Text("加分原因")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.moss)
                ForEach(score.strengths, id: \.self) { item in
                    Label(item, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AppPalette.sage)
                }
            }
            .font(.footnote)

            VStack(alignment: .leading, spacing: 6) {
                Text("需要注意")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppPalette.coral)
                ForEach(score.cautions, id: \.self) { item in
                    Label(item, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppPalette.coral)
                }
            }
            .font(.footnote)
        }
        .padding(14)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
    }
}

struct PanelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.82), lineWidth: 1)
            )
            .shadow(color: AppPalette.moss.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

struct SoftTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundStyle(AppPalette.ink)
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppPalette.sage.opacity(0.18), lineWidth: 1)
            )
    }
}

struct SoftButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(tint.opacity(configuration.isPressed ? 0.18 : 0.12), in: Capsule())
    }
}

struct QuietIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(AppPalette.coral)
            .background(AppPalette.coral.opacity(configuration.isPressed ? 0.16 : 0.10), in: Circle())
    }
}

#Preview {
    ContentView()
}
