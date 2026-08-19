import SwiftUI

// MARK: - Row Style

enum ConditionalRowStyle: String, CaseIterable, Identifiable {
    case ifElse = "if / else"
    case customIfModifier = ".if() Modifier"
    case inertModifiers = "Inert Modifiers"

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .ifElse: .red
        case .customIfModifier: .orange
        case .inertModifiers: .green
        }
    }

    var iconName: String {
        switch self {
        case .ifElse: "arrow.triangle.branch"
        case .customIfModifier: "wand.and.stars"
        case .inertModifiers: "checkmark.seal.fill"
        }
    }

    var scenarioName: String {
        switch self {
        case .ifElse: "ConditionalPerf-IfElse"
        case .customIfModifier: "ConditionalPerf-CustomIf"
        case .inertModifiers: "ConditionalPerf-Inert"
        }
    }

    var explanation: String {
        switch self {
        case .ifElse:
            return "Every badge, price tag, and the whole compact/detailed layout are chosen with if/else. Each toggle tears down one real view type and builds another."
        case .customIfModifier:
            return "Same UI, built with the popular custom .if() modifier. It looks cleaner — it compiles to the exact same _ConditionalContent underneath."
        case .inertModifiers:
            return "Same UI again. Every state change is a modifier argument, a ternary, or a bare if-with-no-else. No view ever changes type."
        }
    }
}

// MARK: - Container Screen

struct ConditionalListView: View {
    let style: ConditionalRowStyle

    @State private var items: [ConditionalDemoItem]
    @State private var displayMode: ProductDisplayMode = .detailed
    @State private var metrics: ConditionalPerfMetrics
    @State private var isStressRunning = false
    @State private var lastStressElapsedMS: Double?
    @State private var lastStressToggleCount = 0

    init(style: ConditionalRowStyle) {
        self.style = style
        _items = State(initialValue: ConditionalDemoItem.makeCatalog())
        _metrics = State(initialValue: ConditionalPerfMetrics(scenario: style.scenarioName))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ConditionalStyleHeader(style: style)

                ConditionalMetricsHUD(
                    mounts: metrics.mounts,
                    bodyEvaluations: metrics.bodyEvaluations,
                    lastStressElapsedMS: lastStressElapsedMS,
                    lastStressToggleCount: lastStressToggleCount,
                    rowCount: items.count
                )

                ConditionalControlsBar(
                    displayMode: $displayMode,
                    isStressRunning: isStressRunning,
                    accent: style.accent,
                    onStressTest: { Task { await runStressTest() } },
                    onReset: {
                        metrics.reset()
                        lastStressElapsedMS = nil
                        lastStressToggleCount = 0
                    }
                )

                VStack(spacing: 10) {
                    ForEach($items) { $item in
                        rowView(item: $item)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(style.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    @ViewBuilder
    private func rowView(item: Binding<ConditionalDemoItem>) -> some View {
        switch style {
        case .ifElse:
            IfElseProductRow(item: item, displayMode: displayMode, metrics: metrics)
        case .customIfModifier:
            CustomIfModifierProductRow(item: item, displayMode: displayMode, metrics: metrics)
        case .inertModifiers:
            InertProductRow(item: item, displayMode: displayMode, metrics: metrics)
        }
    }

    // MARK: - Stress Test

    /// Randomly toggles a field on a random row 40 times, ~35ms apart —
    /// enough real render cycles between mutations that the elapsed wall
    /// time genuinely includes SwiftUI's diffing and layout work, not just
    /// this loop's own bookkeeping.
    @MainActor
    private func runStressTest() async {
        isStressRunning = true
        let clock = ContinuousClock()
        let start = clock.now

        for _ in 0..<40 {
            try? await Task.sleep(for: .milliseconds(35))
            guard let index = items.indices.randomElement() else { continue }
            toggleRandomField(at: index)
        }

        lastStressElapsedMS = start.duration(to: clock.now).milliseconds
        lastStressToggleCount = 40
        isStressRunning = false
    }

    private func toggleRandomField(at index: Int) {
        switch Int.random(in: 0..<5) {
        case 0: items[index].isFavorite.toggle()
        case 1: items[index].isSelected.toggle()
        case 2: items[index].isExpanded.toggle()
        case 3: items[index].isOnline.toggle()
        default: items[index].inStock.toggle()
        }
    }
}

// MARK: - Header
//
// A separate View type, not a computed property: this gives the header its
// own invalidation boundary. Toggling `items` during the stress test
// re-evaluates ConditionalListView's body, but a computed property would
// re-inline into that same body and re-run every time regardless of whether
// `style` changed. A concrete type with a narrow `style` input only
// re-evaluates when `style` itself changes — which, on this screen, is never.

struct ConditionalStyleHeader: View {
    let style: ConditionalRowStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(style.rawValue, systemImage: style.iconName)
                .font(.title3.bold())
                .foregroundStyle(style.accent)
            Text(style.explanation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Metrics HUD

struct ConditionalMetricsHUD: View {
    let mounts: Int
    let bodyEvaluations: Int
    let lastStressElapsedMS: Double?
    let lastStressToggleCount: Int
    let rowCount: Int

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                EvalBadge(label: "Mounts", count: mounts)
                EvalBadge(label: "Row Evals", count: bodyEvaluations)
            }

            if let ms = lastStressElapsedMS {
                Text("Last stress test: \(Int(ms.rounded())) ms for \(lastStressToggleCount) toggles across \(rowCount) rows")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("Flip Compact ⇄ Detailed above and watch Mounts.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Controls

struct ConditionalControlsBar: View {
    @Binding var displayMode: ProductDisplayMode
    let isStressRunning: Bool
    let accent: Color
    let onStressTest: () -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Picker("Display Mode", selection: $displayMode) {
                ForEach(ProductDisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Button {
                onStressTest()
            } label: {
                Label(
                    isStressRunning ? "Running…" : "Stress Test (40 random toggles)",
                    systemImage: isStressRunning ? "bolt.fill" : "bolt"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            .disabled(isStressRunning)

            Button(role: .destructive) {
                onReset()
            } label: {
                Label("Reset Metrics", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}
