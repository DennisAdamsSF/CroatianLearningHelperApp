import Foundation

enum QuestionType: String, Codable, CaseIterable {
    case multipleChoice
    case fillInBlank
    case translationToEnglish
    case translationToCroatian
    case conjugation
    case declension
    case sentenceBuilder
}

enum CEFRLevel: String, Codable {
    case a1, a2, b1
}

struct Question: Codable, Identifiable {
    let id: String
    let chapterID: String
    let type: QuestionType
    let level: CEFRLevel
    let prompt: String
    let contextSentence: String?
    let correctAnswer: String
    let acceptableAnswers: [String]?
    let distractors: [String]?
    let hint: String?
    let explanation: String?
    let exampleSentence: String?
    let exampleTranslation: String?
    let grammarTopic: String?
    let vocabTags: [String]?
}

struct ChapterFile: Codable {
    let chapterID: String
    let version: Int
    let questions: [Question]
}
