import SwiftUI

// MARK: - Demo 1 Root View

struct Demo1_EnvironmentClosure: View {
    @State private var mode: DemoMode = .problem

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DemoSegmentPicker(mode: $mode)

                switch mode {
                case .problem:
                    InsightBox(kind: .problem, text: Demo1Strings.problemInsight)
                    MonoCodeView(code: Demo1Strings.problemCode)
                    BadEnvironmentDemo()

                case .solution:
                    InsightBox(kind: .solution, text: Demo1Strings.solutionInsight)
                    MonoCodeView(code: Demo1Strings.solutionCode)
                    GoodEnvironmentDemo()
                }
            }
            .padding()
        }
        .navigationTitle("Demo 1: Environment Closures")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Bad: Unprotected Handler in Environment

struct BadEnvironmentDemo: View {
    @State private var count = 0
    @State private var unrelatedCount = 0
    @State private var isStressRunning = false
    @State private var parentCounter = EvalCounter(view: "Parent", scenario: "Demo1-Bad")

    var body: some View {
        let pEvals = parentCounter.tick()

        VStack(spacing: 16) {
            DemoCard(title: "Parent View", accent: .red) {
                VStack(spacing: 12) {
                    EvalBadge(label: "Parent.body", count: pEvals)

                    Text("\(count)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .contentTransition(.numericText())

                    // New Handler instance on every parent re-render — no @State protection
                    BadEnvChild()
                        .environment(\.unstableAction, Handler {
                            self.count += 1
                        })
                }
            }

            DemoCard(title: "Trigger Unrelated State Changes", accent: .secondary) {
                VStack(spacing: 10) {
                    HStack {
                        Button {
                            unrelatedCount += 1
                        } label: {
                            Label("Single Change", systemImage: "1.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Text("×\(unrelatedCount)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    StressTestButton(isRunning: isStressRunning, changeCount: unrelatedCount) {
                        runStressTest()
                    }
                }
            }
        }
    }

    private func runStressTest() {
        isStressRunning = true
        Task {
            for _ in 0..<50 {
                try? await Task.sleep(for: .milliseconds(40))
                unrelatedCount += 1
            }
            isStressRunning = false
        }
    }
}

struct BadEnvChild: View {
    @Environment(\.unstableAction) private var action
    @State private var counter = EvalCounter(view: "Child", scenario: "Demo1-Bad")

    private static let childCode =
        "@Environment(\\.unstableAction) var action: Handler?\n" +
        "// New Handler instance arrives each parent render\n" +
        "// Identity (===) always differs → body re-evals"

    var body: some View {
        let evals = counter.tick()
        let _ = Self._printChanges()

        DemoCard(title: "Child View (unstableAction)", accent: evals > 5 ? .red : .orange) {
            VStack(alignment: .leading, spacing: 8) {
                MonoCodeView(code: Self.childCode)

                HStack {
                    EvalBadge(label: "BadEnvChild.body", count: evals)
                    Spacer()
                    Button("Increment") { action?() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.red)
                }

                if evals > 5 {
                    Text("Excessive re-evaluations from unrelated changes")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Good: Stable Handler via @State Modifier

struct GoodEnvironmentDemo: View {
    @State private var count = 0
    @State private var unrelatedCount = 0
    @State private var isStressRunning = false
    @State private var parentCounter = EvalCounter(view: "Parent", scenario: "Demo1-Good")

    var body: some View {
        let pEvals = parentCounter.tick()

        VStack(spacing: 16) {
            DemoCard(title: "Parent View", accent: .green) {
                VStack(spacing: 12) {
                    EvalBadge(label: "Parent.body", count: pEvals)

                    Text("\(count)")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .contentTransition(.numericText())

                    // Handler stored in @State — environment always sees the same reference
                    GoodEnvChild()
                        .stableAction(Handler { count += 1 })
                }
            }

            DemoCard(title: "Trigger Unrelated State Changes", accent: .secondary) {
                VStack(spacing: 10) {
                    HStack {
                        Button {
                            unrelatedCount += 1
                        } label: {
                            Label("Single Change", systemImage: "1.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Text("×\(unrelatedCount)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    StressTestButton(isRunning: isStressRunning, changeCount: unrelatedCount) {
                        runStressTest()
                    }
                }
            }

            InsightBox(kind: .tip, text: Demo1Strings.goodDemoTip)
        }
    }

    private func runStressTest() {
        isStressRunning = true
        Task {
            for _ in 0..<50 {
                try? await Task.sleep(for: .milliseconds(40))
                unrelatedCount += 1
            }
            isStressRunning = false
        }
    }
}

struct GoodEnvChild: View {
    @Environment(\.stableAction) private var action
    @State private var counter = EvalCounter(view: "Child", scenario: "Demo1-Good")

    private static let childCode =
        "@Environment(\\.stableAction) var action: Handler?\n" +
        "// Same Handler instance via @State modifier\n" +
        "// Identity (===) unchanged → body skipped"

    var body: some View {
        let evals = counter.tick()
        let _ = Self._printChanges()

        DemoCard(title: "Child View (stableAction)", accent: .green) {
            VStack(alignment: .leading, spacing: 8) {
                MonoCodeView(code: Self.childCode)

                HStack {
                    EvalBadge(label: "GoodEnvChild.body", count: evals)
                    Spacer()
                    Button("Increment") { action?() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.green)
                }

                Text("Stable — body only evaluates on true dependency changes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - String Constants

private enum Demo1Strings {

    static let problemInsight =
        "A **new** `Handler` instance is created on every parent `body` call " +
        "and placed directly into the environment — without `@State` protection. " +
        "Because `Handler` uses reference (identity) equality, each new instance " +
        "compares as *different* from the last. SwiftUI sees the environment changed " +
        "and re-evaluates the child on every parent re-render — even for completely " +
        "unrelated state changes."

    static let problemCode = """
// BAD: New Handler allocated on every parent body call
ChildView()
    .environment(\\.unstableAction, Handler { count += 1 })
    //                               ^^^^^^^^^^^ new object each render
    // Handler uses === equality → always "different" → child re-evals
"""

    static let solutionInsight =
        "Wrap the `Handler` in `@State` inside a `ViewModifier`. " +
        "`@State` is initialised exactly once — subsequent parent re-renders " +
        "pass a new `Handler` to the modifier's `init`, but SwiftUI ignores it " +
        "because `@State` does not reinitialise after first assignment. " +
        "The child always receives the **same** `Handler` reference; identity " +
        "equality succeeds → SwiftUI skips child re-evaluation entirely."

    static let solutionCode = """
// GOOD: @State set once; subsequent parent re-renders ignored
struct StableActionModifier: ViewModifier {
    @State private var handler: Handler   // ← stable class ref

    init(_ h: Handler) {
        _handler = State(initialValue: h) // set on first render only
    }
    func body(content: Content) -> some View {
        content.environment(\\.stableAction, handler)
    }
}
"""

    static let goodDemoTip =
        "After the stress test: Parent.body shows ~52 evaluations. " +
        "GoodEnvChild.body shows 1–2. " +
        "Open Instruments → Points of Interest and filter by 'Demo1-Good' " +
        "to see the empty child timeline against the busy parent timeline."
}
