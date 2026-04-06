import Foundation
import SwiftData

struct QuestionSelector {
    let modelContext: ModelContext

    func selectQuestions(for chapterID: String, count: Int = 10) -> [Question] {
        let allQuestions = QuestionBank.shared.questions(for: chapterID)
        guard !allQuestions.isEmpty else { return [] }

        let progressRecords = fetchProgress(for: chapterID)
        let progressMap = Dictionary(uniqueKeysWithValues: progressRecords.map { ($0.questionID, $0) })

        var scored = allQuestions.map { question in
            (question: question, priority: computePriority(for: question, progress: progressMap[question.id]))
        }

        scored.sort { $0.priority > $1.priority }

        return applyDiversityConstraints(from: scored.map(\.question), count: count)
    }

    private func computePriority(for question: Question, progress: ProgressRecord?) -> Double {
        var priority = 0.0

        guard let progress else {
            // Never seen — highest priority
            return 100.0 + Double.random(in: 0...20)
        }

        // Weakness bonus: higher if historically answered wrong
        if progress.timesShown > 0 {
            let errorRate = 1.0 - progress.accuracy
            priority += errorRate * 50.0
        }

        // Recency bonus: higher if not shown recently
        if let lastShown = progress.lastShown {
            let daysSince = Date().timeIntervalSince(lastShown) / 86400
            priority += min(daysSince * 5.0, 40.0)
        }

        // Due for review bonus
        if progress.isDueForReview {
            priority += 20.0
        }

        // Random jitter to avoid predictable ordering
        priority += Double.random(in: 0...15)

        return priority
    }

    private func applyDiversityConstraints(from questions: [Question], count: Int) -> [Question] {
        var selected: [Question] = []
        var typeCounts: [QuestionType: Int] = [:]
        let maxPerType = 3

        for question in questions {
            guard selected.count < count else { break }

            let typeCount = typeCounts[question.type, default: 0]
            if typeCount >= maxPerType { continue }

            // Avoid consecutive same grammar topic
            if let lastTopic = selected.last?.grammarTopic,
               let currentTopic = question.grammarTopic,
               lastTopic == currentTopic,
               selected.count >= 2,
               selected[selected.count - 2].grammarTopic == currentTopic {
                continue
            }

            selected.append(question)
            typeCounts[question.type, default: 0] += 1
        }

        // Fill remaining slots if diversity constraints were too strict
        if selected.count < count {
            let selectedIDs = Set(selected.map(\.id))
            for question in questions where selected.count < count {
                if !selectedIDs.contains(question.id) {
                    selected.append(question)
                }
            }
        }

        return selected.shuffled()
    }

    private func fetchProgress(for chapterID: String) -> [ProgressRecord] {
        let predicate = #Predicate<ProgressRecord> { $0.chapterID == chapterID }
        let descriptor = FetchDescriptor<ProgressRecord>(predicate: predicate)
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
