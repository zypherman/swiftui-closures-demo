# Speaker Notes: Conditional View Modifiers in SwiftUI
**Audience:** iOS Engineers | **Duration:** 20–30 min | **Demo:** ContentView → "05 Conditional View Modifiers"

---

## Slide / Section: Hook — "Every `if` Has a Type" (2 min)

**Open with:**
> "Every SwiftUI view has an identity — and for most views, that identity is inferred from two things: where it sits in the tree, and its concrete Swift type. Write an `if`/`else` in a `@ViewBuilder`, and you've just given the compiler two possible types for that slot. Flip the condition, and SwiftUI doesn't update a property — it tears down one view and builds the other from nothing."

**Key points:**
- This talk is not "stop using `if` in SwiftUI." Half the demo's own "bad" screen uses bare `if` correctly.
- The actual lesson is narrower and much more useful: **`if X {A()} else {B()}` where A and B are two real types is expensive. A modifier argument, a ternary, or a bare `if` with no `else` usually isn't.**
- The popular custom `.if()` view modifier extension does not fix this. It hides it.

**Transition:** "Let's look at what SwiftUI actually compiles these to."

---

## Slide / Section: The Mechanism (4 min)

**Key points:**

1. **Structural identity.** SwiftUI infers a view's identity from its type and position in the tree (not from an explicit `.id()`). Two views of different concrete types occupying the "same" visual spot are, to SwiftUI, unrelated — one is destroyed, the other created.

2. **`if`/`else` compiles to `_ConditionalContent<TrueContent, FalseContent>`.** This is a real generic type SwiftUI's `ViewBuilder` produces via `buildEither(first:)` / `buildEither(second:)`. Flipping the branch swaps which payload is live, and SwiftUI treats that as tearing down the old branch's entire subtree — `@State` resets, `onAppear`/`onDisappear` refire, in-flight animations restart.

3. **Bare `if` with NO `else` is different — and safe.** `if condition { A() }` alone compiles via `buildOptional(_:)` to `Optional<A>`. The TYPE never changes; only the payload flips between `.some(A())` and `nil`. SwiftUI diffs an Optional by presence/absence, which is far cheaper than swapping two unrelated types.

4. **The trap: `else { EmptyView() }` looks safe but isn't.** `EmptyView` is a distinct concrete type from whatever the `if` branch produces. Writing `if X { A() } else { EmptyView() }` is STILL `_ConditionalContent<A, EmptyView>` — the exact same cost as branching between two "real" views. This is the single most common way engineers accidentally opt into the expensive path while believing they've avoided it.

5. **The custom `.if()` modifier changes nothing.** The near-universal snippet —
   ```swift
   extension View {
       @ViewBuilder
       func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
           if condition { transform(self) } else { self }
       }
   }
   ```
   — desugars to `_ConditionalContent<Content, Self>`. Same mechanism, same cost, nicer call site. It is, if anything, more dangerous: the raw if/else at least *shows* you there are two branches. `.if()` hides the branch behind a single fluent call.

6. **`AnyView` is the same problem, worse.** Wrapping a view in `AnyView` erases its static type entirely, so SwiftUI can no longer statically diff the subtree at all — every update falls back to a full re-render of that erased subtree. Apple's WWDC21 "Demystify SwiftUI" session names this explicitly and recommends inert modifiers + `@ViewBuilder` instead. Independent benchmarks report list-scrolling ~10% slower with `AnyView`, and ~17% slower under active data churn.

**Key quote (paraphrased from WWDC21 "Demystify SwiftUI"):** "Prefer to keep view identity stable. Use inert modifiers with conditional arguments instead of conditionally including a modifier."

---

## Slide / Section: Demo — Same 42-Row Catalog, Three Builds (10 min)

**Setup:** ContentView → "05 Conditional View Modifiers" → landing screen with three buttons.

The landing screen explains the setup once: 42 product cards, same data, same visuals, three implementations. Each screen has a live **Mounts** counter (driven by real `onAppear` calls — not a guess), a **Row Evals** counter, a Compact/Detailed toggle, and a 40-toggle stress test with an on-screen stopwatch.

### A. `if / else` (red)

Open it. Point out the structure: avatar+status dot, favorite star, price tag, availability badge, and the expand panel are ALL `if X {A()} else {B()}`. Selection highlight uses `else { EmptyView() }` — the trap.

- Tap a few favorite stars. Watch **Mounts** climb — every tap tears down and rebuilds that slot.
- Run the **Stress Test**. Note the elapsed time.
- Flip **Compact ⇄ Detailed**. Watch Mounts jump by ~42 (every row swaps to a different card type at once) and note the visible flash/relayout — there's no continuity for SwiftUI to animate, because nothing it's diffing is the "same view."

### B. `.if()` Modifier (orange)

Same screen, same data. Point out this code *reads* cleaner — no visible `else`. Then point out **Mounts still climbs at the same rate**. Show the single-branch case:
```swift
.if(item.isSelected) { card in card.overlay { SelectionChrome(...) } }
```
There's no `else` written anywhere at this call site — and it's still `_ConditionalContent<ModifiedContent<Card, Overlay>, Card>` under the hood. Run the same stress test; the elapsed time should land within noise of Demo A's.

**Key insight:** ask the room "which of these two looked safer before I told you?" Almost everyone picks `.if()`. That's the point.

### C. Inert Modifiers (green)

Same screen again. Walk through the equivalents:
- `Circle().fill(isOnline ? .green : .gray)` — the color argument IS the modifier's "empty case."
- `Image(systemName: isFavorite ? "star.fill" : "star")` — same `Image` type, different string.
- `.stroke(isSelected ? tint : .clear, lineWidth: isSelected ? 2 : 0)` — `Color.clear` / zero width is the literal nil-case of a stroke, the correct counterpart to the `EmptyView()` trap.
- The expand panel: never removed from the tree, just `.frame(maxHeight: isExpanded ? nil : 0).opacity(...).clipped()`. Its `onAppear` fires exactly once per row for the whole session.

Run the identical stress test and Compact ⇄ Detailed flip. **Mounts barely moves.** The compact/detailed flip animates smoothly, because SwiftUI is interpolating properties on the *same* view instances, not replacing subtrees.

**Numbers to have ready (fill in from your own run — they're reproducible since the catalog is seeded):**

| | if/else | .if() | Inert |
|---|---|---|---|
| Mounts after 3 Compact⇄Detailed flips | ~126 | ~126 | ~42 (once) |
| Stress test elapsed (40 toggles) | highest | ~same as if/else | lowest |

---

## Slide / Section: The Decision Guide (3 min)

| Situation | Pattern |
|---|---|
| Two states of the same view, any parameter differs (color, text, image name, width) | Ternary / inert modifier argument |
| A view should sometimes not be there at all, no state to preserve | Bare `if condition { View() }` — no `else` |
| A view should sometimes not be there, but you don't want to lose its state or re-trigger `onAppear` | Keep it mounted; collapse with `.frame(maxHeight: 0).opacity(0).clipped()` |
| Two genuinely different subviews for a boolean, and you catch yourself writing `else { EmptyView() }` | Stop — check if this is really an inert-modifier case in disguise |
| A custom `.if()` modifier appears in the diff | Treat it exactly like raw if/else for cost purposes — it is one |
| Type-erasing to unify unrelated view trees | Avoid `AnyView`; restructure with `@ViewBuilder` / enum-driven `switch` instead |

**The test story:** `ClosuresDemoTests/ConditionalModifierPerformanceTests.swift` models this in pure Swift — `testStructuralSwapRemountsOnEveryToggle` vs `testInertModifierMountsOnce`, plus `testEmptyViewElseBranchStillRemounts` proving the trap. `⌘U` to run; the summary print block gives a clean before/after for slides.

---

## Closing (1 min)

**Three rules:**

1. If both branches are the same kind of thing with different parameters, it's a modifier argument, not an `if`/`else`.
2. `else { EmptyView() }` is not a nil case — it's a second real branch. Prefer a bare `if` with no `else`, or collapse instead of removing.
3. A custom `.if()` modifier is exactly as expensive as the if/else it replaces syntactically. Don't let nicer syntax read as "solved."

**Close with:**
> "None of this shows up in a code review diff. It shows up as dropped frames during a stress test, and as a Mounts counter that won't stop climbing. Profile it once, and you'll never write `else { EmptyView() }` again without noticing."

---

## Anticipated Q&A

**Q: Isn't `_ConditionalContent` still pretty cheap? It's not literally a UIKit view teardown.**
> A: It's cheaper than `AnyView`, but it's not free. `@State` in the discarded branch is gone, `onAppear`/`onDisappear` refire, animations that were mid-flight restart, and any nested `UIViewRepresentable`/`NSViewRepresentable` genuinely tears down and reinitializes its underlying UIKit/AppKit object — which is where this stops being theoretical and starts being a dropped frame.

**Q: When does this actually matter?**
> A: Rows in a large or frequently-updated list (this demo's whole premise), anywhere with a `UIViewRepresentable`, and anywhere state loss is user-visible (a text field mid-edit, an in-flight animation, scroll position inside a nested container).

**Q: Should I ban `if`/`else` in SwiftUI views?**
> A: No — ban `if`/`else` **where both branches are two real, differently-typed views for what is conceptually one state toggle.** Bare `if` for presence/absence is fine. `if`/`else` between two conceptually different screens (e.g., a loading state vs. a content state) is also fine — those genuinely are different things, and losing state on that transition is usually what you want.

**Q: Is the custom `.if()` modifier ever fine to use?**
> A: Yes — when the condition is effectively static for the view's lifetime (e.g., set once from a feature flag or a template style at construction time and never re-evaluated afterward). The cost only bites when the condition changes at runtime after the view is already on screen.

**Q: Why does Compact ⇄ Detailed cost so much more than a single favorite-star tap?**
> A: A single star tap only invalidates the small slot governed by that one `if`/`else` — its sibling conditionals elsewhere in the row are untouched, because each conditional is its own structural position in the tree. Compact ⇄ Detailed wraps the ENTIRE row body in one `if`/`else`, so flipping it invalidates everything beneath that branch, for every row, simultaneously — that's the multiplier.
