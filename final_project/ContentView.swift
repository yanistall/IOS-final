// MARK: - ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("新決策", systemImage: "plus.circle.fill") {
                NewDecisionView()
            }
            Tab("歷史紀錄", systemImage: "clock.fill") {
                HistoryView()
            }
        }
    }
}

extension View {
    func cardStyle() -> some View {
        self
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

