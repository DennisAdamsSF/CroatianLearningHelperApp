import Foundation
import SwiftData
import Observation

@Observable
class QuizEngine {
    var questions: [Question] = []
    var currentIndex: Int = 0
    var answers: [String: AnswerResult] = [:]
    var conjugationAnswers: [String: (correct: Int, total: Int)] = [:]
    var isShowingFeedback: Bool = false
    var lastResult: AnswerResult?
    var isSessionComplete: Bool = false
    var finalDurationSeconds: Int = 0
    private var sessionStartTime: Date = Date()

    let chapterID: String
    let answerChecker = AnswerChecker()

    private var modelContext: ModelContext

    var currentQuestion: Question? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    var correctCount: Int {
        answers.values.filter {
            if case .correct = $0 { return true }
            return false
        }.count + conjugationAnswers.values.reduce(0) { $0 + $1.correct }
    }

    var totalAnswered: Int {
        answers.count + conjugationAnswers.count
    }

    var sessionDuration: Int {
        if isSessionComplete {
            return finalDurationSeconds
        }
        return Int(Date().timeIntervalSince(sessionStartTime))
    }

    init(chapterID: String, modelContext: ModelContext) {
        self.chapterID = chapterID
        self.modelContext = modelContext
    }

    func startSession(questionCount: Int = 10) {
        let selector = QuestionSelector(modelContext: modelContext)
        questions = selector.selectQuestions(for: chapterID, count: questionCount)
        currentIndex = 0
        answers = [:]
        conjugationAnswers = [:]
        isShowingFeedback = false
        isSessionComplete = false
        finalDurationSeconds = 0
        sessionStartTime = Date()
    }

    func submitAnswer(_ answer: String) {
        guard let question = currentQuestion else { return }

        let result = answerChecker.check(userAnswer: answer, against: question)
        answers[question.id] = result
        lastResult = result

        let isCorrect: Bool
        switch result {
        case .correct: isCorrect = true
        default: isCorrect = false
        }

        updateProgress(questionID: question.id, correct: isCorrect)
        isShowingFeedback = true
    }

    func submitConjugation(userAnswers: [String: String], expected: [String: String]) {
        guard let question = currentQuestion else { return }

        let result = answerChecker.checkConjugation(userAnswers: userAnswers, expected: expected)
        conjugationAnswers[question.id] = (correct: result.correct, total: result.total)

        let isCorrect = result.correct == result.total
        updateProgress(questionID: question.id, correct: isCorrect)
        isShowingFeedback = true
    }

    func cancelSession() {
        finalDurationSeconds = Int(Date().timeIntervalSince(sessionStartTime))
        isSessionComplete = true
        questions = []
    }

    func nextQuestion() {
        isShowingFeedback = false
        lastResult = nil
        currentIndex += 1

        if currentIndex >= questions.count {
            completeSession()
        }
    }

    private func completeSession() {
        finalDurationSeconds = Int(Date().timeIntervalSince(sessionStartTime))
        isSessionComplete = true

        let totalCorrect = correctCount
        let totalAsked = questions.count

        // Save session record
        let types = Array(Set(questions.map(\.type.rawValue)))
        let record = QuizSessionRecord(
            chapterID: chapterID,
            questionsAsked: totalAsked,
            questionsCorrect: totalCorrect,
            questionTypes: types,
            durationSeconds: sessionDuration
        )
        modelContext.insert(record)

        // Update chapter progress
        updateChapterProgress(correct: totalCorrect, total: totalAsked)

        try? modelContext.save()
    }

    private func updateProgress(questionID: String, correct: Bool) {
        let predicate = #Predicate<ProgressRecord> { $0.questionID == questionID }
        let descriptor = FetchDescriptor<ProgressRecord>(predicate: predicate)

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.recordAnswer(correct: correct)
        } else {
            let record = ProgressRecord(questionID: questionID, chapterID: chapterID)
            record.recordAnswer(correct: correct)
            modelContext.insert(record)
        }
    }

    private func updateChapterProgress(correct: Int, total: Int) {
        let chID = chapterID
        let predicate = #Predicate<ChapterProgress> { $0.chapterID == chID }
        let descriptor = FetchDescriptor<ChapterProgress>(predicate: predicate)

        let chapterProgress: ChapterProgress
        if let existing = try? modelContext.fetch(descriptor).first {
            chapterProgress = existing
        } else {
            chapterProgress = ChapterProgress(chapterID: chapterID)
            modelContext.insert(chapterProgress)
        }

        chapterProgress.totalAttempts += total
        chapterProgress.totalCorrect += correct
        chapterProgress.lastPracticed = Date()

        let score = Double(correct) / Double(total)
        if score > chapterProgress.bestSessionScore {
            chapterProgress.bestSessionScore = score
        }

        // Count unique questions answered
        let allProgressPredicate = #Predicate<ProgressRecord> { $0.chapterID == chID }
        let allProgressDescriptor = FetchDescriptor<ProgressRecord>(predicate: allProgressPredicate)
        if let allProgress = try? modelContext.fetch(allProgressDescriptor) {
            chapterProgress.uniqueQuestionsAnswered = allProgress.count
        }
    }
}
