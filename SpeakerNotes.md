# Speaker Notes: Passing Closures in SwiftUI
**Audience:** Senior iOS Engineers | **Duration:** 20–30 min

---

## Slide / Section: Hook — "The Invisible Tax" (2 min)

**Open with:**
> "Closures are everywhere in SwiftUI. Every button, every gesture, every action sheet dismiss. We write them by reflex. But they carry a hidden cost that doesn't show up in code review — and it compounds silently across your entire view hierarchy."

**Key points:**
- This isn't a rare edge case. It hits any view that: (a) reads a closure from the environment, or (b) holds a closure as a view property and has a parent with unrelated state.
- The problem is invisible in previews. You only see it under real state churn — during typing, scroll, animation.

**Transition:** "Let's understand why this happens before looking at solutions."

---

## Slide / Section: SwiftUI's Update Model (3 min)

**Key points:**
1. **Body evaluation ≠ screen render.** Body calls are cheap struct allocations. The render (diffing + GPU) only happens when the result actually changes. But body evaluations are NOT free — they add up under heavy state churn.
2. **How SwiftUI decides to re-evaluate a child's body:**
   - Child has `@State`/`@Observable` that changed → re-eval
   - Child reads from `@Environment` that changed → re-eval
   - Parent re-renders AND child's "view struct" changed → re-eval
   - For that last case: SwiftUI compares child view structs. This requires `Equatable`. Closures aren't Equatable.

**Key quote from Apple (WWDC Optimization Q&A):**
> "Try to capture as little as possible in closures — capturing self depends on the whole view value, not just the property you need."

**Demo:** Open the Xcode console. Show `Self._printChanges()` output for a view that re-evaluates unexpectedly. (`print("🔴 ChildView body")` also works for a cleaner demo.)

---

## Slide / Section: Demo 1 — Closures in Environment (5 min)

**Setup:** Open Demo 1 in the running app. Switch to "❌ Problem" tab.

**Explain the problem:**
- We have a parent with two pieces of state: `count` and `unrelatedCount`.
- The child reads `rawAction` from the environment — a `() -> Void`.
- Watch the child's eval badge. Hit "Single Change" a few times. The child re-evals **every time** even though its action is just `{ count += 1 }`.

**Why:**
```swift
// New closure object on every parent body call
.environment(\.rawAction) { count += 1 }
```
SwiftUI stores the old environment value. When parent re-renders, it writes a new closure. SwiftUI must check: "did the environment change?" Since `() -> Void` isn't Equatable, it assumes YES. Child body re-runs.

**Run the Stress Test.** Parent re-evals ~52×. Child re-evals 52×. In a real app with 6 deeply-nested views, this multiplies.

**Show in Instruments:** (if live demo) Points of Interest → filter `Demo1-Bad`. Dense dot cloud for child. Switch to solution tab, run again. Child dots: 1–2.

**Switch to "✅ Solution" tab:**

The fix — three parts:
1. Wrap closure in a `final class Handler` (reference semantics = identity comparison works)
2. `ViewModifier` with `@State private var handler: Handler` — `@State` is set ONCE, ignores subsequent parent re-renders
3. Child gets same `Handler` reference → SwiftUI: "environment unchanged" → skip body

**Key insight:** This mirrors Apple's own `DismissAction` and `OpenURLAction`. They're callable value types in the environment. We're doing the same thing.

---

## Slide / Section: Demo 2 — View Property Closures (5 min)

**Setup:** Open Demo 2, "❌ Problem" tab.

**Explain:**
- Different problem: child holds `let action: () -> Void` as a property.
- Parent has `importantValue` (what the action cares about) and `inputText` (a text field, unrelated).
- Type in the text field. Watch the child badge increment on every keystroke.

**Why:**
```swift
struct ChildView: View {
    let action: () -> Void  // Not Equatable
    ...
}
```
When SwiftUI checks "did ChildView change?", it can't compare `() -> Void`. It assumes "different → re-evaluate body."

**The insight from Article 2:** Implicit `self` capture means the closure depends on the ENTIRE parent struct — all state, even unrelated. Apple's recommendation: explicit capture lists narrow the dependency.

But explicit captures alone don't solve the SwiftUI diffing problem. You need Equatable.

**Switch to "✅ Solution" tab.** Type in the text field — child stays at 1 eval. Change the Stepper — now the child re-evals. Perfect behavior.

**The fix:**
```swift
struct Action: Equatable {
    let stableWhile: AnyHashable
    private let work: () -> Void

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.stableWhile == rhs.stableWhile  // Only equal when dependency unchanged
    }
}

// At call site:
ChildView(
    action: Action(stableWhile: importantValue) { [importantValue] in
        print(importantValue)  // Explicit capture = clear intent
    }
)
```

**Key nuance:** The `stableWhile:` label is intentional. It documents the contract: "this action's behavior is stable as long as `importantValue` doesn't change."

---

## Slide / Section: Demo 3 — Decision Guide & Profiling (5 min)

**Open Demo 3.**

**The staleness trade-off (address proactively — senior engineers will ask):**
- The `@State`-in-modifier pattern keeps the FIRST handler forever.
- For `{ count += 1 }`: safe, because `@State` captures a reference to SwiftUI's storage — not a value copy. The closure always sees the current count.
- For closures referencing local constants or non-`@State` values: use `Action(stableWhile:)` instead, which refreshes when the dependency changes.

**Decision guide:**

| Scenario | Pattern |
|---|---|
| Simple leaf view, shallow hierarchy | Direct closure (cost is negligible) |
| Closure through environment, deep nesting | `Handler` + `StableActionModifier` |
| Closure as view property, parent has unrelated state | `Action(stableWhile:)` |
| Action depends on frequently-changing state | `Action(stableWhile:)` |
| System features (dismiss, openURL) | Apple already uses this pattern |

**The test story:** Jump to Xcode → ClosuresDemoTests. Show `testEquatableActionMinimizesReevaluations()`. The test asserts 10× improvement — and this is measurable, deterministic, and will catch regressions in CI.

**Run ⌘U.** Show the test output in the console: the formatted ratio summary.

---

## Slide / Section: Closing (2 min)

**Three rules:**

1. **Never put a raw `() -> Void` in `EnvironmentValues`** — use `Handler` + `StableActionModifier`.
2. **Prefer `Action: Equatable` over `() -> Void` for child view properties** when the parent has unrelated state.
3. **Use explicit capture lists** (`[foo]`) as documentation, even if they don't fully solve SwiftUI diffing alone — they make dependencies visible at the call site.

**Close with:**
> "The test in the project asserts a 10× improvement. That's not theoretical — it's measurable in your CI pipeline right now. The patterns are small, the payoff is large, and Apple's own SwiftUI environment actions prove the design."

---

## Anticipated Q&A

**Q: When does this actually matter in practice?**
> A: In forms with many fields (every keystroke re-evaluates siblings), in lists with action-holding cells, and in deeply-nested view hierarchies where a closure traverses many environment levels. The 6× re-eval count in the first article was on initial presentation — it gets worse under real state churn.

**Q: Doesn't SwiftUI batch updates anyway?**
> A: SwiftUI does coalesce some state changes within a single run-loop iteration. But each body evaluation still runs synchronously, and the cost of evaluating a body (creating and diffing view trees) is real. Under rapid state changes (typing, scroll, animation), batching doesn't eliminate the overhead.

**Q: Why doesn't SwiftUI just fix this internally?**
> A: Swift intentionally prohibits closure equality (Chris Lattner: allows compiler optimizations like method body merging and thunk sharing). SwiftUI can't compare closures without Swift-level support. The framework works around this with callable value types — which is exactly what we're doing.

**Q: What about `@Observable` — does this change with the new observation framework?**
> A: `@Observable` gives SwiftUI fine-grained property-level dependency tracking, which helps for properties. But closure identity is a separate concern — the closure comparison problem exists regardless of whether you use `@Observable`, `@ObservableObject`, or plain `@State`. The patterns in this demo apply to all three.

**Q: Is this a performance problem for a 3-view app?**
> A: No. Apply these patterns when: (a) profiling shows excessive body evaluations, (b) you're writing library/reusable components that will be composed unpredictably, or (c) views with complex body computation (heavy layout, list cells). Don't prematurely optimize — profile first.
