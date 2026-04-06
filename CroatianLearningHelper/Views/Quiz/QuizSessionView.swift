import SwiftUI
import SwiftData

struct QuizSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var engine: QuizEngine

    let chapterID: String

    init(chapterID: String) {
        self.chapterID = chapterID
        // Placeholder — real modelContext injected via onAppear
        _engine = State(initialValue: QuizEngine(chapterID: chapterID, modelContext: ModelContext(try! ModelContainer(for: ProgressRecord.self, ChapterProgress.self, QuizSessionRecord.self))))
    }

    var body: some View {
        VStack {
            if engine.isSessionComplete {
                QuizResultView(engine: engine) {
                    engine.startSession()
                } onDismiss: {
                    dismiss()
                }
            } else if let question = engine.currentQuestion {
                // Progress bar
                VStack(spacing: 12) {
                    HStack {
                        Text("Question \(engine.currentIndex + 1) of \(engine.questions.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(question.type.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    ProgressView(value: engine.progress)
                        .tint(.blue)
                }
                .padding(.horizontal)

                // Question content
                ScrollView {
                    VStack(spacing: 20) {
                        switch question.type {
                        case .multipleChoice:
                            MultipleChoiceView(question: question, engine: engine)
                        case .fillInBlank:
                            FillInBlankView(question: question, engine: engine)
                        case .translationToEnglish, .translationToCroatian:
                            TranslationView(question: question, engine: engine)
                        case .conjugation, .declension:
                            ConjugationDrillView(question: question, engine: engine)
                        }
                    }
                    .padding()
                    .id(question.id)
                }

                // Feedback overlay
                if engine.isShowingFeedback {
                    AnswerFeedbackView(result: engine.lastResult, explanation: question.explanation) {
                        engine.nextQuestion()
                    }
                }
            } else {
                ContentUnavailableView("No Questions", systemImage: "questionmark.circle",
                    description: Text("No questions available for this chapter yet."))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") { dismiss() }
            }
        }
        .onAppear {
            engine = QuizEngine(chapterID: chapterID, modelContext: modelContext)
            engine.startSession()
        }
    }
}

extension QuestionType {
    var displayName: String {
        switch self {
        case .multipleChoice: "Multiple Choice"
        case .fillInBlank: "Fill in the Blank"
        case .translationToEnglish: "Translate to English"
        case .translationToCroatian: "Translate to Croatian"
        case .conjugation: "Conjugation"
        case .declension: "Declension"
        }
    }
}
