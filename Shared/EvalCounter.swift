import os
import SwiftUI

/// Counts view body evaluations without triggering re-renders.
///
/// Uses a reference type so mutations are invisible to SwiftUI's observation system.
/// Store as `@State` to persist across struct re-creations.
///
/// Open Instruments → Points of Interest to see each evaluation as a timestamped event,
/// making the difference between bad and good patterns clearly visible in the profiling timeline.
final class EvalCounter {
    private var _count = 0

    // One signposter per scenario so Instruments can filter by category
    private let signposter: OSSignposter

    init(view: String, scenario: String) {
        signposter = OSSignposter(
            subsystem: "com.ClosuresDemo",
            category: "\(scenario).\(view)"
        )
    }

    /// Call at the top of a view's `body`. Returns the updated evaluation count.
    @discardableResult
    func tick() -> Int {
        _count += 1
        // Emits a Point of Interest event visible in Instruments
        let n = _count
        signposter.emitEvent("Body Evaluated", "count=\(n)")
        return _count
    }

    var count: Int { _count }

    func reset() { _count = 0 }
}

// MARK: - Visual Badge

struct EvalBadge: View {
    let label: String
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .imageScale(.small)
            Text("\(label): \(count)×")
                .monospacedDigit()
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.18))
        .foregroundStyle(badgeColor)
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.2), value: count)
    }

    private var badgeColor: Color {
        switch count {
        case 0...2: return .green
        case 3...5: return .orange
        default:    return .red
        }
    }
}
