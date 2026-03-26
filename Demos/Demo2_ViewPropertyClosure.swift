import SwiftUI

// MARK: - Demo 2 Root View

struct Demo2_ViewPropertyClosure: View {
    @State private var mode: DemoMode = .problem

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DemoSegmentPicker(mode: $mode)

                switch mode {
                case .problem:
                    InsightBox(kind: .problem, text: Demo2Strings.problemInsight)
                    MonoCodeView(code: Demo2Strings.problemCode)
                    BadPropertyClosureDemo()

                case .solution:
                    InsightBox(kind: .solution, text: Demo2Strings.solutionInsight)
                    MonoCodeView(code: Demo2Strings.solutionCode)
                    GoodPropertyClosureDemo()
                }
            }
            .padding()
        }
        .navigationTitle("Demo 2: View Property Closures")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Bad: Three children with raw () -> Void

struct BadPropertyClosureDemo: View {
    @State private var userId = 1
    @State private var draftVersion = 0
    @State private var notificationsOn = true
    @State private var searchText = ""
    @State private var isStressRunning = false
    @State private var parentCounter = EvalCounter(view: "Parent", scenario: "Demo2-Bad")

    var body: some View {
        let pEvals = parentCounter.tick()

        VStack(spacing: 16) {
            DemoCard(title: "Parent View", accent: .red) {
                VStack(spacing: 12) {
                    EvalBadge(label: "Parent.body", count: pEvals)

                    // Raw closures — not Equatable, children always re-evaluate
                    BadFeatureChild(
                        childName: "ProfileCard",
                        dependsOn: "userId",
                        action: { print("Submit userId=\(self.userId)") }
                    )
                    BadFeatureChild(
                        childName: "MessageList",
                        dependsOn: "draftVersion",
                        action: { print("Send draftVersion=\(self.draftVersion)") }
                    )
                    BadFeatureChild(
                        childName: "SettingsRow",
                        dependsOn: "notificationsOn",
                        action: { print("Toggle notificationsOn=\(self.notificationsOn)") }
                    )
                }
            }

            // Unrelated triggers — the smoking gun
            DemoCard(title: "Trigger Unrelated State Changes", accent: .secondary) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Search (unrelated):")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Type anything…", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }
                    StressTestButton(isRunning: isStressRunning, changeCount: 0) {
                        runStressTest()
                    }
                }
            }
        }
    }

    private func runStressTest() {
        isStressRunning = true
        Task {
            for i in 0..<50 {
                try? await Task.sleep(for: .milliseconds(40))
                searchText = "search \(i)"
            }
            isStressRunning = false
        }
    }
}

// MARK: - Good: Three children with Action(stableWhile:) + .equatable()

struct GoodPropertyClosureDemo: View {
    @State private var userId = 1
    @State private var draftVersion = 0
    @State private var notificationsOn = true
    @State private var searchText = ""
    @State private var isStressRunning = false
    @State private var parentCounter = EvalCounter(view: "Parent", scenario: "Demo2-Good")

    var body: some View {
        let pEvals = parentCounter.tick()

        VStack(spacing: 16) {
            DemoCard(title: "Parent View", accent: .green) {
                VStack(spacing: 12) {
                    EvalBadge(label: "Parent.body", count: pEvals)

                    // .equatable() + Action.== gates each body call
                    GoodFeatureChild(
                        childName: "ProfileCard",
                        dependsOn: "userId",
                        action: Action(stableWhile: userId) { [userId] in
                            print("Submit userId=\(userId)")
                        }
                    )
                    .equatable()

                    GoodFeatureChild(
                        childName: "MessageList",
                        dependsOn: "draftVersion",
                        action: Action(stableWhile: draftVersion) { [draftVersion] in
                            print("Send draftVersion=\(draftVersion)")
                        }
                    )
                    .equatable()

                    GoodFeatureChild(
                        childName: "SettingsRow",
                        dependsOn: "notificationsOn",
                        action: Action(stableWhile: notificationsOn) { [notificationsOn] in
                            print("Toggle notificationsOn=\(notificationsOn)")
                        }
                    )
                    .equatable()
                }
            }

            DemoCard(title: "Trigger Unrelated State Changes", accent: .secondary) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Search (unrelated):")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Type anything…", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }
                    StressTestButton(isRunning: isStressRunning, changeCount: 0) {
                        runStressTest()
                    }
                }
            }

            DemoCard(title: "Change a Child's Actual Dependency", accent: .blue) {
                VStack(spacing: 8) {
                    HStack {
                        Text("userId:")
                            .foregroundStyle(.secondary)
                            .frame(width: 130, alignment: .leading)
                        Text("\(userId)")
                            .font(.headline.monospacedDigit())
                        Spacer()
                        Stepper("", value: $userId, in: 1...99)
                            .labelsHidden()
                    }
                    HStack {
                        Text("draftVersion:")
                            .foregroundStyle(.secondary)
                            .frame(width: 130, alignment: .leading)
                        Text("\(draftVersion)")
                            .font(.headline.monospacedDigit())
                        Spacer()
                        Stepper("", value: $draftVersion, in: 0...99)
                            .labelsHidden()
                    }
                    HStack {
                        Text("notificationsOn:")
                            .foregroundStyle(.secondary)
                            .frame(width: 130, alignment: .leading)
                        Spacer()
                        Toggle("", isOn: $notificationsOn)
                            .labelsHidden()
                    }
                }
            }

            InsightBox(kind: .tip, text: Demo2Strings.goodTip)
        }
    }

    private func runStressTest() {
        isStressRunning = true
        Task {
            for i in 0..<50 {
                try? await Task.sleep(for: .milliseconds(40))
                searchText = "search \(i)"
            }
            isStressRunning = false
        }
    }
}

// MARK: - BadFeatureChild: holds () -> Void (not Equatable — always re-evaluates)

struct BadFeatureChild: View {
    let childName: String
    let dependsOn: String
    let action: () -> Void
    @State private var counter: EvalCounter

    init(childName: String, dependsOn: String, action: @escaping () -> Void) {
        self.childName = childName
        self.dependsOn = dependsOn
        self.action = action
        _counter = State(initialValue: EvalCounter(view: childName, scenario: "Demo2-Bad"))
    }

    var body: some View {
        let evals = counter.tick()
        let _ = Self._printChanges()

        DemoCard(title: childName, accent: evals > 3 ? .red : .orange) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    EvalBadge(label: "body", count: evals)
                    Spacer()
                    Button("Execute action closure") { action() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.red)
                }
                if evals > 3 {
                    Label(
                        "\(evals)× re-evaluations — unrelated changes are the cause",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - GoodFeatureChild: Equatable + .equatable() → body only called when dependency changes

struct GoodFeatureChild: View {
    let childName: String
    let dependsOn: String
    let action: Action
    @State private var counter: EvalCounter

    init(childName: String, dependsOn: String, action: Action) {
        self.childName = childName
        self.dependsOn = dependsOn
        self.action = action
        _counter = State(initialValue: EvalCounter(view: childName, scenario: "Demo2-Good"))
    }

    private var childCode: String {
        "let action: Action  // Equatable via stableWhile \n" +
        "// .equatable() gates body: skipped unless \(dependsOn) changes"
    }

    var body: some View {
        let evals = counter.tick()
        let _ = Self._printChanges()

        DemoCard(title: childName, accent: .green) {
            VStack(alignment: .leading, spacing: 8) {
                MonoCodeView(code: childCode)
                HStack {
                    EvalBadge(label: "body", count: evals)
                    Spacer()
                    Button("Execute action closure") { action() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.green)
                }
                Label(
                    "Stable — body skipped unless \(dependsOn) changes",
                    systemImage: "lock.fill"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

// @preconcurrency suppresses Swift 6 cross-actor-isolation error:
// SwiftUI always calls == on the main actor (via EquatableView), so no real data race.
extension GoodFeatureChild: @preconcurrency Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.childName == rhs.childName &&
        lhs.dependsOn == rhs.dependsOn &&
        lhs.action == rhs.action
        // @State counter intentionally excluded — SwiftUI manages it separately
    }
}

// MARK: - String Constants

private enum Demo2Strings {

    static let problemInsight =
        "Each child holds `let action: () -> Void`. " +
        "Because closures aren't `Equatable`, SwiftUI **cannot diff** them — " +
        "it always assumes the child's input changed and calls `body` again. " +
        "Every closure also implicitly captures `self`, " +
        "so ANY parent state change produces a brand-new closure instance " +
        "and forces ALL three children to re-evaluate — " +
        "even when none of them care about what changed."

    static let problemCode = """
// Three children, each holding () -> Void (not Equatable)
ProfileCard(action: { submit(self.userId) })
MessageList(action: { send(self.draftVersion) })
SettingsRow(action: { toggle(self.notificationsOn) })

// Any unrelated keystroke → parent re-renders
//   → 3 new closure instances (can't compare)
//   → SwiftUI cannot diff → assumes ALL 3 changed
//   → ALL 3 children re-evaluate on every keystroke
"""

    static let solutionInsight =
        "Replace `() -> Void` with `Action(stableWhile:)`. " +
        "`Action` conforms to `Equatable` via its `stableWhile` dependency key. " +
        "Pairing this with `.equatable()` tells SwiftUI: " +
        "**use `==` to gate this view's `body` call**. " +
        "When `stableWhile` hasn't changed, `Action.==` returns `true`, " +
        "SwiftUI skips the child's `body` entirely — " +
        "zero wasted work, zero re-evaluations."

    static let solutionCode = """
// Action declares its exact dependency
ProfileCard(
    action: Action(stableWhile: userId) { [userId] in submit(userId) }
).equatable()  // <- gates body on Action.== result

MessageList(
    action: Action(stableWhile: draftVersion) { ... }
).equatable()

SettingsRow(
    action: Action(stableWhile: notificationsOn) { ... }
).equatable()

// Unrelated keystroke → stableWhile unchanged for all 3
//   → Action.== returns true → SwiftUI skips ALL 3 body calls
"""

    static let badTip =
        "**Run Stress Test** — watch all three child badges climb to 50+, " +
        "even though none of their actions care about the unrelated changes. " +
        "Then try typing in the Search field — every keystroke re-evaluates all three."

    static let goodTip =
        "**Run Stress Test** — parent climbs to 52×, all three children stay at 1×. " +
        "Typing in Search still does nothing to the children. " +
        "Now change a Stepper or Toggle — only the matching child re-evaluates."
}
