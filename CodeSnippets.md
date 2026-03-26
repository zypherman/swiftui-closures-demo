# Code Snippets Reference — Passing Closures in SwiftUI

Quick-reference for all patterns covered in the presentation.

---

## 1. The Problem: Raw Closure in EnvironmentValues

```swift
// ❌ New closure allocated on every parent body call
// Swift can't compare () -> Void → SwiftUI assumes "changed" → child re-evals
private struct ActionKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var tapAction: (() -> Void)? {
        get { self[ActionKey.self] }
        set { self[ActionKey.self] = newValue }
    }
}

struct ParentView: View {
    @State private var count = 0
    @State private var unrelated = 0

    var body: some View {
        ChildView()
            .environment(\.tapAction) { count += 1 }
            // ↑ New closure on every body call.
            // When `unrelated` changes → parent re-renders → new closure
            // → SwiftUI: "environment changed?" → can't know → re-eval ChildView
    }
}
```

**Observable symptom:** Add `let _ = Self._printChanges()` to `ChildView.body`. It fires on every parent state change, even unrelated ones.

---

## 2. The Fix: Handler Class + @State Modifier

```swift
// ✅ Stable closure wrapper using class semantics
final class Handler {
    let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    func callAsFunction() { action() }
}

// Environment key for the stable handler
private struct StableActionKey: EnvironmentKey {
    static let defaultValue: Handler? = nil
}

extension EnvironmentValues {
    var stableAction: Handler? {
        get { self[StableActionKey.self] }
        set { self[StableActionKey.self] = newValue }
    }
}

// The modifier stores the handler in @State — set once, never replaced
struct StableActionModifier: ViewModifier {
    @State private var handler: Handler

    init(_ handler: Handler) {
        _handler = State(initialValue: handler)  // Only set on first init
    }

    func body(content: Content) -> some View {
        content.environment(\.stableAction, handler)
        // handler is always the SAME class instance → SwiftUI: "no change" → skip child re-eval
    }
}

extension View {
    func stableAction(_ handler: Handler) -> some View {
        modifier(StableActionModifier(handler))
    }
}

// Usage — child body no longer re-evaluates when `unrelated` changes
struct ParentView: View {
    @State private var count = 0
    @State private var unrelated = 0

    var body: some View {
        ChildView()
            .stableAction(Handler { count += 1 })
    }
}
```

**Why `@State` works here:** `@State` does not reinitialize when its owning struct is recreated. Subsequent calls to `init(_ handler:)` provide a new `Handler`, but `State(initialValue:)` was already initialized — it ignores the new value. The child always receives the original class instance.

---

## 3. The Problem: Raw Closure as View Property

```swift
// ❌ () -> Void is not Equatable
// SwiftUI cannot determine if ChildView changed → always re-evaluates body
struct ChildView: View {
    let action: () -> Void   // Not Equatable → SwiftUI assumes "changed"
    var body: some View { ... }
}

// In parent:
ChildView(action: { print(self.importantValue) })
//                 ^^^^ implicit self — depends on ALL parent state
// Typing in an unrelated TextField → parent re-renders → child.action is "new" → body re-evals
```

---

## 4. Partial Improvement: Explicit Capture List

```swift
// 🟡 Better readability, narrows intent — but doesn't solve SwiftUI diffing alone
ChildView(action: { [importantValue] in
    print(importantValue)
})
// Apple's recommendation: "capture only the properties you actually need"
// Still passes () -> Void → SwiftUI still can't compare → child still re-evals
// Value: code clarity, compiler optimization hints, prevents accidental self retention
```

---

## 5. The Fix: Equatable Action Struct

```swift
// ✅ Equatable via an explicit dependency key
struct Action: Equatable {
    let stableWhile: AnyHashable   // The dependency that controls equality
    private let work: () -> Void

    init<H: Hashable>(stableWhile dependency: H, _ work: @escaping () -> Void) {
        stableWhile = AnyHashable(dependency)
        self.work = work
    }

    func callAsFunction() { work() }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.stableWhile == rhs.stableWhile  // Equal when dependency unchanged
    }
}

// Child view now holds an Equatable property
struct ChildView: View {
    let action: Action   // Equatable → SwiftUI can diff correctly
    var body: some View { ... }
}

// Parent — child body only re-evals when importantValue changes
struct ParentView: View {
    @State private var importantValue = 0
    @State private var inputText = ""   // Unrelated

    var body: some View {
        ChildView(
            action: Action(stableWhile: importantValue) { [importantValue] in
                print(importantValue)
            }
        )
        TextField("Unrelated", text: $inputText)
        // Typing here → parent re-renders → Action(stableWhile: importantValue) created
        // importantValue unchanged → old Action == new Action → SwiftUI skips child body
    }
}
```

---

## 6. Staleness Trade-off (Handler pattern)

```swift
// ✅ Safe: @State captures a reference to SwiftUI's storage
// Even though the handler is set once, it reads the CURRENT count each call
.stableAction(Handler { count += 1 })

// ⚠️ Risky: if threshold is a local constant captured by value at first render
let threshold = computedThreshold   // Might become stale
.stableAction(Handler { if value > threshold { count += 1 } })

// ✅ Fix: use Action(stableWhile:) so handler refreshes when threshold changes
ChildView(
    action: Action(stableWhile: threshold) { [threshold] in
        if value > threshold { count += 1 }
    }
)
```

---

## 7. Self._printChanges() — Debug Re-evaluations

```swift
struct ChildView: View {
    var body: some View {
        let _ = Self._printChanges()   // Prints to Xcode console why body ran
        // Example output:
        // "ChildView: @self, @identity, action changed."
        //              ^^^^^ means SOMETHING about self changed — often a closure
        Button("Tap") { action() }
    }
}
```

---

## 8. XCTest Performance Baseline

```swift
func testEquatableActionMinimizesReevaluations() {
    struct EquatableChild: Equatable {
        let dependency: Int
        let closure: () -> Void
        static func == (lhs: Self, rhs: Self) -> Bool { lhs.dependency == rhs.dependency }
    }

    var evalCount = 0
    var lastChild = EquatableChild(dependency: 0, closure: {})

    for i in 0..<100 {
        let newChild = EquatableChild(dependency: i / 10, closure: {})
        if newChild != lastChild { evalCount += 1; lastChild = newChild }
    }

    XCTAssertEqual(evalCount, 10)   // 10× fewer re-evals vs raw closure
}

// After running: click the clock icon → "Set Baseline"
// CI will now fail if this regresses beyond 10% tolerance
```

---

## 9. OSSignposter — Instruments Integration

```swift
// In EvalCounter.swift
final class EvalCounter {
    private var _count = 0
    private let signposter: OSSignposter

    init(view: String, scenario: String) {
        signposter = OSSignposter(
            subsystem: "com.ClosuresDemo",
            category: "\(scenario).\(view)"
        )
    }

    @discardableResult
    func tick() -> Int {
        _count += 1
        let n = _count
        signposter.emitEvent("Body Evaluated", "count=\(n)")
        return _count
    }
}

// In a view's body:
struct ChildView: View {
    @State private var counter = EvalCounter(view: "Child", scenario: "Demo1-Bad")

    var body: some View {
        let evals = counter.tick()   // Emits Point of Interest event
        // ...
    }
}

// In Instruments:
// 1. ⌘I → Time Profiler template
// 2. Add "Points of Interest" instrument
// 3. Filter subsystem: com.ClosuresDemo
// 4. Each dot = one body evaluation
// Bad child: 50+ dots | Good child: 1-2 dots
```

---

## 10. Apple's DismissAction — The Blueprint

```swift
// Apple's implementation (conceptual — internal to SwiftUI):
public struct DismissAction {
    internal let action: () -> ()
    public func callAsFunction() { action() }
}

// Stored in environment via @State in a system modifier — exactly our Handler pattern.
// Our Handler replicates this:

final class Handler {
    let action: () -> Void
    func callAsFunction() { action() }
}
// + StableActionModifier with @State private var handler: Handler
```

---

## Quick Decision Guide

```
Which pattern do I need?
│
├─ Passing closure through environment (deep nesting)?
│  └─ Handler (class) + StableActionModifier (@State)
│
├─ Closure as child view property, parent has unrelated state?
│  └─ Action: Equatable with stableWhile dependency key
│
├─ Simple leaf view, parent rarely re-renders?
│  └─ Direct () -> Void — negligible overhead, keep it simple
│
└─ Both environment AND equatable needed?
   └─ Combine: wrap Action in a StableActionModifier
```
