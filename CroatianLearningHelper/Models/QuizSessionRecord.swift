import Foundation
import SwiftData

@Model
class QuizSessionRecord {
    var sessionID: UUID = UUID()
    var chapterID: String
    var date: Date = Date()
    var questionsAsked: Int
    var questionsCorrect: Int
    var questionTypes: [String]
    var durationSeconds: Int

    init(chapterID: String, questionsAsked: Int, questionsCorrect: Int,
         questionTypes: [String], durationSeconds: Int) {
        self.chapterID = chapterID
        self.questionsAsked = questionsAsked
        self.questionsCorrect = questionsCorrect
        self.questionTypes = questionTypes
        self.durationSeconds = durationSeconds
    }

    var score: Double {
        guard questionsAsked > 0 else { return 0 }
        return Double(questionsCorrect) / Double(questionsAsked)
    }
}
