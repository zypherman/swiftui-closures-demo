import SwiftUI

// MARK: - Demo A: Raw if/else Branching
//
// This is the pattern that shows up in most real codebases: a plain `if
// condition { ViewA() } else { ViewB() }` for every piece of state that has
// two visual states. It reads naturally and every branch "does the right
// thing" in isolation. The cost is invisible until you profile it: every one
// of these branches compiles to `_ConditionalContent<ViewA, ViewB>`, and
// flipping the condition destroys whichever branch was mounted to build the
// other one from scratch.

struct IfElseProductRow: View {
    @Binding var item: ConditionalDemoItem
    let displayMode: ProductDisplayMode
    let metrics: ConditionalPerfMetrics

    var body: some View {
        // The single most expensive conditional in the whole demo: this swaps
        // EVERY row between two entirely different view types the instant
        // displayMode flips, tearing down all 42 rows' worth of child state at once.
        if displayMode == .detailed {
            DetailedIfElseCard(item: $item, metrics: metrics)
        } else {
            CompactIfElseCard(item: $item, metrics: metrics)
        }
    }
}

struct DetailedIfElseCard: View {
    @Binding var item: ConditionalDemoItem
    let metrics: ConditionalPerfMetrics

    var body: some View {
        let _ = metrics.recordBodyEval()

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarCircle(category: item.category)
                    if item.isOnline {
                        OnlineDot(metrics: metrics)
                    } else {
                        OfflineDot(metrics: metrics)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.name).font(.headline)
                        if item.isNew { NewRibbon() }
                        if item.isPremium { PremiumCrown() }
                    }
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if item.rating > 0 {
                        RatingStarsView(rating: item.rating)
                    }
                }

                Spacer(minLength: 0)

                if item.isFavorite {
                    FilledStarButton(metrics: metrics) { item.isFavorite.toggle() }
                } else {
                    OutlineStarButton(metrics: metrics) { item.isFavorite.toggle() }
                }
            }

            HStack {
                if let discount = item.discountPercent {
                    DiscountedPriceTag(price: item.price, discountPercent: discount, metrics: metrics)
                } else {
                    RegularPriceTag(price: item.price, metrics: metrics)
                }

                Spacer()

                if item.inStock {
                    InStockBadge(metrics: metrics)
                } else {
                    OutOfStockBadge(metrics: metrics)
                }
            }

            Button {
                item.isExpanded.toggle()
            } label: {
                HStack(alignment: .top) {
                    if item.isExpanded {
                        ExpandedDetailPanel(item: item, metrics: metrics)
                    } else {
                        CollapsedDetailHint(metrics: metrics)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: item.isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .productCardChrome()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            // The "EmptyView() trap": this LOOKS like a nil-case pattern but
            // isn't — see SelectionChrome's doc comment in UnstableConditionalLeaves.swift.
            if item.isSelected {
                SelectionChrome(tint: item.category.tint, metrics: metrics)
            } else {
                EmptyView()
            }
        }
        .onTapGesture { item.isSelected.toggle() }
    }
}

struct CompactIfElseCard: View {
    @Binding var item: ConditionalDemoItem
    let metrics: ConditionalPerfMetrics

    var body: some View {
        let _ = metrics.recordBodyEval()

        HStack(spacing: 12) {
            AvatarCircle(category: item.category)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let discount = item.discountPercent {
                    DiscountedPriceTag(price: item.price, discountPercent: discount, metrics: metrics)
                } else {
                    RegularPriceTag(price: item.price, metrics: metrics)
                }
            }

            Spacer(minLength: 8)

            if item.inStock {
                InStockBadge(metrics: metrics)
            } else {
                OutOfStockBadge(metrics: metrics)
            }

            if item.isFavorite {
                FilledStarButton(metrics: metrics) { item.isFavorite.toggle() }
            } else {
                OutlineStarButton(metrics: metrics) { item.isFavorite.toggle() }
            }
        }
        .padding(10)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            if item.isSelected {
                SelectionChrome(tint: item.category.tint, metrics: metrics)
            } else {
                EmptyView()
            }
        }
        .onTapGesture { item.isSelected.toggle() }
    }
}
