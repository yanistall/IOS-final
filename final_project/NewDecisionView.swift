// MARK: - NewDecisionView.swift
import SwiftUI
import SwiftData

// MARK: - Draft Models (local, not persisted)

struct DraftCriterion: Identifiable {
    var id = UUID()
    var name: String
    var weight: Double
}

struct DraftOption: Identifiable {
    var id = UUID()
    var name: String
    var scores: [UUID: Double] = [:]

    func score(for criterionId: UUID) -> Double {
        scores[criterionId] ?? 50
    }

    func weightedTotal(criteria: [DraftCriterion]) -> Double {
        let totalWeight = criteria.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        return criteria.reduce(0.0) { acc, c in
            acc + score(for: c.id) * c.weight
        } / totalWeight
    }
}

// MARK: - NewDecisionView

struct NewDecisionView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var question = ""
    @State private var criteria: [DraftCriterion] = [
        DraftCriterion(name: "價格", weight: 3),
        DraftCriterion(name: "距離", weight: 3),
        DraftCriterion(name: "口味", weight: 4)
    ]
    @State private var options: [DraftOption] = [
        DraftOption(name: ""),
        DraftOption(name: "")
    ]
    @State private var showSavedAlert = false

    private var rankedOptions: [(DraftOption, Double)] {
        options
            .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { ($0, $0.weightedTotal(criteria: criteria)) }
            .sorted { $0.1 > $1.1 }
    }

    private var canSave: Bool {
        !question.trimmingCharacters(in: .whitespaces).isEmpty && rankedOptions.count >= 2
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    questionSection
                    criteriaSection
                    optionsSection
                    if rankedOptions.count >= 2 {
                        resultSection
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .navigationTitle("新決策")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .alert("已儲存", isPresented: $showSavedAlert) {
                Button("確定", role: .cancel) {}
            } message: {
                Text("決策已加入歷史紀錄。")
            }
        }
    }

    // MARK: - Question Section

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("決策題目", systemImage: "questionmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.cyan)
            TextField("例如：晚餐吃什麼？", text: $question, axis: .vertical)
                .lineLimit(1...3)
                .padding(12)
                .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
        .cardStyle()
    }

    // MARK: - Criteria Section

    private var criteriaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("評分準則", systemImage: "slider.horizontal.3")
                    .font(.headline)
                    .foregroundStyle(.orange)
                Spacer()
                Button {
                    withAnimation {
                        criteria.append(DraftCriterion(name: "", weight: 3))
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.orange)
                        .imageScale(.large)
                }
            }
            ForEach($criteria) { $c in
                CriterionRow(criterion: $c, canDelete: criteria.count > 1) {
                    withAnimation { criteria.removeAll { $0.id == c.id } }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("選項", systemImage: "list.bullet.rectangle.portrait.fill")
                    .font(.headline)
                    .foregroundStyle(.purple)
                Spacer()
                Button {
                    withAnimation {
                        options.append(DraftOption(name: ""))
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.purple)
                        .imageScale(.large)
                }
            }
            ForEach($options) { $opt in
                OptionEntryRow(
                    option: $opt,
                    criteria: criteria,
                    canDelete: options.count > 2
                ) {
                    withAnimation { options.removeAll { $0.id == opt.id } }
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Result Section

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("推薦結果", systemImage: "star.fill")
                .font(.headline)
                .foregroundStyle(.yellow)

            if let (top, topScore) = rankedOptions.first {
                VStack(spacing: 6) {
                    Text(top.name)
                        .font(.largeTitle.weight(.bold))
                    Text(String(format: "加權得分 %.1f", topScore))
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.yellow)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    LinearGradient(
                        colors: [.yellow.opacity(0.25), .orange.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.yellow.opacity(0.35), lineWidth: 1))
            }

            ForEach(rankedOptions, id: \.0.id) { opt, score in
                HStack(spacing: 12) {
                    Text(opt.name)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    ProgressView(value: score, total: 100)
                        .tint(.cyan)
                        .frame(width: 80)
                    Text(String(format: "%.1f", score))
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .foregroundStyle(.cyan)
                        .frame(width: 44, alignment: .trailing)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Save

    private func save() {
        guard canSave, let (top, topScore) = rankedOptions.first else { return }

        let decision = Decision(
            question: question.trimmingCharacters(in: .whitespaces),
            recommendedOption: top.name,
            recommendedScore: topScore
        )
        decision.criteria = criteria.map {
            Criterion(name: $0.name.isEmpty ? "未命名" : $0.name, weight: $0.weight)
        }
        decision.options = options
            .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { draft -> DecisionOption in
                let opt = DecisionOption(name: draft.name)
                opt.scores = criteria.map { c in
                    OptionScore(
                        criterionName: c.name.isEmpty ? "未命名" : c.name,
                        score: draft.score(for: c.id)
                    )
                }
                return opt
            }

        modelContext.insert(decision)
        resetForm()
        showSavedAlert = true
    }

    private func resetForm() {
        question = ""
        criteria = [
            DraftCriterion(name: "價格", weight: 3),
            DraftCriterion(name: "距離", weight: 3),
            DraftCriterion(name: "口味", weight: 4)
        ]
        options = [DraftOption(name: ""), DraftOption(name: "")]
    }
}

// MARK: - CriterionRow

struct CriterionRow: View {
    @Binding var criterion: DraftCriterion
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField("準則名稱", text: $criterion.name)
                    .padding(10)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                if canDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red.opacity(0.7))
                            .imageScale(.large)
                    }
                }
            }
            HStack(spacing: 10) {
                Text("重要度")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)
                Slider(value: $criterion.weight, in: 1...5, step: 1)
                    .tint(.orange)
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { i in
                        Circle()
                            .fill(i <= Int(criterion.weight) ? Color.orange : Color.white.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                }
                Text("\(Int(criterion.weight))")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(.orange)
                    .frame(width: 20)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - OptionEntryRow

struct OptionEntryRow: View {
    @Binding var option: DraftOption
    let criteria: [DraftCriterion]
    let canDelete: Bool
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TextField("選項名稱", text: $option.name)
                    .font(.headline)
                    .padding(10)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                if canDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red.opacity(0.7))
                            .imageScale(.large)
                    }
                }
            }

            if !criteria.isEmpty {
                VStack(spacing: 6) {
                    ForEach(criteria) { c in
                        HStack(spacing: 10) {
                            Text(c.name.isEmpty ? "（未命名）" : c.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 56, alignment: .leading)
                                .lineLimit(1)

                            Slider(
                                value: Binding(
                                    get: { option.scores[c.id] ?? 50 },
                                    set: { newVal in
                                        var copy = option
                                        copy.scores[c.id] = newVal
                                        option = copy
                                    }
                                ),
                                in: 0...100,
                                step: 1
                            )
                            .tint(.purple)

                            Text(String(format: "%.0f", option.scores[c.id] ?? 50))
                                .font(.caption.monospacedDigit().weight(.bold))
                                .foregroundStyle(.purple)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }
}
