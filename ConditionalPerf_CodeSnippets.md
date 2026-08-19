# Code Snippets Reference — Conditional View Modifiers

Quick-reference for every pattern shown in Demo 5. File locations are under `ConditionalPerf/`.

---

## 1. The Trap: `if`/`else` With Two Real Branches

```swift
// ❌ Two distinct concrete types → _ConditionalContent<OnlineDot, OfflineDot>
// Flipping isOnline destroys whichever dot is on screen and builds the other.
if item.isOnline {
    OnlineDot(metrics: metrics)
} else {
    OfflineDot(metrics: metrics)
}
```

**Observable symptom:** each branch's `onAppear` fires again every time the condition flips — even flipping back to a previously-seen state creates a brand-new instance. Track it with a shared counter (see `ConditionalPerfMetrics` in `ConditionalDemoModels.swift`).

---

## 2. The Hidden Trap: `else { EmptyView() }`

```swift
// ❌ Looks like "nothing," but EmptyView is a distinct type from SelectionChrome.
// Still _ConditionalContent<SelectionChrome, EmptyView> — still remounts on every toggle.
.overlay {
    if item.isSelected {
        SelectionChrome(tint: item.category.tint, metrics: metrics)
    } else {
        EmptyView()
    }
}
```

**The fix — bare `if`, no `else`:**

```swift
// ✅ Optional<SelectionChrome> — SwiftUI diffs by presence/absence.
.overlay {
    if item.isSelected {
        SelectionChrome(tint: item.category.tint, metrics: metrics)
    }
}
```

**Or better still, when there's a natural "off" value — the true inert-modifier fix:**

```swift
// ✅ Same shape, always mounted. Color.clear / lineWidth: 0 IS the nil case.
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(item.isSelected ? tint : Color.clear, lineWidth: item.isSelected ? 2 : 0)
)
```

---

## 3. The Custom `.if()` Modifier — Same Cost, Nicer Syntax

```swift
// ConditionalPerf/View+If.swift
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        then trueTransform: (Self) -> TrueContent,
        else falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }
}
```

```swift
// ❌ Reads as "conditionally decorate the card." Compiles to the same
// _ConditionalContent<ModifiedContent<Card, Overlay>, Card> as raw if/else.
card.if(item.isSelected) { $0.overlay { SelectionChrome(...) } }
```

There is no version of `.if()` that avoids this cost — the extension is pure syntax sugar over `_ConditionalContent`. If the condition changes at runtime after the view is on screen, treat `.if()` exactly like a hand-written if/else for performance purposes.

---

## 4. Whole-Screen Structural Swap (the expensive one)

```swift
// ❌ Every one of 42 rows swaps to a different card TYPE the instant
// displayMode flips — one state change, 42 simultaneous remounts.
if displayMode == .detailed {
    DetailedIfElseCard(item: $item, metrics: metrics)
} else {
    CompactIfElseCard(item: $item, metrics: metrics)
}
```

**The fix — one adaptive type, modifiers do the layout work:**

```swift
// ✅ ConditionalPerf/Rows/InertProductRow.swift
// One AdaptiveProductCard type for both modes. isCompact only ever changes
// spacing, opacity, and frame — never which Swift type is on screen.
VStack(alignment: .leading, spacing: isCompact ? 6 : 10) {
    HStack(alignment: .top, spacing: 12) {
        ZStack(alignment: .bottomTrailing) {
            AvatarCircle(category: item.category)
            StatusDot(isOnline: item.isOnline, metrics: metrics)
                .opacity(isCompact ? 0 : 1)   // stays mounted, just invisible
        }
        Text(item.name)
            .font(isCompact ? .subheadline.weight(.semibold) : .headline)
        // ...
    }
}
```

---

## 5. Collapse Instead of Remove (protecting state + mount cost)

```swift
// ✅ ConditionalPerf/Rows/StableConditionalLeaves.swift — DetailPanel
// Never removed from the tree in ANY mode. onAppear fires exactly once
// per row for the lifetime of the screen, no matter how many times
// isExpanded or isCompact flips.
VStack(alignment: .leading, spacing: 6) {
    Text("Full specs...")
    HStack { ForEach(tags, id: \.self) { TagChip($0) } }
}
.frame(maxHeight: isExpanded ? nil : 0, alignment: .top)
.opacity(isExpanded ? 1 : 0)
.clipped()
```

---

## 6. Bare `if` (No Else) Is Already Cheap — Use It Freely

```swift
// ✅ Optional<NewRibbon> — safe everywhere, including inside a "bad" row.
// This is NOT the pattern to avoid.
if item.isNew {
    NewRibbon()
}
```

The lesson isn't "avoid `if`." It's "avoid `if`/`else` where both branches are real, differently-typed views standing in for what is conceptually one property change."

---

## 7. Measuring It

```swift
// ConditionalPerf/ConditionalDemoModels.swift
final class ConditionalPerfMetrics {
    private(set) var mounts = 0            // real onAppear calls — identity loss
    private(set) var bodyEvaluations = 0   // row body calls — sanity check only
    private let signposter: OSSignposter   // Points of Interest in Instruments
    // ...
}
```

```swift
// ClosuresDemoTests/ConditionalModifierPerformanceTests.swift
func testStructuralSwapRemountsOnEveryToggle() {
    var slot = StructuralSlot()
    var state = false
    for _ in 0..<40 { state.toggle(); slot.setState(state) }
    XCTAssertEqual(slot.mounts, 40)   // every toggle remounts
}

func testInertModifierMountsOnce() {
    var slot = InertSlot()
    var state = false
    for _ in 0..<40 { state.toggle(); slot.setState(state) }
    XCTAssertEqual(slot.mounts, 1)    // mounts once, ever
}
```

**Profiling live:** Instruments → Time Profiler + Points of Interest, filter by subsystem `com.ClosuresDemo.ConditionalPerf`, category `ConditionalPerf-IfElse` / `-CustomIf` / `-Inert`.
