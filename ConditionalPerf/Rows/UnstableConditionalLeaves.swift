import SwiftUI

// MARK: - "Unstable" Leaves — two distinct concrete types per condition
//
// Every pair here is deliberately written the way real production code
// often looks: the two states aren't just cosmetic twins, they carry their
// own small bit of local state or behavior (a mount pulse, a different
// layout). That's *why* engineers reach for if/else instead of a ternary —
// it feels like the branches are "different enough" to deserve their own
// view. The cost is the same either way: two real types means
// `_ConditionalContent<A, B>`, and flipping the condition destroys whichever
// branch was on screen and creates the other from scratch.
//
// These leaves are shared by both the raw if/else row AND the custom
// `.if()` row — the only thing that differs between those two demos is the
// *syntax* used to switch between them. The mount count is identical either
// way, which is the whole point.

// MARK: Status Dot

struct OnlineDot: View {
    let metrics: ConditionalPerfMetrics
    @State private var scale: CGFloat = 0.3

    var body: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 10, height: 10)
            .scaleEffect(scale)
            .onAppear {
                metrics.recordMount()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { scale = 1 }
            }
    }
}

struct OfflineDot: View {
    let metrics: ConditionalPerfMetrics

    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.4))
            .frame(width: 10, height: 10)
            .onAppear { metrics.recordMount() }
    }
}

// MARK: Favorite Icon

struct FilledStarButton: View {
    let metrics: ConditionalPerfMetrics
    let action: () -> Void
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Button(action: action) {
            Image(systemName: "star.fill")
                .foregroundStyle(.yellow)
                .scaleEffect(scale)
        }
        .buttonStyle(.plain)
        .onAppear {
            metrics.recordMount()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { scale = 1 }
        }
    }
}

struct OutlineStarButton: View {
    let metrics: ConditionalPerfMetrics
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "star")
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .onAppear { metrics.recordMount() }
    }
}

// MARK: Availability Badge

struct InStockBadge: View {
    let metrics: ConditionalPerfMetrics

    var body: some View {
        Label("In Stock", systemImage: "checkmark.circle.fill")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.green)
            .onAppear { metrics.recordMount() }
    }
}

struct OutOfStockBadge: View {
    let metrics: ConditionalPerfMetrics
    @State private var opacity: Double = 0

    var body: some View {
        Label("Out of Stock", systemImage: "xmark.circle.fill")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.red)
            .opacity(opacity)
            .onAppear {
                metrics.recordMount()
                withAnimation(.easeIn(duration: 0.2)) { opacity = 1 }
            }
    }
}

// MARK: Price Tag

struct DiscountedPriceTag: View {
    let price: Double
    let discountPercent: Int
    let metrics: ConditionalPerfMetrics

    private var discountedPrice: Double { price * (1 - Double(discountPercent) / 100) }

    var body: some View {
        HStack(spacing: 6) {
            Text(price, format: .currency(code: "USD"))
                .font(.caption)
                .strikethrough()
                .foregroundStyle(.secondary)
            Text(discountedPrice, format: .currency(code: "USD"))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.red)
        }
        .onAppear { metrics.recordMount() }
    }
}

struct RegularPriceTag: View {
    let price: Double
    let metrics: ConditionalPerfMetrics

    var body: some View {
        Text(price, format: .currency(code: "USD"))
            .font(.subheadline.weight(.bold))
            .onAppear { metrics.recordMount() }
    }
}

// MARK: Expand Panel

struct ExpandedDetailPanel: View {
    let item: ConditionalDemoItem
    let metrics: ConditionalPerfMetrics
    @State private var rotation: Double = -90

    private let tags = ["Free returns", "2-yr warranty", "Ships in 24h"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Full specs and shipping details for \(item.name) appear here once expanded.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(item.category.tint.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 1, y: 0, z: 0), anchor: .top)
        .onAppear {
            metrics.recordMount()
            withAnimation(.easeOut(duration: 0.2)) { rotation = 0 }
        }
    }
}

struct CollapsedDetailHint: View {
    let metrics: ConditionalPerfMetrics

    var body: some View {
        Text("Tap to see details")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .onAppear { metrics.recordMount() }
    }
}

// MARK: Selection Chrome — the "EmptyView() trap"
//
// This pair looks innocent — "if selected, draw a highlight; otherwise draw
// nothing." But `EmptyView` is still a *distinct concrete type* from
// `SelectionChrome`. Writing `else { EmptyView() }` does NOT get you the
// cheap Optional-diffing behavior of a bare `if` — it produces
// `_ConditionalContent<SelectionChrome, EmptyView>`, so toggling selection
// still swaps structural identity. It just doesn't look like it does.

struct SelectionChrome: View {
    let tint: Color
    let metrics: ConditionalPerfMetrics

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(tint.opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(tint, lineWidth: 2))
            .onAppear { metrics.recordMount() }
    }
}
