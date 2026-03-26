import SwiftUI

// MARK: - Demo Side By Side Demo

struct Demo3_BestPractice: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // Side-by-side live comparison
                Group {
                    SectionTitle(text: "Live Side-by-Side Comparison", systemImage: "rectangle.split.2x1")
                    SideBySideDemo()
                }

                Divider()
            }
            .padding()
        }
        .navigationTitle("Side By Side Demo")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Decision Row

struct DecisionRow: View {
    let scenario: String
    let verdict: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(scenario)
                    .font(.subheadline.weight(.medium))
                Text(verdict)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Live Side-by-Side Comparison

struct SideBySideDemo: View {
    @State private var sharedCount = 0
    @State private var unrelated = 0
    @State private var isRunning = false

    // Separate counters so we can compare them
    @State private var badCounter = EvalCounter(view: "Bad", scenario: "Demo3-Compare")
    @State private var goodCounter = EvalCounter(view: "Good", scenario: "Demo3-Compare")

    var body: some View {
        VStack(spacing: 12) {
            // The state controls
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text("Count (relevant)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Stepper("\(sharedCount)", value: $sharedCount)
                        .labelsHidden()
                    Text("\(sharedCount)")
                        .font(.title2.bold().monospacedDigit())
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("Unrelated changes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button {
                        unrelated += 1
                    } label: {
                        Label("Trigger", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Text("×\(unrelated)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Stress test
            Button {
                runStress()
            } label: {
                Label(
                    isRunning ? "Running…" : "Stress Test: 50 unrelated changes",
                    systemImage: isRunning ? "bolt.fill" : "bolt"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(isRunning)

            // Side by side children
            HStack(spacing: 12) {
                SideBySideChild(
                    label: "Raw () → Void",
                    color: .red,
                    evalCount: badCounter.count,
                    onAction: { _ = badCounter.tick() }
                )

                SideBySideChild(
                    label: "Action(stableWhile:)",
                    color: .green,
                    evalCount: goodCounter.count,
                    onAction: { _ = goodCounter.tick() }
                )
                // Note: in a real app the Action struct would gate re-evals automatically.
                // Here we simulate by only ticking goodCounter when sharedCount changes.
            }
            .onChange(of: unrelated) {
                // Bad: re-evals on unrelated change
                let _ = badCounter.tick()
            }
            .onChange(of: sharedCount) {
                // Both re-eval on relevant change
                let _ = badCounter.tick()
                let _ = goodCounter.tick()
            }

            HStack {
                Label("After stress test:", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Bad: \(badCounter.count)×")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.red)
                Text("Good: \(goodCounter.count)×")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
    }

    private func runStress() {
        isRunning = true
        Task {
            for _ in 0..<50 {
                try? await Task.sleep(for: .milliseconds(40))
                unrelated += 1
            }
            isRunning = false
        }
    }
}

struct SideBySideChild: View {
    let label: String
    let color: Color
    let evalCount: Int
    let onAction: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
            EvalBadge(label: "evals", count: evalCount)
            Button("Action") { onAction() }
                .buttonStyle(.bordered)
                .tint(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1.5)
        )
    }
}
