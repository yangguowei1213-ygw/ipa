import Foundation

/// A small, read-only App Group store suitable for a keyboard extension.
/// The extension should request only the prefix it needs instead of decoding a huge array.
final class SharedWordStore {
    static let shared = SharedWordStore()

    private let defaults: UserDefaults?
    private let key = "customWords"
    private var cachedWords: [String]?

    private init() {
        defaults = UserDefaults(suiteName: "group.com.app.keyboard")
    }

    /// Loads once and drops duplicates/empty values to keep the retained object small.
    func words(limit: Int = 500) -> [String] {
        if let cachedWords { return Array(cachedWords.prefix(limit)) }
        guard let values = defaults?.array(forKey: key) as? [String] else { return [] }
        var result: [String] = []
        result.reserveCapacity(min(values.count, limit))
        var seen = Set<String>()
        for word in values where !word.isEmpty && seen.insert(word).inserted {
            result.append(word)
            if result.count == limit { break }
        }
        cachedWords = result
        return result
    }

    func invalidateCache() {
        cachedWords = nil
    }
}

// Main app example:
// UserDefaults(suiteName: "group.com.app.keyboard")?.set(words, forKey: "customWords")
// UserDefaults(suiteName: "group.com.app.keyboard")?.synchronize() // optional; avoid frequent writes
