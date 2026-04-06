import SwiftUI
import SwiftData

struct ChapterDetailView: View {
    let chapter: Chapter

    @Query private var chapterProgress: [ChapterProgress]
    @Query private var sessions: [QuizSessionRecord]

    private var progress: ChapterProgress? {
        chapterProgress.first { $0.chapterID == chapter.id }
    }

    private var chapterSessions: [QuizSessionRecord] {
        sessions
            .filter { $0.chapterID == chapter.id }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Lekcija \(chapter.number)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(chapter.title)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(chapter.titleEnglish)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                // Progress ring
                ProgressRing(
                    progress: progress?.accuracy ?? 0,
                    size: 100,
                    lineWidth: 8,
                    color: .blue
                )

                // Stats
                if let prog = progress, prog.totalAttempts > 0 {
                    HStack(spacing: 20) {
                        statItem(value: "\(prog.totalAttempts)", label: "Attempts")
                        statItem(value: "\(Int(prog.accuracy * 100))%", label: "Accuracy")
                        statItem(value: "\(Int(prog.bestSessionScore * 100))%", label: "Best")
                    }
                    .padding()
                    .background(.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Grammar topics
                VStack(alignment: .leading, spacing: 8) {
                    Text("Grammar Topics")
                        .font(.headline)
                    FlowLayout(spacing: 8) {
                        ForEach(chapter.grammarTopics, id: \.self) { topic in
                            Text(topic)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Vocabulary themes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vocabulary Themes")
                        .font(.headline)
                    FlowLayout(spacing: 8) {
                        ForEach(chapter.vocabThemes, id: \.self) { theme in
                            Text(theme)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.green.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Start quiz button
                NavigationLink(destination: QuizSessionView(chapterID: chapter.id)) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Quiz")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Session history
                if !chapterSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Session History")
                            .font(.headline)

                        ForEach(chapterSessions.prefix(10)) { session in
                            HStack {
                                Text(session.date, style: .date)
                                    .font(.callout)
                                Spacer()
                                Text("\(session.questionsCorrect)/\(session.questionsAsked)")
                                    .fontWeight(.medium)
                                    .foregroundStyle(session.score >= 0.7 ? .green : .orange)
                                Text("\(session.durationSeconds)s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
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
        .frame(maxWidth: .infinity)
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
