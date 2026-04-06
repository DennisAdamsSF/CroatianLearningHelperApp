import SwiftUI
import SwiftData

struct ChapterListView: View {
    @Query private var chapterProgress: [ChapterProgress]

    private var chapters: [Chapter] {
        QuestionBank.shared.chapters
    }

    private func progress(for chapterID: String) -> ChapterProgress? {
        chapterProgress.first { $0.chapterID == chapterID }
    }

    var body: some View {
        NavigationStack {
            List(chapters) { chapter in
                NavigationLink(destination: ChapterDetailView(chapter: chapter)) {
                    HStack(spacing: 14) {
                        ProgressRing(
                            progress: progress(for: chapter.id)?.accuracy ?? 0,
                            size: 44,
                            lineWidth: 4,
                            color: colorForLevel(chapter.level)
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Lekcija \(chapter.number)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                Text(chapter.level.rawValue.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(colorForLevel(chapter.level).opacity(0.15))
                                    .foregroundStyle(colorForLevel(chapter.level))
                                    .clipShape(Capsule())
                            }

                            Text(chapter.title)
                                .font(.body)
                                .fontWeight(.medium)

                            Text(chapter.titleEnglish)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let prog = progress(for: chapter.id), prog.totalAttempts > 0 {
                            VStack(alignment: .trailing) {
                                Text("\(prog.uniqueQuestionsAnswered)/\(chapter.questionCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Chapters")
        }
    }

    private func colorForLevel(_ level: CEFRLevel) -> Color {
        switch level {
        case .a1: return .green
        case .a2: return .blue
        case .b1: return .purple
        }
    }
}
