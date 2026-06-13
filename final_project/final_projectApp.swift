// MARK: - final_projectApp.swift
import SwiftUI
import SwiftData

@main
struct final_projectApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Decision.self,
                Criterion.self,
                DecisionOption.self,
                OptionScore.self
            ])
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("SwiftData 容器建立失敗: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
