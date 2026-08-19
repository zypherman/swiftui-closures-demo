import SwiftUI

// MARK: - Demo 5 Landing

/// The "previous view" in the demo flow: explains the problem once, then
/// pushes into one of three implementations of the *exact same* 42-row
/// product catalog. Compare them live, or profile each independently.
struct ConditionalDemoLanding: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                InsightBox(kind: .problem, text: ConditionalLandingStrings.hook)

                DemoCard(title: "Why this matters", accent: .indigo) {
                    Text(ConditionalLandingStrings.explainer)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    SectionTitle(text: "Pick a build to profile", systemImage: "list.bullet.rectangle")

                    NavigationLink {
                        ConditionalListView(style: .ifElse)
                    } label: {
                        StyleLaunchRow(
                            style: .ifElse,
                            subtitle: "The everyday pattern: 42 cards, ~7 if/else branches each."
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ConditionalListView(style: .customIfModifier)
                    } label: {
                        StyleLaunchRow(
                            style: .customIfModifier,
                            subtitle: "The \"clean\" version everyone copy-pastes. Same cost, hidden."
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ConditionalListView(style: .inertModifiers)
                    } label: {
                        StyleLaunchRow(
                            style: .inertModifiers,
                            subtitle: "Ternaries, bare-if, and the collapse trick. No identity changes."
                        )
                    }
                    .buttonStyle(.plain)
                }

                InsightBox(kind: .tip, text: ConditionalLandingStrings.howToProfile)
            }
            .padding()
        }
        .navigationTitle("Conditional Modifiers")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Style Launch Row

struct StyleLaunchRow: View {
    let style: ConditionalRowStyle
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: style.iconName)
                .font(.title2)
                .foregroundStyle(style.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(style.rawValue)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(style.accent.opacity(0.25), lineWidth: 1.5)
        )
    }
}

// MARK: - String Constants

private enum ConditionalLandingStrings {

    static let hook =
        "SwiftUI gives every `if`/`else` in a `@ViewBuilder` its own concrete type: " +
        "`_ConditionalContent<TrueContent, FalseContent>`. When the condition flips, SwiftUI " +
        "doesn't update a property — it destroys the old branch and builds the new one from " +
        "scratch. Any `@State` in there resets, `onAppear` fires again, and any in-flight " +
        "animation restarts. Apple's own WWDC guidance (\"Demystify SwiftUI\") recommends " +
        "reaching for an inert modifier argument instead, whenever one exists."

    static let explainer =
        "This screen renders the same 42-item, semi-detailed catalog three times — once with " +
        "raw if/else, once with the popular custom `.if()` view modifier, and once using only " +
        "inert modifiers and the ViewBuilder \"nil case\" (a bare `if` with no `else`, which " +
        "compiles to `Optional<View>` instead of `_ConditionalContent`). Every screen shares the " +
        "same data model, the same visual design, and the same stress-test harness — only the " +
        "conditional strategy changes. A live Mounts counter (driven by real `onAppear` calls, " +
        "not guesswork) makes the identity churn visible without needing Instruments, and an " +
        "on-screen stopwatch times a 40-toggle stress test so the difference is a real number, " +
        "not a vibe."

    static let howToProfile =
        "For the deep dive: run each screen through **Instruments → Time Profiler**, then add " +
        "the **Points of Interest** instrument and filter by subsystem `com.ClosuresDemo." +
        "ConditionalPerf`. Each screen emits its own signpost category — `ConditionalPerf-IfElse`, " +
        "`-CustomIf`, `-Inert` — so you can flip Compact ⇄ Detailed on each and compare event " +
        "density side by side on the same timeline."
}
