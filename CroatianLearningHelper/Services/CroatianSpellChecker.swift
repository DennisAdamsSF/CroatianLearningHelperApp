import UIKit

struct CroatianSpellChecker {
    private let checker = UITextChecker()
    private let language = "hr"

    /// Check if Croatian is available on this device
    var isAvailable: Bool {
        UITextChecker.availableLanguages.contains { $0.hasPrefix("hr") }
    }

    /// Get spelling suggestions for a word in Croatian
    func suggestions(for word: String) -> [String] {
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: language
        )

        guard misspelledRange.location != NSNotFound else {
            return [] // Word is spelled correctly
        }

        let guesses = checker.guesses(forWordRange: misspelledRange, in: word, language: language) ?? []
        return Array(guesses.prefix(4))
    }

    /// Check if a word is spelled correctly in Croatian
    func isCorrect(_ word: String) -> Bool {
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: language
        )
        return misspelledRange.location == NSNotFound
    }

    /// Get suggestions for the last word in a sentence
    func suggestionsForLastWord(in text: String) -> [String] {
        let words = text.trimmingCharacters(in: .whitespaces).components(separatedBy: " ")
        guard let lastWord = words.last, !lastWord.isEmpty, lastWord.count >= 2 else {
            return []
        }
        return suggestions(for: lastWord)
    }

    /// Get completions for a partial word
    func completions(for partialWord: String) -> [String] {
        guard partialWord.count >= 2 else { return [] }
        let completions = checker.completions(
            forPartialWordRange: NSRange(location: 0, length: partialWord.utf16.count),
            in: partialWord,
            language: language
        ) ?? []
        return Array(completions.prefix(4))
    }
}
