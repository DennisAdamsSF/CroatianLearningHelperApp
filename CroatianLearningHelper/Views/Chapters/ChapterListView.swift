import SwiftUI
import SwiftData

struct ChapterListView: View {
    @Query private var chapterProgress: [ChapterProgress]

    private var chapters: [Chapter] {
        QuestionBank.shared.chapters
    }

    private var groupedByCjelina: [(cjelina: Int, cjelinaTitle: String, cjelinaTitleEnglish: String, level: CEFRLevel, sections: [Chapter])] {
        let grouped = Dictionary(grouping: chapters) { $0.cjelina }
        return grouped.keys.sorted().compactMap { cjelina in
            guard let sections = grouped[cjelina], let first = sections.first else { return nil }
            return (
                cjelina: cjelina,
                cjelinaTitle: first.cjelinaTitle,
                cjelinaTitleEnglish: first.cjelinaTitleEnglish,
                level: first.level,
                sections: sections.sorted { $0.section < $1.section }
            )
        }
    }

    private func progress(for chapterID: String) -> ChapterProgress? {
        chapterProgress.first { $0.chapterID == chapterID }
    }

    private func cjelinaAccuracy(sections: [Chapter]) -> Double {
        let progresses = sections.compactMap { progress(for: $0.id) }.filter { $0.totalAttempts > 0 }
        guard !progresses.isEmpty else { return 0 }
        let totalAttempts = progresses.reduce(0) { $0 + $1.totalAttempts }
        let totalCorrect = progresses.reduce(0) { $0 + $1.totalCorrect }
        guard totalAttempts > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAttempts)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedByCjelina, id: \.cjelina) { group in
                    Section {
                        ForEach(group.sections) { chapter in
                            NavigationLink(destination: ChapterDetailView(chapter: chapter)) {
                                sectionRow(chapter: chapter)
                            }
                        }
                    } header: {
                        cjelinaHeader(group: group)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Cjeline")
        }
    }

    private func cjelinaHeader(group: (cjelina: Int, cjelinaTitle: String, cjelinaTitleEnglish: String, level: CEFRLevel, sections: [Chapter])) -> some View {
        HStack(spacing: 10) {
            ProgressRing(
                progress: cjelinaAccuracy(sections: group.sections),
                size: 32,
                lineWidth: 3,
                color: colorForLevel(group.level)
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Cjelina \(group.cjelina)")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Text(group.level.rawValue.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(colorForLevel(group.level).opacity(0.15))
                        .foregroundStyle(colorForLevel(group.level))
                        .clipShape(Capsule())
                }
                Text(group.cjelinaTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func sectionRow(chapter: Chapter) -> some View {
        HStack(spacing: 12) {
            Text(chapter.displayLabel)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(colorForLevel(chapter.level))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(chapter.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(chapter.titleEnglish)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let prog = progress(for: chapter.id), prog.totalAttempts > 0 {
                Text("\(Int(prog.accuracy * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(prog.accuracy >= 0.7 ? .green : .orange)
            } else if chapter.questionCount == 0 {
                Text("Soon")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func colorForLevel(_ level: CEFRLevel) -> Color {
        switch level {
        case .a1: return .green
        case .a2: return .blue
        case .b1: return .purple
        }
    }
}
