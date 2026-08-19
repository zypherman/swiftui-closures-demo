import SwiftUI

// MARK: - "Stable" Leaves — one concrete type per condition
//
// Same six slots as UnstableConditionalLeaves.swift, same visual states,
// same information density. The only difference: each slot is now a single
// view type whose *parameters* change, not its *identity*. SwiftUI updates
// these in place — no teardown, no `onAppear` refiring, no state loss, and
// transitions animate implicitly for free because the framework is
// interpolating a property, not replacing a subtree.

// MARK: Status Dot

struct StatusDot: View {
    let isOnline: Bool
    let metrics: ConditionalPerfMetrics

    var body: some View {
        Circle()
            // The color argument is the "empty case" of this modifier: instead of
            // choosing between two Circle-wrapping views, we choose between two
            // color values on the SAME Circle.
            .fill(isOnline ? Color.green : Color.gray.opacity(0.4))
            .frame(width: 10, height: 10)
            .animation(.easeInOut(duration: 0.2), value: isOnline)
            .onAppear { metrics.recordMount() } // fires once, ever — never again
    }
}

// MARK: Favorite Icon

struct FavoriteButton: View {
    let isFavorite: Bool
    let metrics: ConditionalPerfMetrics
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // systemName is a String parameter, not a type choice — same Image view either way.
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundStyle(isFavorite ? Color.yellow : Color.secondary)
                .scaleEffect(isFavorite ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isFavorite)
        .onAppear { metrics.recordMount() }
    }
}

// MARK: Availability Badge

struct AvailabilityLabel: View {
    let inStock: Bool
    let metrics: ConditionalPerfMetrics

    var body: some View {
        Label(inStock ? "In Stock" : "Out of Stock",
              systemImage: inStock ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(inStock ? Color.green : Color.red)
            .animation(.easeInOut(duration: 0.2), value: inStock)
            .onAppear { metrics.recordMount() }
    }
}

// MARK: Price Tag

struct PriceTag: View {
    let price: Double
    let discountPercent: Int?
    let metrics: ConditionalPerfMetrics

    private var hasDiscount: Bool { discountPercent != nil }
    private var finalPrice: Double {
        guard let discountPercent else { return price }
        return price * (1 - Double(discountPercent) / 100)
    }

    var body: some View {
        HStack(spacing: 6) {
            // Bare `if` (no else) — Optional<Text>, not _ConditionalContent.
            // Cheap to insert/remove because the type never changes, only the
            // Optional's payload does.
            if hasDiscount {
                Text(price, format: .currency(code: "USD"))
                    .font(.caption)
                    .strikethrough()
                    .foregroundStyle(.secondary)
            }

            // This Text is ALWAYS present — only its value and color argument
            // change. Same view, same identity, whether discounted or not.
            Text(finalPrice, format: .currency(code: "USD"))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(hasDiscount ? Color.red : Color.primary)
        }
        .animation(.easeInOut(duration: 0.2), value: discountPercent)
        .onAppear { metrics.recordMount() }
    }
}

// MARK: Expand Panel

struct DetailPanel: View {
    let item: ConditionalDemoItem
    let isExpanded: Bool
    let metrics: ConditionalPerfMetrics

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
        // Never removed from the tree — just resized and faded. onAppear fires
        // exactly once per row for the entire lifetime of the screen, no matter
        // how many times the user taps expand/collapse.
        .frame(maxHeight: isExpanded ? nil : 0, alignment: .top)
        .opacity(isExpanded ? 1 : 0)
        .clipped()
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
        .onAppear { metrics.recordMount() }
    }
}

// MARK: Selection Chrome
//
// The true inert-modifier counterpart to the "EmptyView() trap": one shape,
// always present, with `Color.clear` / zero line width as its literal
// "nothing to draw" state — never a different view type.

struct SelectionOverlay: ViewModifier {
    let isSelected: Bool
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background(isSelected ? tint.opacity(0.12) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? tint : Color.clear, lineWidth: isSelected ? 2 : 0)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

extension View {
    func selectionOverlay(isSelected: Bool, tint: Color) -> some View {
        modifier(SelectionOverlay(isSelected: isSelected, tint: tint))
    }
}
