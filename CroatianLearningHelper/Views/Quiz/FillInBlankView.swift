import SwiftUI

struct FillInBlankView: View {
    let question: Question
    let engine: QuizEngine

    @State private var userAnswer = ""
    @State private var hasSubmitted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.prompt)
                .font(.title3)
                .fontWeight(.medium)

            if let context = question.contextSentence {
                Text(context)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
            }

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
                placeholder: "Type your answer...",
                text: $userAnswer,
                isCroatian: true,
                disabled: hasSubmitted,
                onSubmit: submitIfReady
            )

            if hasSubmitted {
                resultDisplay
            }

            if !hasSubmitted && !userAnswer.isEmpty {
                Button("Submit") { submitIfReady() }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var resultDisplay: some View {
        if let result = engine.lastResult {
            switch result {
            case .correct:
                Label("Correct!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            case .almostCorrect(let expected):
                VStack(alignment: .leading, spacing: 4) {
                    Label("Almost! Close enough.", systemImage: "exclamationmark.circle.fill")
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
    }

    private func submitIfReady() {
        guard !hasSubmitted && !userAnswer.isEmpty else { return }
        hasSubmitted = true
        engine.submitAnswer(userAnswer)
    }
}
