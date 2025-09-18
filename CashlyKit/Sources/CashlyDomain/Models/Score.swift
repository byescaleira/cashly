//
//  Score.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 16/09/25.
//

import SwiftUI

public struct Score: Equatable, Identifiable {
    public var title: String
    public var score: Int
    public var min: Double
    public var max: Double
    public var summary: String
    public var color: Color
    
    public var id: String {
        title
    }
    
    public var isEnable: Bool {
        let score = score.double
        return score >= min && score <= max
    }
    
    public var progress: Double {
        let score = score.double
        return (score - min) / (max - min)
    }
    
    public init(
        title: String,
        score: Int,
        min: Double,
        max: Double,
        summary: String,
        color: Color
    ) {
        self.title = title
        self.score = score
        self.min = min
        self.max = max
        self.summary = summary
        self.color = color
    }
}

extension Score {
    static func critical(score: Int) -> Score {
        Score(
            title: "Critical",
            score: score,
            min: 200,
            max: 499,
            summary: """
            You are spending significantly above your planned budget. Immediate action is required to regain control.
            """,
            color: .red
        )
    }

    static func atRisk(score: Int) -> Score {
        Score(
            title: "At Risk",
            score: score,
            min: 500,
            max: 699,
            summary: """
            Your spending is above your budget. Take steps to reduce discretionary expenses and monitor your cash flow closely to avoid further overspending.
            """,
            color: .orange
        )
    }

    static func overBudget(score: Int) -> Score {
        Score(
            title: "Over Budget",
            score: score,
            min: 700,
            max: 894,
            summary: """
            You have exceeded your planned budget. Adjust your spending immediately and focus on essential costs to regain control of your finances.
            """,
            color: .yellow
        )
    }

    static func healthy(score: Int) -> Score {
        Score(
            title: "Healthy",
            score: score,
            min: 895,
            max: 1000,
            summary: """
            Excellent! You are within your planned budget and managing your finances well.
            """,
            color: .green
        )
    }

}

public extension Array where Element == Score {
    static func scores(for score: Int) -> [Score] {
        [
            .critical(score: score),
            .atRisk(score: score),
            .overBudget(score: score),
            .healthy(score: score)
        ]
    }
}

public struct BalanceScore: Equatable {
    var score: Int
    
    public init(score: Int) {
        self.score = score
    }
    
    public var scores: [Score] {
        .scores(for: score)
    }
}
