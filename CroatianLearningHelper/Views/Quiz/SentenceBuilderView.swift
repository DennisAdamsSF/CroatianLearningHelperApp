import SwiftUI

struct SentenceBuilderView: View {
    let question: Question
    let engine: QuizEngine

    @State private var userAnswer = ""
    @State private var hasSubmitted = false

    private var wordParts: (noun: String, pronoun: String)? {
        guard let range = question.prompt.range(of: "with: ") else { return nil }
        let components = question.prompt[range.upperBound...]
            .components(separatedBy: " + ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard components.count == 2 else { return nil }
        return (noun: components[0], pronoun: components[1])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Build a possessive sentence")
                .font(.title3)
                .fontWeight(.medium)

            if let parts = wordParts {
                HStack(spacing: 12) {
                    wordChip(parts.noun, icon: "textformat")
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                    wordChip(parts.pronoun, icon: "person")
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.secondary)
                    Text("?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
            }

            if let context = question.contextSentence {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)
                    Text(context)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .italic()
                }
                .padding(10)
                .background(.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
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
                placeholder: "Type the full sentence...",
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

    private func wordChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.blue.opacity(0.1))
        .clipShape(Capsule())
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
