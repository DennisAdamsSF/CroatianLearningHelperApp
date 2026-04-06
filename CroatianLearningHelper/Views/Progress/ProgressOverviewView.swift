import SwiftUI
import SwiftData
import Charts

struct ProgressOverviewView: View {
    @Query private var chapterProgress: [ChapterProgress]
    @Query(sort: \QuizSessionRecord.date, order: .reverse) private var sessions: [QuizSessionRecord]

    private var chapters: [Chapter] {
        QuestionBank.shared.chapters
    }

    private var activeChapterData: [(chapter: Chapter, progress: ChapterProgress)] {
        chapters.compactMap { ch in
            guard let prog = chapterProgress.first(where: { $0.chapterID == ch.id }),
                  prog.totalAttempts > 0 else { return nil }
            return (chapter: ch, progress: prog)
        }
    }

    private var weakAreas: [(topic: String, accuracy: Double)] {
        // Aggregate accuracy by grammar topic from session data
        // For now, show chapter-level weaknesses
        activeChapterData
            .filter { $0.progress.accuracy < 0.7 }
            .sorted { $0.progress.accuracy < $1.progress.accuracy }
            .flatMap { item in
                item.chapter.grammarTopics.map { topic in
                    (topic: topic, accuracy: item.progress.accuracy)
                }
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if activeChapterData.isEmpty {
                        ContentUnavailableView(
                            "No Progress Yet",
                            systemImage: "chart.bar",
                            description: Text("Complete some quizzes to see your progress here.")
                        )
                    } else {
                        // Accuracy by chapter chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Accuracy by Chapter")
                                .font(.headline)

                            Chart(activeChapterData, id: \.chapter.id) { item in
                                BarMark(
                                    x: .value("Chapter", "Ch. \(item.chapter.number)"),
                                    y: .value("Accuracy", item.progress.accuracy * 100)
                                )
                                .foregroundStyle(item.progress.accuracy >= 0.7 ? .green : .orange)
                                .cornerRadius(4)
                            }
                            .chartYScale(domain: 0...100)
                            .chartYAxis {
                                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        Text("\(value.as(Int.self) ?? 0)%")
                                    }
                                }
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // Sessions over time
                        if sessions.count >= 2 {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Scores")
                                    .font(.headline)

                                Chart(sessions.prefix(20).reversed()) { session in
                                    LineMark(
                                        x: .value("Date", session.date),
                                        y: .value("Score", session.score * 100)
                                    )
                                    .foregroundStyle(.blue)
                                    PointMark(
                                        x: .value("Date", session.date),
                                        y: .value("Score", session.score * 100)
                                    )
                                    .foregroundStyle(.blue)
                                }
                                .chartYScale(domain: 0...100)
                                .frame(height: 200)
                            }
                            .padding()
                            .background(.gray.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Weak areas
                        if !weakAreas.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Areas to Improve")
                                    .font(.headline)

                                ForEach(weakAreas.prefix(5), id: \.topic) { area in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                            .font(.caption)
                                        Text(area.topic)
                                            .font(.body)
                                        Spacer()
                                        Text("\(Int(area.accuracy * 100))%")
                                            .font(.callout)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                            .padding()
                            .background(.orange.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Total stats
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Totals")
                                .font(.headline)

                            let totalAttempts = chapterProgress.reduce(0) { $0 + $1.totalAttempts }
                            let totalCorrect = chapterProgress.reduce(0) { $0 + $1.totalCorrect }

                            HStack {
                                Text("Questions answered")
                                Spacer()
                                Text("\(totalAttempts)")
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                Text("Correct answers")
                                Spacer()
                                Text("\(totalCorrect)")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.green)
                            }
                            HStack {
                                Text("Quiz sessions")
                                Spacer()
                                Text("\(sessions.count)")
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .background(.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
}
