import SwiftUI

// MARK: - Pieces shared, unmodified, by all three row styles
//
// These use the bare `if condition { View() }` form with NO else branch.
// `@ViewBuilder` compiles that to `Optional<View>`, not `_ConditionalContent`.
// The type is always `Optional<NewRibbon>` — only the runtime payload flips
// between `.some(NewRibbon())` and `nil`. SwiftUI can diff an Optional by
// presence/absence far more cheaply than two unrelated concrete types, so
// this pattern is safe everywhere, including inside the "bad" row. The demo
// is not "avoid if" — it's "avoid if/else with two real branches."

struct AvatarCircle: View {
    let category: ConditionalDemoItem.Category

    var body: some View {
        Circle()
            .fill(category.tint.gradient)
            .frame(width: 44, height: 44)
            .overlay {
                Image(systemName: category.symbolName)
                    .foregroundStyle(.white)
                    .font(.system(size: 17, weight: .semibold))
            }
    }
}

struct RatingStarsView: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: index < rating ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
    }
}

struct NewRibbon: View {
    var body: some View {
        Text("NEW")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

struct PremiumCrown: View {
    var body: some View {
        Image(systemName: "crown.fill")
            .font(.caption)
            .foregroundStyle(.yellow)
    }
}

// MARK: - Reusable card chrome

struct ProductCardChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func productCardChrome() -> some View {
        modifier(ProductCardChrome())
    }
}
