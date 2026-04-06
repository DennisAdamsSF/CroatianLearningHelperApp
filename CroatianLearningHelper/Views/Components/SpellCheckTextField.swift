import SwiftUI
import Combine

struct SpellCheckTextField: View {
    let placeholder: String
    @Binding var text: String
    var isCroatian: Bool = true
    var disabled: Bool = false
    var axis: Axis = .horizontal
    var onSubmit: (() -> Void)?

    @State private var suggestions: [String] = []
    @FocusState private var isFocused: Bool

    private let spellChecker = CroatianSpellChecker()

    var body: some View {
        VStack(spacing: 6) {
            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .textInputAutocapitalization(.never)
                .focused($isFocused)
                .disabled(disabled)
                .onSubmit { onSubmit?() }
                .onChange(of: text) { _, newValue in
                    if isCroatian {
                        updateSuggestions(for: newValue)
                    }
                }

            if !suggestions.isEmpty && !disabled {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Image(systemName: "character.cursor.ibeam")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                applySuggestion(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(.callout)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: suggestions)
        .onAppear { isFocused = true }
    }

    private func updateSuggestions(for text: String) {
        guard !text.isEmpty else {
            suggestions = []
            return
        }

        // Get both corrections and completions
        var allSuggestions: [String] = []

        let corrections = spellChecker.suggestionsForLastWord(in: text)
        allSuggestions.append(contentsOf: corrections)

        // If no corrections, try completions for the last word
        if corrections.isEmpty {
            let words = text.components(separatedBy: " ")
            if let lastWord = words.last {
                let completions = spellChecker.completions(for: lastWord)
                allSuggestions.append(contentsOf: completions)
            }
        }

        suggestions = Array(Set(allSuggestions)).sorted().prefix(4).map { $0 }
    }

    private func applySuggestion(_ suggestion: String) {
        var words = text.components(separatedBy: " ")
        if !words.isEmpty {
            words[words.count - 1] = suggestion
        }
        text = words.joined(separator: " ") + " "
        suggestions = []
    }
}
