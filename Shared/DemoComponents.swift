import SwiftUI

// MARK: - DemoCard

struct DemoCard<Content: View>: View {
    let title: String
    var accent: Color = .primary
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "square.stack.3d.up")
                .font(.caption.weight(.semibold))
                .foregroundStyle(accent)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accent.opacity(0.25), lineWidth: 1.5)
        )
    }
}

// MARK: - InsightBox

struct InsightBox: View {
    enum Kind { case problem, solution, tip }

    let kind: Kind
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .font(.body.weight(.semibold))
            Text(LocalizedStringKey(text))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(iconColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var iconName: String {
        switch kind {
        case .problem:  return "exclamationmark.triangle.fill"
        case .solution: return "checkmark.seal.fill"
        case .tip:      return "lightbulb.fill"
        }
    }

    private var iconColor: Color {
        switch kind {
        case .problem:  return .red
        case .solution: return .green
        case .tip:      return .orange
        }
    }
}

// MARK: - MonoCodeView

struct MonoCodeView: View {
    let code: String

    var body: some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - StressTestButton

struct StressTestButton: View {
    let isRunning: Bool
    let changeCount: Int
    let action: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button(action: action) {
                Label(
                    isRunning ? "Running…" : "Stress Test (50 rapid changes)",
                    systemImage: isRunning ? "bolt.fill" : "bolt"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(isRunning)

            Text("Fires 50 unrelated state changes. Watch the child eval badge.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - SectionTitle

struct SectionTitle: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.headline)
            .padding(.top, 4)
    }
}

// MARK: - DemoSegmentPicker

enum DemoMode: String, CaseIterable {
    case problem = "Problem"
    case solution = "Solution"
}

struct DemoSegmentPicker: View {
    @Binding var mode: DemoMode

    var body: some View {
        Picker("Mode", selection: $mode) {
            ForEach(DemoMode.allCases, id: \.self) {
                Text($0.rawValue).tag($0)
            }
        }
        .pickerStyle(.segmented)
    }
}
