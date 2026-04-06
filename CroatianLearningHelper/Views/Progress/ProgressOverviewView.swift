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
                VStack(spacing: 20) {
                    if activeChapterData.isEmpty {
                        ContentUnavailableView(
                            "No Progress Yet",
                            systemImage: "chart.bar",
                            description: Text("Complete some quizzes to see your progress here.")
                        )
                    } else {
                        // Accuracy by chapter
                        chartCard("Accuracy by Chapter") {
                            Chart(activeChapterData, id: \.chapter.id) { item in
                                BarMark(
                                    x: .value("Chapter", "Ch. \(item.chapter.number)"),
                                    y: .value("Accuracy", item.progress.accuracy * 100),
                                    width: .fixed(40)
                                )
                                .foregroundStyle(item.progress.accuracy >= 0.7 ? .green : .orange)
                                .cornerRadius(6)
                                .annotation(position: .top, spacing: 4) {
                                    Text("\(Int(item.progress.accuracy * 100))%")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .chartYScale(domain: 0...100)
                            .chartYAxis {
                                AxisMarks(values: [0, 50, 100]) { value in
                                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                    AxisValueLabel {
                                        Text("\(value.as(Int.self) ?? 0)%")
                                            .font(.caption2)
                                    }
                                }
                            }
                            .frame(height: 180)
                        }

                        // Recent scores over time
                        if sessions.count >= 2 {
                            chartCard("Recent Scores") {
                                let recentSessions = Array(sessions.prefix(10).reversed())
                                Chart(Array(recentSessions.enumerated()), id: \.offset) { index, session in
                                    LineMark(
                                        x: .value("Session", "Quiz \(index + 1)"),
                                        y: .value("Score", session.score * 100)
                                    )
                                    .foregroundStyle(.blue)
                                    .interpolationMethod(.catmullRom)
                                    PointMark(
                                        x: .value("Session", "Quiz \(index + 1)"),
                                        y: .value("Score", session.score * 100)
                                    )
                                    .foregroundStyle(.blue)
                                    .annotation(position: .top, spacing: 4) {
                                        Text("\(Int(session.score * 100))%")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .chartYScale(domain: 0...100)
                                .chartYAxis {
                                    AxisMarks(values: [0, 50, 100]) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                                        AxisValueLabel {
                                            Text("\(value.as(Int.self) ?? 0)%")
                                                .font(.caption2)
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks { _ in
                                        AxisValueLabel()
                                            .font(.caption2)
                                    }
                                }
                                .frame(height: 180)
                            }
                        }

                        // Weak areas
                        if !weakAreas.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Areas to Improve", systemImage: "exclamationmark.triangle.fill")
                                    .font(.headline)
                                    .foregroundStyle(.orange)

                                ForEach(weakAreas.prefix(5), id: \.topic) { area in
                                    HStack {
                                        Text(area.topic)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(Int(area.accuracy * 100))%")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.orange)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .padding()
                            .background(.orange.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Totals
                        VStack(spacing: 0) {
                            let totalAttempts = sessions.reduce(0) { $0 + $1.questionsAsked }
                            let totalCorrect = sessions.reduce(0) { $0 + $1.questionsCorrect }

                            totalRow(label: "Questions answered", value: "\(totalAttempts)", color: .primary)
                            Divider().padding(.horizontal)
                            totalRow(label: "Correct answers", value: "\(totalCorrect)", color: .green)
                            Divider().padding(.horizontal)
                            totalRow(label: "Quiz sessions", value: "\(sessions.count)", color: .primary)
                        }
                        .background(.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }

    private func chartCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func totalRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
