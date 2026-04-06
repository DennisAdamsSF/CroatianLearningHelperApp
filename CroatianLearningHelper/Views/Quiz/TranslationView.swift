import SwiftUI

struct TranslationView: View {
    let question: Question
    let engine: QuizEngine

    @State private var userAnswer = ""
    @State private var hasSubmitted = false

    private var isCroatianInput: Bool {
        question.type == .translationToCroatian
    }

    private var directionLabel: String {
        question.type == .translationToEnglish ? "Translate to English" : "Prevedite na hrvatski"
    }

    private var directionIcon: String {
        question.type == .translationToEnglish ? "🇭🇷 → 🇬🇧" : "🇬🇧 → 🇭🇷"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(directionIcon)
                    .font(.title2)
                Text(directionLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(question.prompt)
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            if let hint = question.hint, !hasSubmitted {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundStyle(.yellow)
                    Text(hint)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            SpellCheckTextField(
                placeholder: "Your translation...",
                text: $userAnswer,
                isCroatian: isCroatianInput,
                disabled: hasSubmitted,
                axis: Axis.vertical,
                onSubmit: submitIfReady
            )

            if hasSubmitted, let result = engine.lastResult {
                resultView(result)
            }

            if !hasSubmitted && !userAnswer.isEmpty {
                Button("Submit") { submitIfReady() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func resultView(_ result: AnswerResult) -> some View {
        switch result {
        case .correct:
            Label("Correct!", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.headline)
        case .almostCorrect(let expected):
            VStack(alignment: .leading, spacing: 4) {
                Label("Almost correct!", systemImage: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.headline)
                Text("Expected: \(expected)")
                    .foregroundStyle(.secondary)
            }
        case .incorrect(let expected):
            VStack(alignment: .leading, spacing: 4) {
                Label("Incorrect", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.headline)
                Text("Correct answer: \(expected)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func submitIfReady() {
        guard !hasSubmitted && !userAnswer.isEmpty else { return }
        hasSubmitted = true
        engine.submitAnswer(userAnswer)
    }
}
