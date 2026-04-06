import Foundation

class QuestionBank {
    static let shared = QuestionBank()

    private var questionCache: [String: [Question]] = [:]
    private var chaptersCache: [Chapter]?

    var chapters: [Chapter] {
        if let cached = chaptersCache { return cached }
        guard let url = Bundle.main.url(forResource: "chapters", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(ChaptersFile.self, from: data) else {
            return []
        }
        chaptersCache = file.chapters
        return file.chapters
    }

    func questions(for chapterID: String) -> [Question] {
        if let cached = questionCache[chapterID] { return cached }
        guard let url = Bundle.main.url(forResource: chapterID, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(ChapterFile.self, from: data) else {
            return []
        }
        questionCache[chapterID] = file.questions
        return file.questions
    }

    func chapter(for id: String) -> Chapter? {
        chapters.first { $0.id == id }
    }
}
