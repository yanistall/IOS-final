// MARK: - HistoryView.swift
import SwiftUI
import SwiftData

// MARK: - HistoryView

struct HistoryView: View {
    @Query(sort: \Decision.date, order: .reverse) private var decisions: [Decision]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if decisions.isEmpty {
                    ContentUnavailableView {
                        Label("還沒有決策紀錄", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("在「新決策」頁完成分析並儲存後，\n會在這裡看到歷史。")
                    }
                } else {
                    List {
                        ForEach(decisions) { decision in
                            NavigationLink {
                                DecisionDetailView(decision: decision)
                            } label: {
                                DecisionRowView(decision: decision)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("歷史紀錄")
            .toolbar {
                if !decisions.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(decisions[i]) }
    }
}

// MARK: - DecisionRowView

struct DecisionRowView: View {
    let decision: Decision

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(decision.question)
                .font(.headline)
                .lineLimit(2)
            HStack {
                Label(decision.recommendedOption, systemImage: "crown.fill")
                    .font(.subheadline)
                    .foregroundStyle(.yellow)
                    .lineLimit(1)
                Spacer()
                Text(String(format: "%.1f 分", decision.recommendedScore))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.cyan)
            }
            Text(decision.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - DecisionDetailView

struct DecisionDetailView: View {
    let decision: Decision

    private var rankedOptions: [(DecisionOption, Double)] {
        decision.options
            .map { ($0, weightedTotal(option: $0)) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let (winner, score) = rankedOptions.first {
                    winnerCard(name: winner.name, score: score)
                }
                if !decision.criteria.isEmpty {
                    criteriaCard
                }
                if !decision.options.isEmpty {
                    optionsCard
                }
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .navigationTitle(decision.question)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func winnerCard(name: String, score: Double) -> some View {
        VStack(spacing: 8) {
            Label("推薦選項", systemImage: "crown.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.yellow.opacity(0.9))
            Text(name)
                .font(.largeTitle.weight(.bold))
            Text(String(format: "加權得分 %.1f", score))
                .font(.title3)
                .foregroundStyle(.yellow)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            LinearGradient(
                colors: [.yellow.opacity(0.25), .orange.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.yellow.opacity(0.35), lineWidth: 1))
    }

    private var criteriaCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("準則與權重", systemImage: "slider.horizontal.3")
                .font(.headline)
                .foregroundStyle(.orange)

            ForEach(decision.criteria) { c in
                HStack {
                    Text(c.name)
                        .font(.subheadline)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { i in
                            Circle()
                                .fill(i <= Int(c.weight) ? Color.orange : Color.white.opacity(0.2))
                                .frame(width: 8, height: 8)
                        }
                    }
                    Text("\(Int(c.weight))")
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundStyle(.orange)
                        .frame(width: 20, alignment: .trailing)
                }
            }
        }
        .cardStyle()
    }

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("選項得分明細", systemImage: "chart.bar.fill")
                .font(.headline)
                .foregroundStyle(.purple)

            ForEach(rankedOptions, id: \.0.id) { opt, total in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(opt.name)
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f 分", total))
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.cyan)
                    }
                    ForEach(decision.criteria) { c in
                        let s = opt.scores.first { $0.criterionName == c.name }?.score ?? 0
                        HStack(spacing: 10) {
                            Text(c.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 56, alignment: .leading)
                                .lineLimit(1)
                            ProgressView(value: s, total: 100)
                                .tint(.purple)
                            Text(String(format: "%.0f", s))
                                .font(.caption.monospacedDigit())
                                .frame(width: 28, alignment: .trailing)
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .cardStyle()
    }

    private func weightedTotal(option: DecisionOption) -> Double {
        let criteria = decision.criteria
        let totalWeight = criteria.reduce(0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        return criteria.reduce(0.0) { acc, c in
            let s = option.scores.first { $0.criterionName == c.name }?.score ?? 0
            return acc + s * c.weight
        } / totalWeight
    }
}
