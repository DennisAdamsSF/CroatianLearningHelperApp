import SwiftUI

struct ConjugationDrillView: View {
    let question: Question
    let engine: QuizEngine

    @State private var answers: [String: String] = [:]
    @State private var hasSubmitted = false
    @State private var results: [(person: String, userAnswer: String, expected: String, isCorrect: Bool)] = []

    private let persons = ["ja", "ti", "on/ona/ono", "mi", "vi", "oni/one/ona"]

    private var expectedForms: [String: String] {
        // Parse the correctAnswer which is formatted as "ja sam, ti si, ..."
        var forms: [String: String] = [:]
        let parts = question.correctAnswer.components(separatedBy: ", ")
        for part in parts {
            for person in persons {
                if part.hasPrefix(person + " ") {
                    let form = String(part.dropFirst(person.count + 1))
                    forms[person] = form
                }
            }
        }
        return forms
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.prompt)
                .font(.title3)
                .fontWeight(.medium)

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

            // Example sentence
            if let example = question.exampleSentence {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Example")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(example)
                        .font(.body)
                        .italic()
                    if let translation = question.exampleTranslation {
                        Text(translation)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(spacing: 12) {
                ForEach(persons, id: \.self) { person in
                    HStack {
                        Text(person)
                            .font(.body)
                            .fontWeight(.medium)
                            .frame(width: 110, alignment: .leading)

                        if hasSubmitted {
                            let result = results.first { $0.person == person }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(answers[person] ?? "")
                                    .foregroundStyle(result?.isCorrect == true ? .green : .red)
                                if result?.isCorrect == false {
                                    Text(result?.expected ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if result?.isCorrect == true {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        } else {
                            SpellCheckTextField(
                                placeholder: "...",
                                text: Binding(
                                    get: { answers[person] ?? "" },
                                    set: { answers[person] = $0 }
                                ),
                                isCroatian: true,
                                disabled: false
                            )
                        }
                    }
                }
            }
            .padding()
            .background(.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if hasSubmitted {
                let correct = results.filter(\.isCorrect).count
                Text("\(correct)/\(results.count) correct")
                    .font(.headline)
                    .foregroundStyle(correct == results.count ? .green : .orange)
            }

            if !hasSubmitted {
                Button("Submit") {
                    hasSubmitted = true
                    let expected = expectedForms
                    let checkResult = engine.answerChecker.checkConjugation(
                        userAnswers: answers, expected: expected
                    )
                    results = checkResult.details
                    engine.submitConjugation(userAnswers: answers, expected: expected)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(answers.values.filter { !$0.isEmpty }.count < persons.count)
            }
        }
    }
}
