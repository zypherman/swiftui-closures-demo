import SwiftUI

// MARK: - Demo C: Inert Modifiers + the ViewBuilder nil-case
//
// One row type. One card type, for BOTH compact and detailed — no
// `if displayMode == .compact { CompactCard() } else { DetailedCard() }`
// anywhere. Every place Demo A/B swapped between two real view types, this
// version instead:
//
//   1. Feeds a Bool/optional straight into an existing modifier's argument
//      (`.fill(isOnline ? .green : .gray)`, `Image(systemName: isFavorite
//      ? "star.fill" : "star")`) — the "empty case" of the modifier IS the
//      alternate state, so there's nothing to swap.
//   2. Uses a bare `if condition { View() }` with NO else for anything
//      genuinely optional (ribbon, crown, subtitle, rating) — ViewBuilder's
//      `buildOptional` wraps that in `Optional<View>`, which SwiftUI diffs
//      by presence/absence, not by tearing down unrelated types.
//   3. For the two leaves that carry real state worth protecting
//      (`StatusDot`'s mount, `DetailPanel`'s content), keeps the view
//      permanently mounted and just resizes/fades it to nothing — the
//      "collapse instead of remove" trick.
//
// Compare `mounts` on this screen's HUD to Demo A/B's after flipping
// Compact ⇄ Detailed a few times: this one barely moves.

struct InertProductRow: View {
    @Binding var item: ConditionalDemoItem
    let displayMode: ProductDisplayMode
    let metrics: ConditionalPerfMetrics

    var body: some View {
        AdaptiveProductCard(item: $item, isCompact: displayMode == .compact, metrics: metrics)
    }
}

struct AdaptiveProductCard: View {
    @Binding var item: ConditionalDemoItem
    let isCompact: Bool
    let metrics: ConditionalPerfMetrics

    var body: some View {
        let _ = metrics.recordBodyEval()

        VStack(alignment: .leading, spacing: isCompact ? 6 : 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarCircle(category: item.category)
                    // Stays mounted always; only its visibility is toggled.
                    StatusDot(isOnline: item.isOnline, metrics: metrics)
                        .opacity(isCompact ? 0 : 1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(isCompact ? .subheadline.weight(.semibold) : .headline)
                            .lineLimit(1)
                        // Stateless flourishes: bare-if is already cheap, no
                        // collapse trick needed.
                        if item.isNew && !isCompact { NewRibbon() }
                        if item.isPremium && !isCompact { PremiumCrown() }
                    }

                    if !isCompact {
                        Text(item.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if item.rating > 0 {
                            RatingStarsView(rating: item.rating)
                        }
                    }
                }

                Spacer(minLength: 0)

                FavoriteButton(isFavorite: item.isFavorite, metrics: metrics) {
                    item.isFavorite.toggle()
                }
            }

            HStack {
                PriceTag(price: item.price, discountPercent: item.discountPercent, metrics: metrics)
                Spacer()
                AvailabilityLabel(inStock: item.inStock, metrics: metrics)
            }

            Button {
                item.isExpanded.toggle()
            } label: {
                HStack(alignment: .top) {
                    Text("Tap to see details")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .opacity(item.isExpanded ? 0 : 1)
                    Spacer(minLength: 8)
                    Image(systemName: item.isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .opacity(isCompact ? 0 : 1)
            .frame(maxHeight: isCompact ? 0 : nil)
            .clipped()

            // Never removed from the tree in ANY mode — see DetailPanel's
            // doc comment in StableConditionalLeaves.swift. Its mount count
            // stays at 1 per row for the lifetime of the screen no matter
            // how many times isExpanded or isCompact change.
            DetailPanel(item: item, isExpanded: item.isExpanded && !isCompact, metrics: metrics)
        }
        .productCardChrome()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 14 : 16))
        // Color.clear / lineWidth: 0 IS the nil case of an overlay stroke —
        // the exact modifier-level equivalent of the "EmptyView() trap" in
        // Demo A/B, done correctly.
        .selectionOverlay(isSelected: item.isSelected, tint: item.category.tint)
        .animation(.easeInOut(duration: 0.25), value: isCompact)
        .onTapGesture { item.isSelected.toggle() }
    }
}
