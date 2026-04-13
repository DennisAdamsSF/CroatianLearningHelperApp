import Foundation

struct Chapter: Codable, Identifiable {
    let id: String
    let cjelina: Int
    let section: String
    let cjelinaTitle: String
    let cjelinaTitleEnglish: String
    let title: String
    let titleEnglish: String
    let level: CEFRLevel
    let grammarTopics: [String]
    let vocabThemes: [String]
    let questionCount: Int

    var displayLabel: String {
        "\(cjelina)\(section)"
    }
}

struct ChaptersFile: Codable {
    let version: Int
    let chapters: [Chapter]
}
