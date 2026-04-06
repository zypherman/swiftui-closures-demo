//
//  VariantAHeaderView.swift
//  Booking
//

import CommonUI
import SwiftUI

/// Fixed header variant A with brand logo centered at top and hotel name centered at bottom
struct VariantAHeaderView: View {
    /// URL for the hero image
    let imageURL: URL?

    /// URL for the brand logo
    let brandLogoURL: URL?

    /// Hotel name to display
    let hotelName: String

    /// Action to perform when back button is tapped
    let onBack: () -> Void

    /// When true, renders an X (close) icon instead of a back chevron
    var isCloseButton: Bool = false

    /// Action to perform when hotel details is tapped (brand logo)
    let onHotelDetails: () -> Void

    /// Safe area top inset (passed in since parent ignores safe area)
    var safeAreaTop: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Hero image background
                RemoteImage(url: imageURL)
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Gradient scrim for text readability
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0.00),
                        .init(color: .black.opacity(0.10), location: 0.45),
                        .init(color: .black.opacity(0.50), location: 0.70),
                        .init(color: .black.opacity(0.70), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Content overlay
                VStack(spacing: 24) {
                    // Top bar: Back button + centered brand logo
                    HStack(alignment: .center) {
                        FixedHeaderBackButton(action: onBack, isCloseButton: isCloseButton)

                        Spacer()

                        // Center: Brand logo in white rounded container (tappable for hotel details)
                        Button(action: onHotelDetails) {
                            Image(.Hotels.fallback)
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Spacer()

                        // Invisible spacer for symmetry with back button
                        Color.clear
                            .frame(width: 44, height: 44)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, safeAreaTop + 8)

                    // Bottom: Hotel name centered above the overlap zone
                    Text(hotelName)
                        .hyattFont(.standard(.body1(emphasized: true)))
                        .foregroundStyle(Color.Rebrand.Text.inverse)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 50)

                    Spacer()
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.blue, lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    GeometryReader { geometry in
        ScrollView {
            VStack(spacing: 16) {
                VariantAHeaderView(
                    imageURL: URL(string: "https://assets.hyatt.com/content/dam/hyatt/hyattdam/images/2019/10/25/1453/Great-Scotland-Yard-Hotel-P002-Exterior-Evening.jpg/Great-Scotland-Yard-Hotel-P002-Exterior-Evening.4x3.jpg"),
                    brandLogoURL: URL(string: "https://assets.hyatt.com/content/dam/hyatt/hyattdam/images/2021/01/20/1029/Hyatt-Centric-Logo.png"),
                    hotelName: "Hyatt Centric Chicago Magnificent Mile",
                    onBack: {},
                    onHotelDetails: {},
                    safeAreaTop: geometry.safeAreaInsets.top
                )
                .frame(height: 200 + geometry.safeAreaInsets.top)
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}


private var variantALayout: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top

            ScrollView {
                VStack(spacing: 16) {
                    VariantAHeaderView(
                        imageURL: viewModel.propertyDetail.mobileImageURL,
                        brandLogoURL: viewModel.brandLogoURL,
                        hotelName: viewModel.propertyDetail.name ?? "",
                        onBack: backAction,
                        isCloseButton: isCartCloseMode,
                        onHotelDetails: {
                            viewModel.trackHotelDetailsButtonTapped()
                            handleHotelDetailsTap()
                        },
                        safeAreaTop: safeAreaTop
                    )
                    .frame(height: 160 + safeAreaTop)
                    .onGeometryChange(for: CGFloat.self) { geo in
                        geo.frame(in: .global).maxY
                    } action: { newValue in
                        headerBottomY = newValue
                    }

                    Messages()
                        .padding(.top, -50)
                        .accessibilityIdentifierBranch("HotelMessages")
                        .onGeometryChange(for: CGRect.self) { geo in
                            geo.frame(in: .global)
                        } action: { rect in
                            overlayBottomY = rect.maxY
                            if rect.height > 0 {
                                hasOverlay = true
                            }
                        }

                    roomsAndRatesContent(includePointsCalendar: true)
                }
            }
            .overlay(alignment: .top) {
                CompactVariantAHeaderBar(
                    hotelName: viewModel.propertyDetail.name ?? "",
                    brandLogoURL: viewModel.brandLogoURL,
                    onBack: backAction,
                    isCloseButton: isCartCloseMode,
                    onHotelDetails: {
                        viewModel.trackHotelDetailsButtonTapped()
                        handleHotelDetailsTap()
                    },
                    safeAreaTop: safeAreaTop
                )
                .onGeometryChange(for: CGFloat.self) { geo in
                    geo.size.height
                } action: { newValue in
                    compactHeaderHeight = newValue
                }
                .opacity(showCompactHeader ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showCompactHeader)
                .allowsHitTesting(showCompactHeader)
            }
            .ignoresSafeArea(.container, edges: .top)
        }
    }

// Body
public var body: some View {
    Group {
            switch selectedVariant {
            case .base:
                baseLayout
                    .toolbarVisibility(.visible, for: .navigationBar)
                    .navigationTitle(ViewStrings.title)
            case .variantA:
                variantALayout
                    .toolbarVisibility(.hidden, for: .navigationBar)
            case .variantB:
                variantBLayout
                    .toolbarVisibility(.hidden, for: .navigationBar)
            }
        }
        .animation(.easeInOut, value: viewModel.showPoints)
        .animation(.easeInOut, value: viewModel.allMessages)
        .background(Color.Rebrand.Canvas.primary)
        .foregroundStyle(Color.Rebrand.Text.primary)
}