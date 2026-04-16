import SwiftUI

struct QuizResultView: View {
    let engine: QuizEngine
    let onRetry: () -> Void
    let onDismiss: () -> Void

    private var score: Double {
        guard engine.questions.count > 0 else { return 0 }
        return Double(engine.correctCount) / Double(engine.questions.count)
    }

    private var scoreColor: Color {
        if score >= 0.8 { return .green }
        if score >= 0.5 { return .orange }
        return .red
    }

    private var encouragement: String {
        if score >= 0.9 { return "Odlično! Excellent!" }
        if score >= 0.7 { return "Vrlo dobro! Very good!" }
        if score >= 0.5 { return "Dobro! Keep practicing!" }
        return "Ne brini! Don't worry, practice makes perfect!"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(.gray.opacity(0.2), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: score)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.8), value: score)
                    VStack {
                        Text("\(Int(score * 100))%")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(scoreColor)
                        Text("\(engine.correctCount)/\(engine.questions.count)")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 160, height: 160)
                .padding(.top, 20)

                Text(encouragement)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                // Stats
                HStack(spacing: 24) {
                    statItem(value: "\(engine.finalDurationSeconds)s", label: "Time")
                    statItem(value: "\(engine.questions.count)", label: "Questions")
                    statItem(value: "\(engine.correctCount)", label: "Correct")
                }
                .padding()
                .background(.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Mistakes review
                let mistakes = engine.questions.filter { q in
                    if let result = engine.answers[q.id] {
                        switch result {
                        case .correct: return false
                        default: return true
                        }
                    }
                    return false
                }

                if !mistakes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review Mistakes")
                            .font(.headline)

                        ForEach(mistakes) { question in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(question.prompt)
                                    .font(.body)
                                Text("Answer: \(question.correctAnswer)")
                                    .font(.callout)
                                    .foregroundStyle(.green)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button("Try Again") { onRetry() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                    Button("Done") { onDismiss() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
