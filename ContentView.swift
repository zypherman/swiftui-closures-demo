import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: Demo1_EnvironmentClosure()) {
                        DemoRow(
                            number: "01",
                            title: "Closures in Environment",
                            subtitle: "Closure identity breaks env diffing → 6× re-evals",
                            accent: .red
                        )
                    }
                    NavigationLink(destination: Demo2_ViewPropertyClosure()) {
                        DemoRow(
                            number: "02",
                            title: "Implicit vs Explicit Capture",
                            subtitle: "3 real children × raw () → Void = all re-eval on every keystroke",
                            accent: .orange
                        )
                    }
                    NavigationLink(destination: Demo3_BestPractice()) {
                        DemoRow(
                            number: "03",
                            title: "The Stable Patterns",
                            subtitle: "Handler + Action — the DismissAction approach",
                            accent: .green
                        )
                    }
                    NavigationLink(destination: Demo4_CompoundEffect()) {
                        DemoRow(
                            number: "04",
                            title: "Compound Effect",
                            subtitle: "8 state fields × raw Handler = 50× wasted child re-evals",
                            accent: .purple
                        )
                    }
                } header: {
                    Text("Demos")
                } footer: {}
            }
            .navigationTitle("Closures in SwiftUI")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - DemoRow

struct DemoRow: View {
    let number: String
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Text(number)
                .font(.caption.monospacedDigit().weight(.black))
                .foregroundStyle(accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
