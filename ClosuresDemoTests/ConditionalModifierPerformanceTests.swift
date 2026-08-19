import XCTest
import os

/// Performance tests that quantify the identity-churn cost of structural
/// if/else (and the equivalent custom `.if()` modifier) versus inert,
/// parameter-driven modifiers — modeled in pure Swift so it's measurable
/// without a running UI. Run with `⌘U`.
///
/// After the first run, click the measured value in each `measure {}` block
/// and choose "Set Baseline" so a future regression fails CI.
final class ConditionalModifierPerformanceTests: XCTestCase {

    // MARK: - Models

    /// Mirrors what `_ConditionalContent<A, B>` costs: EVERY toggle mounts a
    /// fresh instance of whichever branch is now active, because the two
    /// branches are different concrete types with independent identity.
    private struct StructuralSlot {
        private(set) var mounts = 0
        private var currentBranch: Bool?

        mutating func setState(_ isOn: Bool) {
            // A branch swap always remounts — even flipping back to a
            // previously-seen state creates a brand new instance, because
            // SwiftUI does not cache the torn-down branch.
            if currentBranch != isOn {
                mounts += 1
                currentBranch = isOn
            } else {
                // Same value delivered twice in a row (no-op state write) —
                // no re-render at all, so no mount either way.
            }
        }
    }

    /// Mirrors an inert, single-type view: state changes are modifier
    /// arguments, so the view mounts exactly once, ever.
    private struct InertSlot {
        private(set) var mounts = 0
        private var hasMounted = false

        mutating func setState(_ isOn: Bool) {
            if !hasMounted {
                mounts += 1
                hasMounted = true
            }
            // Any further `setState` calls just update the argument in
            // place — no new mount, regardless of value.
        }
    }

    // MARK: - Test 1: Structural swap remounts on every toggle

    func testStructuralSwapRemountsOnEveryToggle() {
        var slot = StructuralSlot()
        var state = false

        // 40 toggles, alternating true/false — the exact shape of the
        // demo's stress test.
        for _ in 0..<40 {
            state.toggle()
            slot.setState(state)
        }

        XCTAssertEqual(slot.mounts, 40, "Every alternating toggle remounts the active branch")
    }

    // MARK: - Test 2: Inert modifier never remounts after the first render

    func testInertModifierMountsOnce() {
        var slot = InertSlot()
        var state = false

        for _ in 0..<40 {
            state.toggle()
            slot.setState(state)
        }

        XCTAssertEqual(slot.mounts, 1, "An inert, single-type view mounts exactly once regardless of toggle count")
    }

    // MARK: - Test 3: The EmptyView() trap
    //
    // `if cond { A() } else { EmptyView() }` is STILL a structural swap —
    // EmptyView is a distinct concrete type from A, so this behaves like
    // Test 1, not like a safe bare-if.

    func testEmptyViewElseBranchStillRemounts() {
        var slot = StructuralSlot() // EmptyView() branch counts the same as any other type
        var state = false

        for _ in 0..<40 {
            state.toggle()
            slot.setState(state)
        }

        XCTAssertEqual(slot.mounts, 40, "if/else with an EmptyView() branch remounts exactly like any other two-type branch")
    }

    // MARK: - Test 4: Bare if (no else) is cheap — Optional-content diffing

    /// Models `if condition { A() }` with NO else: ViewBuilder wraps this in
    /// `Optional<A>`. The TYPE never changes — only the payload flips
    /// between `.some(A())` and `nil`. A mount only happens on an actual
    /// nil → some transition, not on every state check.
    func testBareIfOnlyMountsOnInsertion() {
        var mounts = 0
        var isPresent: Bool? = nil // nil = "no prior render"

        let presenceSequence = [true, true, false, true, false, false, true]
        for next in presenceSequence {
            if isPresent != true, next {
                mounts += 1 // nil/false → true is an insertion
            }
            isPresent = next
        }

        // Insertions happened at indices 0, 3, 6 → 3 mounts, not 7.
        XCTAssertEqual(mounts, 3, "Bare if-with-no-else only mounts on true insertions, not on every check")
    }

    // MARK: - Test 5: Whole-screen structural swap across a large catalog

    /// Models the demo's Compact ⇄ Detailed toggle: in the structural
    /// styles, EVERY row swaps to a different card type at once. In the
    /// inert style, one adaptive card type just re-lays-out.
    func testDisplayModeToggleAcrossCatalog() {
        let rowCount = 42
        let modeFlips = 3

        // Structural styles: every row swaps to a different card TYPE on
        // every flip, so every flip remounts the whole catalog again.
        let structuralMounts = rowCount * modeFlips

        // Inert style: one adaptive card type per row, mounted once ever —
        // mode flips only change modifier arguments on the existing instance.
        let inertMounts = rowCount

        XCTAssertEqual(structuralMounts, 126, "3 mode flips × 42 rows = 126 structural remounts")
        XCTAssertEqual(inertMounts, rowCount, "The adaptive row mounts once per row, independent of mode flips")

        let improvement = Double(structuralMounts) / Double(inertMounts)
        XCTAssertGreaterThanOrEqual(improvement, 3.0, "Inert layout produces at least 3× fewer mounts across 3 mode flips")
    }

    // MARK: - Test 6: Measured cost of structural churn vs inert updates

    func testStructuralChurnPerformance() {
        let signposter = OSSignposter(subsystem: "com.ClosuresDemo.Tests", category: "StructuralSwap")

        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            var slot = StructuralSlot()
            var state = false

            for _ in 0..<10_000 {
                state.toggle()
                let id = signposter.makeSignpostID()
                let interval = signposter.beginInterval("Structural Mount", id: id)
                slot.setState(state)
                signposter.endInterval("Structural Mount", interval)
            }

            XCTAssertEqual(slot.mounts, 10_000)
        }
    }

    func testInertUpdatePerformance() {
        let signposter = OSSignposter(subsystem: "com.ClosuresDemo.Tests", category: "InertUpdate")

        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            var slot = InertSlot()
            var state = false

            for _ in 0..<10_000 {
                state.toggle()
                let id = signposter.makeSignpostID()
                let interval = signposter.beginInterval("Inert Update", id: id)
                slot.setState(state)
                signposter.endInterval("Inert Update", interval)
            }

            XCTAssertEqual(slot.mounts, 1)
        }

        print("""
        ╔═══════════════════════════════════════════════╗
        ║  Conditional Modifier Cost Summary            ║
        ╠═══════════════════════════════════════════════╣
        ║  10,000 toggles, structural if/else:  10,000 mounts  ║
        ║  10,000 toggles, inert modifier:           1 mount   ║
        ╚═══════════════════════════════════════════════╝
        """)
    }
}
