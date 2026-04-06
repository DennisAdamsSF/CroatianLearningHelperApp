import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            ChapterListView()
                .tabItem {
                    Label("Chapters", systemImage: "book.fill")
                }

            ProgressOverviewView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
        }
        .tint(.blue)
    }
}
