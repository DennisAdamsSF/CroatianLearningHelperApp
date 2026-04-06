import Foundation
import SwiftData

@Model
class ProgressRecord {
    @Attribute(.unique) var questionID: String
    var chapterID: String
    var timesShown: Int = 0
    var timesCorrect: Int = 0
    var lastShown: Date?
    var lastCorrect: Date?
    var consecutiveCorrect: Int = 0
    var easeFactor: Double = 2.5

    init(questionID: String, chapterID: String) {
        self.questionID = questionID
        self.chapterID = chapterID
    }

    var accuracy: Double {
        guard timesShown > 0 else { return 0 }
        return Double(timesCorrect) / Double(timesShown)
    }

    var nextReviewDate: Date? {
        guard let lastShown else { return nil }
        let interval = pow(easeFactor, Double(consecutiveCorrect)) * 86400
        return lastShown.addingTimeInterval(interval)
    }

    var isDueForReview: Bool {
        guard let nextReview = nextReviewDate else { return true }
        return Date() >= nextReview
    }

    func recordAnswer(correct: Bool) {
        timesShown += 1
        lastShown = Date()
        if correct {
            timesCorrect += 1
            consecutiveCorrect += 1
            lastCorrect = Date()
            easeFactor = min(easeFactor + 0.1, 3.0)
        } else {
            consecutiveCorrect = 0
            easeFactor = max(easeFactor - 0.2, 1.3)
        }
    }
}
