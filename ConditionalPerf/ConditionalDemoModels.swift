import SwiftUI
import os

// MARK: - Demo Item

/// A catalog card used to demonstrate structural (if/else) vs. inert-modifier
/// conditional rendering in a realistically-sized SwiftUI list.
struct ConditionalDemoItem: Identifiable, Equatable {
    let id: Int
    let name: String
    let subtitle: String
    let category: Category
    let rating: Int            // 0...5. 0 = "no rating yet" (bare-if / nil-case slot)
    let price: Double
    var discountPercent: Int?  // nil = no discount

    var isOnline: Bool
    var inStock: Bool
    var isFavorite: Bool
    var isSelected: Bool
    var isExpanded: Bool

    let isPremium: Bool        // static flourish — bare-if / nil-case slot everywhere
    let isNew: Bool            // static flourish — bare-if / nil-case slot everywhere

    enum Category: String, CaseIterable {
        case audio = "Audio"
        case wearables = "Wearables"
        case home = "Home"
        case outdoors = "Outdoors"
        case office = "Office"

        var symbolName: String {
            switch self {
            case .audio: "headphones"
            case .wearables: "applewatch"
            case .home: "house.fill"
            case .outdoors: "mountain.2.fill"
            case .office: "desktopcomputer"
            }
        }

        var tint: Color {
            switch self {
            case .audio: .purple
            case .wearables: .pink
            case .home: .orange
            case .outdoors: .green
            case .office: .blue
            }
        }
    }
}

// MARK: - Deterministic Catalog Generator

/// A tiny xorshift64* generator so the demo catalog is identical on every launch —
/// reproducible numbers make for a reliable live demo and stable before/after screenshots.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 2685821657736338717
    }
}

extension ConditionalDemoItem {
    /// Generates a semi-detailed, realistically-sized catalog (default 42 cards).
    /// Large enough that the cost of tearing down and rebuilding view identity
    /// is visible on-screen and in Instruments, not just in theory.
    static func makeCatalog(count: Int = 42, seed: UInt64 = 20_260_819) -> [ConditionalDemoItem] {
        var rng = SeededGenerator(seed: seed)
        let adjectives = ["Aurora", "Nimbus", "Cobalt", "Ridge", "Solstice", "Ember", "Quartz", "Lumen", "Drift", "Basalt", "Halo", "Cascade"]
        let nouns = ["Buds", "Tracker", "Hub", "Lamp", "Pack", "Station", "Monitor", "Speaker", "Case", "Dock", "Mount", "Sensor"]

        var items: [ConditionalDemoItem] = []
        items.reserveCapacity(count)

        for i in 0..<count {
            let category = Category.allCases.randomElement(using: &rng) ?? .audio
            let adjective = adjectives.randomElement(using: &rng) ?? "Aurora"
            let noun = nouns.randomElement(using: &rng) ?? "Hub"
            let rating = Int.random(in: 0...5, using: &rng)
            let hasDiscount = Double.random(in: 0...1, using: &rng) < 0.3

            items.append(
                ConditionalDemoItem(
                    id: i,
                    name: "\(adjective) \(noun)",
                    subtitle: "\(category.rawValue) · \(rating > 0 ? "Customer favorite" : "New arrival")",
                    category: category,
                    rating: rating,
                    price: Double(Int.random(in: 20...240, using: &rng)),
                    discountPercent: hasDiscount ? Int.random(in: 10...40, using: &rng) : nil,
                    isOnline: Double.random(in: 0...1, using: &rng) < 0.5,
                    inStock: Double.random(in: 0...1, using: &rng) < 0.8,
                    isFavorite: false,
                    isSelected: false,
                    isExpanded: false,
                    isPremium: Double.random(in: 0...1, using: &rng) < 0.15,
                    isNew: Double.random(in: 0...1, using: &rng) < 0.2
                )
            )
        }
        return items
    }
}

// MARK: - Display Mode

/// The screen-wide layout condition. In the structural demos, flipping this
/// swaps EVERY row to a different view type all at once — the single most
/// dramatic example of identity churn in the whole demo.
enum ProductDisplayMode: String, CaseIterable, Identifiable {
    case detailed = "Detailed"
    case compact = "Compact"
    var id: String { rawValue }
}

// MARK: - Perf Metrics

/// Aggregates two honest, narrowly-scoped signals across a whole screen:
///
/// - `mounts`: how many times a conditionally-swapped leaf view's `onAppear`
///   fired. Because `onAppear` only fires when a view is freshly inserted into
///   the tree, this is a direct, measurable proxy for identity loss — NOT a
///   proxy for "body was called" (a row's own body runs on every relevant
///   state change regardless of style; identity loss is about what happens
///   to its *children*).
/// - `bodyEvaluations`: raw count of row `body` calls, useful as a sanity
///   check that both styles are being driven by the same amount of state churn.
///
/// Also emits an `OSSignposter` event per call so the same numbers are visible
/// as Points of Interest in Instruments — filter by the `scenario` category to
/// compare styles side-by-side on the same timeline.
final class ConditionalPerfMetrics {
    private(set) var mounts = 0
    private(set) var bodyEvaluations = 0
    private let signposter: OSSignposter

    init(scenario: String) {
        signposter = OSSignposter(subsystem: "com.ClosuresDemo.ConditionalPerf", category: scenario)
    }

    @discardableResult
    func recordMount() -> Int {
        mounts += 1
        signposter.emitEvent("Leaf Mounted", "n=\(mounts)")
        return mounts
    }

    @discardableResult
    func recordBodyEval() -> Int {
        bodyEvaluations += 1
        signposter.emitEvent("Row Body Evaluated", "n=\(bodyEvaluations)")
        return bodyEvaluations
    }

    func reset() {
        mounts = 0
        bodyEvaluations = 0
    }
}

// MARK: - Duration Helper

extension Duration {
    /// Wall-clock milliseconds, used to show a real, on-screen stopwatch
    /// reading for the stress test — no Instruments required for a live demo.
    var milliseconds: Double {
        let c = components
        return Double(c.seconds) * 1000 + Double(c.attoseconds) / 1_000_000_000_000_000
    }
}
