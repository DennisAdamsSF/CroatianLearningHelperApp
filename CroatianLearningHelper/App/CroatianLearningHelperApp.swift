import SwiftUI
import SwiftData

@main
struct CroatianLearningHelperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            ProgressRecord.self,
            ChapterProgress.self,
            QuizSessionRecord.self
        ])
    }
}
