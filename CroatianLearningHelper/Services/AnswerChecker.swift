import Foundation

enum AnswerResult {
    case correct
    case almostCorrect(expected: String)
    case incorrect(expected: String)
}

struct AnswerChecker {
    var strictDiacritics: Bool = false

    func check(userAnswer: String, against question: Question) -> AnswerResult {
        let normalized = normalize(userAnswer)
        let correctNormalized = normalize(question.correctAnswer)

        // Exact match
        if normalized == correctNormalized {
            return .correct
        }

        // Check acceptable answers
        if let acceptable = question.acceptableAnswers {
            for answer in acceptable {
                if normalized == normalize(answer) {
                    return .correct
                }
            }
        }

        // Fuzzy match — Levenshtein distance
        let distance = levenshteinDistance(normalized, correctNormalized)
        if distance <= 2 && normalized.count > 3 {
            return .almostCorrect(expected: question.correctAnswer)
        }

        // Check acceptable answers with fuzzy matching too
        if let acceptable = question.acceptableAnswers {
            for answer in acceptable {
                if levenshteinDistance(normalized, normalize(answer)) <= 2 && normalized.count > 3 {
                    return .almostCorrect(expected: answer)
                }
            }
        }

        return .incorrect(expected: question.correctAnswer)
    }

    func checkConjugation(userAnswers: [String: String], expected: [String: String]) -> (correct: Int, total: Int, details: [(person: String, userAnswer: String, expected: String, isCorrect: Bool)]) {
        var correct = 0
        var details: [(person: String, userAnswer: String, expected: String, isCorrect: Bool)] = []
        let persons = ["ja", "ti", "on/ona/ono", "mi", "vi", "oni/one/ona"]

        for person in persons {
            guard let expectedForm = expected[person] else { continue }
            let userForm = userAnswers[person] ?? ""
            let isCorrect = normalize(userForm) == normalize(expectedForm)
            if isCorrect { correct += 1 }
            details.append((person: person, userAnswer: userForm, expected: expectedForm, isCorrect: isCorrect))
        }

        return (correct: correct, total: details.count, details: details)
    }

    private func normalize(_ text: String) -> String {
        var result = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        // Remove trailing punctuation
        while result.last == "." || result.last == "!" || result.last == "?" {
            result.removeLast()
        }

        if !strictDiacritics {
            // Normalize Croatian diacritics for lenient matching
            result = result
                .replacingOccurrences(of: "č", with: "c")
                .replacingOccurrences(of: "ć", with: "c")
                .replacingOccurrences(of: "ž", with: "z")
                .replacingOccurrences(of: "š", with: "s")
                .replacingOccurrences(of: "đ", with: "d")
        }

        return result
    }
}

// Levenshtein distance for fuzzy matching
func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
    let a = Array(s1)
    let b = Array(s2)
    let m = a.count
    let n = b.count

    if m == 0 { return n }
    if n == 0 { return m }

    var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

    for i in 0...m { matrix[i][0] = i }
    for j in 0...n { matrix[0][j] = j }

    for i in 1...m {
        for j in 1...n {
            let cost = a[i - 1] == b[j - 1] ? 0 : 1
            matrix[i][j] = min(
                matrix[i - 1][j] + 1,
                matrix[i][j - 1] + 1,
                matrix[i - 1][j - 1] + cost
            )
        }
    }

    return matrix[m][n]
}
