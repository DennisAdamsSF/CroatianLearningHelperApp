import Foundation
import SwiftData

@Model
class ChapterProgress {
    @Attribute(.unique) var chapterID: String
    var totalAttempts: Int = 0
    var totalCorrect: Int = 0
    var uniqueQuestionsAnswered: Int = 0
    var lastPracticed: Date?
    var bestSessionScore: Double = 0

    init(chapterID: String) {
        self.chapterID = chapterID
    }

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAttempts)
    }
}
