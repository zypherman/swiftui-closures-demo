import SwiftUI

// MARK: - The "Custom .if() Conditional Modifier"
//
// This is one of the most copy-pasted SwiftUI snippets on the internet —
// almost every "SwiftUI tips" thread eventually recommends it as a clean
// way to avoid duplicating a whole view for the sake of one modifier.
//
// It reads beautifully:
//
//     Text("Hello")
//         .if(isHighlighted) { $0.bold().foregroundStyle(.yellow) }
//
// But look at what `@ViewBuilder` actually compiles this to. `if condition {
// transform(self) } else { self }` is exactly the same `buildEither` /
// `_ConditionalContent<TrueContent, FalseContent>` machinery as writing the
// if/else by hand. The nicer call site does NOT change the underlying cost:
// flipping `condition` still swaps the view's structural identity, still
// tears down and reinserts everything inside the transformed branch, and
// still resets any `@State` those views hold. This file exists so the demo
// can prove that side-by-side against the raw if/else and the inert-modifier
// versions of the exact same UI.
extension View {

    /// Single-branch form. `condition == false` returns `self` unchanged.
    @ViewBuilder
    func `if`<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Two-branch form. Also extremely common — used whenever both states
    /// need their own wrapping, not just an on/off toggle.
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
