import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var chapterProgress: [ChapterProgress]
    @Query(sort: \QuizSessionRecord.date, order: .reverse) private var recentSessions: [QuizSessionRecord]

    @State private var navigateToQuiz = false
    @State private var selectedChapterID: String?

    private var overallAccuracy: Double {
        guard !chapterProgress.isEmpty else { return 0 }
        let total = chapterProgress.reduce(0) { $0 + $1.totalAttempts }
        let correct = chapterProgress.reduce(0) { $0 + $1.totalCorrect }
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    private var weakestChapter: ChapterProgress? {
        chapterProgress
            .filter { $0.totalAttempts > 0 }
            .min { $0.accuracy < $1.accuracy }
    }

    private var totalSessions: Int { recentSessions.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome card
                    VStack(spacing: 8) {
                        Text("Razgovarajte s nama")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Croatian Learning Quiz")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Overall progress
                    ProgressRing(progress: overallAccuracy, size: 120, lineWidth: 10, color: ringColor)
                        .padding()

                    Text("Overall Accuracy")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Quick stats
                    HStack(spacing: 20) {
                        statCard(value: "\(totalSessions)", label: "Sessions", icon: "flame.fill", color: .orange)
                        statCard(value: "\(chapterProgress.filter { $0.totalAttempts > 0 }.count)", label: "Sections", icon: "book.fill", color: .blue)
                        statCard(value: "\(Int(overallAccuracy * 100))%", label: "Accuracy", icon: "target", color: .green)
                    }
                    .padding(.horizontal)

                    // Continue button
                    if let weakest = weakestChapter,
                       let chapter = QuestionBank.shared.chapter(for: weakest.chapterID) {
                        VStack(spacing: 8) {
                            Text("Continue practicing")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            NavigationLink(destination: QuizSessionView(chapterID: weakest.chapterID)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("Cjelina \(chapter.displayLabel)")
                                            .font(.headline)
                                        Text(chapter.title)
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                    Image(systemName: "play.fill")
                                        .font(.title2)
                                }
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // First time — pick a chapter
                        NavigationLink(destination: ChapterListView()) {
                            HStack {
                                Text("Start Learning")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: "play.fill")
                            }
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                    }

                    // Recent sessions
                    if !recentSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Sessions")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(recentSessions.prefix(5)) { session in
                                HStack {
                                    VStack(alignment: .leading) {
                                        if let ch = QuestionBank.shared.chapter(for: session.chapterID) {
                                            Text("\(ch.displayLabel): \(ch.title)")
                                                .font(.body)
                                        } else {
                                            Text(session.chapterID)
                                                .font(.body)
                                        }
                                        Text(session.date, format: .dateTime.month(.abbreviated).day().hour().minute())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("\(session.questionsCorrect)/\(session.questionsAsked)")
                                        .font(.headline)
                                        .foregroundStyle(session.score >= 0.7 ? .green : .orange)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Home")
        }
    }

    private var ringColor: Color {
        if overallAccuracy >= 0.8 { return .green }
        if overallAccuracy >= 0.5 { return .orange }
        if overallAccuracy > 0 { return .red }
        return .blue
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
