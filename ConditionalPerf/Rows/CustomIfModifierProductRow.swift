import SwiftUI

// MARK: - Demo B: The Custom `.if()` Modifier
//
// Same visual result, same UNSTABLE leaves (OnlineDot/OfflineDot,
// FilledStarButton/OutlineStarButton, etc.) as the raw if/else demo — the
// only thing that changes here is the syntax used to switch between them.
// If your instinct reading this file is "this looks cleaner and safer than
// Demo A," that instinct is exactly the trap: `.if()` desugars to the same
// `_ConditionalContent` (or `ModifiedContent<Content, Self>` swapped against
// `Self`) that raw if/else produces. Every mount count in the metrics HUD
// for this screen should land within noise of Demo A's — that equality IS
// the result.

struct CustomIfModifierProductRow: View {
    @Binding var item: ConditionalDemoItem
    let displayMode: ProductDisplayMode
    let metrics: ConditionalPerfMetrics

    var body: some View {
        // Still a real structural swap — `.if()` doesn't help here either,
        // because both branches need genuinely different layouts, not just
        // a modifier tweak. Written as a plain if/else since that's how this
        // particular decision reads in real code even for teams that reach
        // for `.if()` everywhere else.
        if displayMode == .detailed {
            DetailedCustomIfCard(item: $item, metrics: metrics)
        } else {
            CompactCustomIfCard(item: $item, metrics: metrics)
        }
    }
}

struct DetailedCustomIfCard: View {
    @Binding var item: ConditionalDemoItem
    let metrics: ConditionalPerfMetrics

    var body: some View {
        let _ = metrics.recordBodyEval()

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                AvatarCircle(category: item.category)
                    .if(item.isOnline, then: { avatar in
                        avatar.overlay(alignment: .bottomTrailing) { OnlineDot(metrics: metrics) }
                    }, else: { avatar in
                        avatar.overlay(alignment: .bottomTrailing) { OfflineDot(metrics: metrics) }
                    })

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

                EmptyView()
                    .if(item.isFavorite, then: { _ in
                        FilledStarButton(metrics: metrics) { item.isFavorite.toggle() }
                    }, else: { _ in
                        OutlineStarButton(metrics: metrics) { item.isFavorite.toggle() }
                    })
            }

            HStack {
                EmptyView()
                    .if(item.discountPercent != nil, then: { _ in
                        DiscountedPriceTag(price: item.price, discountPercent: item.discountPercent ?? 0, metrics: metrics)
                    }, else: { _ in
                        RegularPriceTag(price: item.price, metrics: metrics)
                    })

                Spacer()

                EmptyView()
                    .if(item.inStock, then: { _ in
                        InStockBadge(metrics: metrics)
                    }, else: { _ in
                        OutOfStockBadge(metrics: metrics)
                    })
            }

            Button {
                item.isExpanded.toggle()
            } label: {
                HStack(alignment: .top) {
                    EmptyView()
                        .if(item.isExpanded, then: { _ in
                            ExpandedDetailPanel(item: item, metrics: metrics)
                        }, else: { _ in
                            CollapsedDetailHint(metrics: metrics)
                        })
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
        // The single-branch form is the most dangerous of all: there's no
        // visible "else" at the call site, so it *reads* like a safe,
        // inert toggle. It still swaps identity underneath.
        .if(item.isSelected) { card in
            card.overlay { SelectionChrome(tint: item.category.tint, metrics: metrics) }
        }
        .onTapGesture { item.isSelected.toggle() }
    }
}

struct CompactCustomIfCard: View {
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
                EmptyView()
                    .if(item.discountPercent != nil, then: { _ in
                        DiscountedPriceTag(price: item.price, discountPercent: item.discountPercent ?? 0, metrics: metrics)
                    }, else: { _ in
                        RegularPriceTag(price: item.price, metrics: metrics)
                    })
            }

            Spacer(minLength: 8)

            EmptyView()
                .if(item.inStock, then: { _ in
                    InStockBadge(metrics: metrics)
                }, else: { _ in
                    OutOfStockBadge(metrics: metrics)
                })

            EmptyView()
                .if(item.isFavorite, then: { _ in
                    FilledStarButton(metrics: metrics) { item.isFavorite.toggle() }
                }, else: { _ in
                    OutlineStarButton(metrics: metrics) { item.isFavorite.toggle() }
                })
        }
        .padding(10)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .if(item.isSelected) { card in
            card.overlay { SelectionChrome(tint: item.category.tint, metrics: metrics) }
        }
        .onTapGesture { item.isSelected.toggle() }
    }
}
