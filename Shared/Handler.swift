import SwiftUI

// MARK: - Handler (for Demo 1: Environment Closures)

/// A stable callable wrapper for environment actions.
///
/// Uses class semantics so SwiftUI can compare two Handler instances by identity.
/// Combined with `@State` in `StableActionModifier`, this ensures the environment
/// value appears unchanged to child views even when the parent re-renders.
///
/// Mirrors Apple's own `DismissAction` pattern from SwiftUI.
// `@unchecked Sendable`: `action` is set once at init and never mutated — safe.
final class Handler: @unchecked Sendable {
    let action: () -> Void

    init(_ action: @escaping () -> Void) {
        self.action = action
    }

    func callAsFunction() {
        action()
    }
}

// Equatable by reference identity: two Handler variables are equal only when they
// point to the exact same object. This lets SwiftUI skip child re-renders when the
// environment receives the same @State-stored instance on every parent re-render.
extension Handler: Equatable {
    static func == (lhs: Handler, rhs: Handler) -> Bool { lhs === rhs }
}

// MARK: - Environment Keys

// Unstable: passes Handler directly with no @State protection.
// A new Handler instance is created on each parent body call →
// different identity → Equatable returns false → child re-evaluates.
private struct UnstableActionKey: EnvironmentKey {
    static let defaultValue: Handler? = nil
}

extension EnvironmentValues {
    var unstableAction: Handler? {
        get { self[UnstableActionKey.self] }
        set { self[UnstableActionKey.self] = newValue }
    }
}

// Stable: Handler stored in @State inside StableActionModifier.
// Same Handler instance survives every parent re-render →
// identity equal → child skips re-evaluation.
private struct StableActionKey: EnvironmentKey {
    static let defaultValue: Handler? = nil
}

extension EnvironmentValues {
    var stableAction: Handler? {
        get { self[StableActionKey.self] }
        set { self[StableActionKey.self] = newValue }
    }
}

/// A `ViewModifier` that stores the handler in `@State` so it is set exactly once.
///
/// When the parent re-renders and passes a new `Handler`, SwiftUI ignores it because
/// `@State` does not reinitialize after initial assignment. The child therefore sees
/// the same `Handler` reference in the environment on every parent re-render.
struct StableActionModifier: ViewModifier {
    @State private var handler: Handler

    init(_ handler: Handler) {
        _handler = State(initialValue: handler)
    }

    func body(content: Content) -> some View {
        content.environment(\.stableAction, handler)
    }
}

extension View {
    func stableAction(_ handler: Handler) -> some View {
        modifier(StableActionModifier(handler))
    }
}

// MARK: - Action (for Demo 2: View Property Closures)

/// An Equatable action wrapper that tells SwiftUI exactly when an action "changes".
///
/// SwiftUI compares child view structs before deciding to re-evaluate body.
/// A raw `() -> Void` is not Equatable, so SwiftUI always assumes "changed".
/// This wrapper adds an explicit dependency key — SwiftUI skips re-evaluation
/// when the dependency hasn't changed.
///
/// In the Hyatt App, we are using a similar approach that uses a UUID() to track equality vs passing in an explicit value
struct Action: Equatable {
    let stableWhile: AnyHashable   // The dependency that controls equality
    private let work: () -> Void

    /// - Parameters:
    ///   - dependency: The value this action semantically depends on.
    ///                 When `dependency` is unchanged, SwiftUI skips child body re-evaluation.
    ///   - work: The closure to execute. Use an explicit capture list for clarity.
    init<H: Hashable>(stableWhile dependency: H, _ work: @escaping () -> Void) {
        stableWhile = AnyHashable(dependency)
        self.work = work
    }

    func callAsFunction() { work() }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.stableWhile == rhs.stableWhile
    }
}
