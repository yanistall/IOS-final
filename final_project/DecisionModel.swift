// MARK: - DecisionModel.swift
import SwiftData
import Foundation

@Model
final class Decision {
    var question: String
    var date: Date
    var recommendedOption: String
    var recommendedScore: Double
    @Relationship(deleteRule: .cascade, inverse: \Criterion.decision) var criteria: [Criterion] = []
    @Relationship(deleteRule: .cascade, inverse: \DecisionOption.decision) var options: [DecisionOption] = []

    init(question: String, recommendedOption: String, recommendedScore: Double) {
        self.question = question
        self.date = .now
        self.recommendedOption = recommendedOption
        self.recommendedScore = recommendedScore
    }
}

@Model
final class Criterion {
    var name: String
    var weight: Double
    var decision: Decision?

    init(name: String, weight: Double) {
        self.name = name
        self.weight = weight
    }
}

@Model
final class DecisionOption {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \OptionScore.option) var scores: [OptionScore] = []
    var decision: Decision?

    init(name: String) {
        self.name = name
    }
}

@Model
final class OptionScore {
    var criterionName: String
    var score: Double
    var option: DecisionOption?

    init(criterionName: String, score: Double) {
        self.criterionName = criterionName
        self.score = score
    }
}
