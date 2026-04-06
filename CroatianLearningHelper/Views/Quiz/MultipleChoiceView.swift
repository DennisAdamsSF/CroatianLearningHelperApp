import SwiftUI

struct MultipleChoiceView: View {
    let question: Question
    let engine: QuizEngine

    @State private var selectedAnswer: String?
    @State private var hasSubmitted = false

    var options: [String] {
        var all = question.distractors ?? []
        all.append(question.correctAnswer)
        // Use a seeded shuffle based on question ID for consistent ordering per question
        var rng = SeededRandomNumberGenerator(seed: question.id.hashValue)
        all.shuffle(using: &rng)
        return all
    }

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

            ForEach(options, id: \.self) { option in
                Button {
                    guard !hasSubmitted else { return }
                    selectedAnswer = option
                } label: {
                    HStack {
                        Text(option)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if hasSubmitted {
                            if option == question.correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if option == selectedAnswer {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        } else if option == selectedAnswer {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.blue)
                                .font(.caption)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(backgroundColor(for: option))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            if selectedAnswer != nil && !hasSubmitted {
                Button("Submit") {
                    hasSubmitted = true
                    engine.submitAnswer(selectedAnswer ?? "")
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func backgroundColor(for option: String) -> Color {
        if !hasSubmitted {
            return option == selectedAnswer ? .blue.opacity(0.1) : .gray.opacity(0.08)
        }
        if option == question.correctAnswer {
            return .green.opacity(0.15)
        }
        if option == selectedAnswer && option != question.correctAnswer {
            return .red.opacity(0.15)
        }
        return .gray.opacity(0.08)
    }
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed))
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
