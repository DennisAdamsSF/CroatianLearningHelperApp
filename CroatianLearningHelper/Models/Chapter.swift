import Foundation

struct Chapter: Codable, Identifiable {
    let id: String
    let number: Int
    let title: String
    let titleEnglish: String
    let level: CEFRLevel
    let grammarTopics: [String]
    let vocabThemes: [String]
    let questionCount: Int
}

struct ChaptersFile: Codable {
    let version: Int
    let chapters: [Chapter]
}
