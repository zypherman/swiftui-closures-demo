import SwiftUI

// MARK: - Demo 4 Root View

struct Demo4_CompoundEffect: View {
    @State private var mode: DemoMode = .problem

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DemoSegmentPicker(mode: $mode)

                switch mode {
                case .problem:
                    InsightBox(kind: .problem, text: Demo4Strings.problemInsight)
                    MonoCodeView(code: Demo4Strings.problemCode)
                    BadCompoundDemo()

                case .solution:
                    InsightBox(kind: .solution, text: Demo4Strings.solutionInsight)
                    MonoCodeView(code: Demo4Strings.solutionCode)
                    GoodCompoundDemo()
                }
            }
            .padding()
        }
        .navigationTitle("Demo 4: Compound Effect")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared UI Component

struct StatePill: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption2.monospacedDigit().weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Bad: Compound Effect Demo

struct BadCompoundDemo: View {
    // 8 independent state fields — simulating a real feature module
    @State private var messageCount = 0
    @State private var notificationCount = 0
    @State private var score = 0
    @State private var selectedTab = 0
    @State private var volumeLevel: Double = 0.5
    @State private var isSyncing = false
    @State private var filterQuery = ""
    @State private var primaryValue = 0   // what the child action actually cares about

    @State private var parentCounter = EvalCounter(view: "Parent", scenario: "Demo4-Bad")
    @State private var isStressRunning = false

    var body: some View {
        let pEvals = parentCounter.tick()

        VStack(spacing: 16) {
            DemoCard(title: "Parent View — 8 State Fields", accent: .red) {
                VStack(spacing: 12) {
                    EvalBadge(label: "Parent.body", count: pEvals)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 6
                    ) {
                        StatePill(label: "Msgs", value: "\(messageCount)")
                        StatePill(label: "Notif", value: "\(notificationCount)")
                        StatePill(label: "Score", value: "\(score)")
                        StatePill(label: "Tab", value: "\(selectedTab)")
                        StatePill(label: "Vol", value: String(format: "%.0f%%", volumeLevel * 100))
                        StatePill(label: "Sync", value: isSyncing ? "On" : "Off")
                    }

                    Divider()

                    // New () -> Void on every parent re-render — not Equatable
                    BadCompoundChild(action: {
                        print("primaryValue is \(self.primaryValue)")
                    })
                }
            }

            DemoCard(title: "Trigger Independent State Changes", accent: .secondary) {
                VStack(spacing: 8) {
                    Text("Each button updates a different field — none affect the child's action")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        Button("+ Message") { messageCount += 1 }
                            .buttonStyle(.bordered)
                        Button("+ Notification") { notificationCount += 1 }
                            .buttonStyle(.bordered)
                        Button("+ Score") { score += 10 }
                            .buttonStyle(.bordered)
                        Button("Next Tab") { selectedTab = (selectedTab + 1) % 5 }
                            .buttonStyle(.bordered)
                    }

                    StressTestButton(
                        isRunning: isStressRunning,
                        changeCount: messageCount + notificationCount + score
                    ) { runStressTest() }
                }
            }
        }
    }

    private func runStressTest() {
        isStressRunning = true
        Task {
            for i in 0..<50 {
                try? await Task.sleep(for: .milliseconds(40))
                switch i % 7 {
                case 0: messageCount += 1
                case 1: notificationCount += 1
                case 2: score += 5
                case 3: selectedTab = (selectedTab + 1) % 5
                case 4: volumeLevel = Double.random(in: 0.2...0.9)
                case 5: isSyncing.toggle()
                default: filterQuery = "q\(i)"
                }
            }
            isStressRunning = false
        }
    }
}

struct BadCompoundChild: View {
    let action: () -> Void
    @State private var counter = EvalCounter(view: "Child", scenario: "Demo4-Bad")

    var body: some View {
        let evals = counter.tick()
        let _ = Self._printChanges()

        DemoCard(title: "Child View — let action: () → Void", accent: evals > 10 ? .red : .orange) {
            VStack(spacing: 10) {
                EvalBadge(label: "BadCompoundChild.body", count: evals)

                if evals > 10 {
                    Text("\(evals) re-evaluations from unrelated state changes")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Tap the parent buttons or run the stress test")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button("Log Primary Value") { action() }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
            }
        }
    }
}

// MARK: - Good: Action(stableWhile:) with Large Parent

struct GoodCompoundDemo: View {
    @State private var messageCount = 0
    @State private var notificationCount = 0
    @State private var score = 0
    @State private var selectedTab = 0
    @State private var volumeLevel: Double = 0.5
    @State private var isSyncing = false
    @State private var filterQuery = ""
    @State private var primaryValue = 0   // the child's only real dependency

    @State private var parentCounter = EvalCounter(view: "Parent", scenario: "Demo4-Good")
    @State private var isStressRunning = false

    var body: some View {
        let pEvals = parentCounter.tick()

        VStack(spacing: 16) {
            DemoCard(title: "Parent View — 8 State Fields", accent: .green) {
                VStack(spacing: 12) {
                    EvalBadge(label: "Parent.body", count: pEvals)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 6
                    ) {
                        StatePill(label: "Msgs", value: "\(messageCount)")
                        StatePill(label: "Notif", value: "\(notificationCount)")
                        StatePill(label: "Score", value: "\(score)")
                        StatePill(label: "Tab", value: "\(selectedTab)")
                        StatePill(label: "Vol", value: String(format: "%.0f%%", volumeLevel * 100))
                        StatePill(label: "Sync", value: isSyncing ? "On" : "Off")
                    }

                    Divider()

                    // .equatable() + Action.== gates body: skipped unless primaryValue changes
                    GoodCompoundChild(
                        action: Action(stableWhile: primaryValue) { [primaryValue] in
                            print("primaryValue is \(primaryValue)")
                        }
                    )
                    .equatable()
                }
            }

            DemoCard(title: "Trigger Independent State Changes", accent: .secondary) {
                VStack(spacing: 8) {
                    Text("Same 8-field parent. Watch the child badge stay at 1×.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        Button("+ Message") { messageCount += 1 }
                            .buttonStyle(.bordered)
                        Button("+ Notification") { notificationCount += 1 }
                            .buttonStyle(.bordered)
                        Button("+ Score") { score += 10 }
                            .buttonStyle(.bordered)
                        Button("Next Tab") { selectedTab = (selectedTab + 1) % 5 }
                            .buttonStyle(.bordered)
                    }

                    StressTestButton(
                        isRunning: isStressRunning,
                        changeCount: messageCount + notificationCount + score
                    ) { runStressTest() }
                }
            }

            InsightBox(kind: .tip, text: Demo4Strings.goodTip)

            // Allow demonstrating that the child DOES re-evaluate when its real dependency changes
            DemoCard(title: "Update the Child's Real Dependency", accent: .blue) {
                HStack {
                    Text("primaryValue:")
                        .foregroundStyle(.secondary)
                    Text("\(primaryValue)")
                        .font(.headline.monospacedDigit())
                    Spacer()
                    Stepper("", value: $primaryValue)
                        .labelsHidden()
                }
            }
        }
    }

    private func runStressTest() {
        isStressRunning = true
        Task {
            for i in 0..<50 {
                try? await Task.sleep(for: .milliseconds(40))
                switch i % 7 {
                case 0: messageCount += 1
                case 1: notificationCount += 1
                case 2: score += 5
                case 3: selectedTab = (selectedTab + 1) % 5
                case 4: volumeLevel = Double.random(in: 0.2...0.9)
                case 5: isSyncing.toggle()
                default: filterQuery = "q\(i)"
                }
            }
            isStressRunning = false
        }
    }
}

struct GoodCompoundChild: View {
    let action: Action
    @State private var counter = EvalCounter(view: "Child", scenario: "Demo4-Good")

    var body: some View {
        let evals = counter.tick()
        let _ = Self._printChanges()

        DemoCard(title: "Child View — let action: Action (Equatable)", accent: .green) {
            VStack(spacing: 10) {
                EvalBadge(label: "GoodCompoundChild.body", count: evals)

                Text("Only re-evaluates when primaryValue changes — all other parent churn ignored")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Log Primary Value") { action() }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
            }
        }
    }
}

// @preconcurrency: SwiftUI always calls == on the main actor via EquatableView — no real data race.
extension GoodCompoundChild: @preconcurrency Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.action == rhs.action
    }
}

// MARK: - String Constants

private enum Demo4Strings {

    static let problemInsight =
        "In real feature modules, a parent owns many independent pieces of " +
        "state. Every state change re-renders the parent, which passes a new " +
        "`() -> Void` closure to each child. Because closures are not " +
        "`Equatable`, SwiftUI cannot diff them — so **every child re-evaluates " +
        "on every parent re-render**, even when none of the child's actual " +
        "dependencies changed. With 8 state fields and 50 rapid updates, " +
        "the wasted evaluation count compounds quickly."

    static let problemCode = """
// Parent with 8 independent state fields
struct FeatureParent: View {
    @State var messages = 0      @State var score = 0
    @State var notifications = 0 @State var volume = 0.5
    @State var filterText = ""   @State var tab = 0
    @State var isSyncing = false @State var userName = "…"

    var body: some View {
        ChildView(action: { print(primaryValue) })
        //                   ^^^ new closure each render
        //        () -> Void not Equatable → child always re-evals
    }
}
"""

    static let solutionInsight =
        "Replace `() -> Void` with `Action(stableWhile:)`. SwiftUI compares " +
        "child view structs before deciding to call `body`. Because `Action` " +
        "is `Equatable` via its `stableWhile` dependency, SwiftUI can detect " +
        "that the child's input is **unchanged** and skip evaluation entirely. " +
        "After 50 unrelated state changes, the child stays at 1 evaluation."

    static let solutionCode = """
// Same parent — same 8 state fields
struct FeatureParent: View {
    // ...
    @State var primaryValue = 0   // child's only real dependency

    var body: some View {
        ChildView(
            action: Action(stableWhile: primaryValue) { [primaryValue] in
                print(primaryValue)  // explicit capture = clear dependency
            }
        )
        // Action.== compares stableWhile only
        // Unchanged → SwiftUI skips ChildView.body entirely
    }
}
"""

    static let goodTip =
        "After the stress test: Parent.body shows ~52 evaluations. " +
        "GoodCompoundChild.body shows 1. " +
        "Use the Stepper to update `primaryValue` — now the child " +
        "re-evaluates because its actual dependency changed."
}
