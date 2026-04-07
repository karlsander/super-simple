import SwiftUI

private enum CycleGridMetrics {
    static let leadingWidth: CGFloat = 156
}

struct ContentView: View {
    @StateObject private var viewModel = RhythmExplorerViewModel()
    @State private var showsTempoOverlay = false

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset = max(20, min(proxy.size.width * 0.055, 34))
            let contentWidth = min(proxy.size.width - (horizontalInset * 2), 1180)

            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    mapSection
                        .frame(maxWidth: contentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, horizontalInset)
                        .padding(.top, 12)
                        .padding(.bottom, 14)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 30) {
                            browseSection
                            heroSection
                            mixSection
                        }
                        .frame(maxWidth: contentWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaPadding(.horizontal, horizontalInset)
                    .scrollClipDisabled()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomSequencer(contentWidth: contentWidth, horizontalInset: horizontalInset)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                appToolbar(contentWidth: contentWidth, horizontalInset: horizontalInset)
            }
            .overlay {
                if showsTempoOverlay {
                    tempoOverlay
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var mapSection: some View {
        RhythmSpaceMap(selectedRegion: viewModel.selectedRegion) { region in
            viewModel.selectRegion(region)
        }
    }

    private func bottomSequencer(contentWidth: CGFloat, horizontalInset: CGFloat) -> some View {
        cycleSection
            .frame(maxWidth: contentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, horizontalInset)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.86),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionDivider()

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.selectedRhythm.name)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .tracking(-1.0)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(viewModel.selectedRhythm.tradition)
                        DotSeparator()
                        Text(viewModel.selectedRhythm.family)
                        DotSeparator()
                        Text(viewModel.selectedRhythm.cycle.meter)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                TierBadge(tier: viewModel.selectedRhythm.tier)
            }

            Text(viewModel.selectedRhythm.summary)
                .font(.body)
                .foregroundStyle(Color.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.selectedRhythm.hearingCue)
                .font(.title3.weight(.semibold))
                .foregroundStyle(viewModel.selectedRhythm.region.tint)

            AdaptiveFlow(minimum: 120, spacing: 10) {
                HeroMetric(title: "Pulse", value: viewModel.selectedRhythm.cycle.pulseUnitName)
                HeroMetric(title: "Grid", value: viewModel.selectedRhythm.cycle.stepUnitName)
                HeroMetric(title: "Feel", value: viewModel.selectedRhythm.cycle.nativeFeel)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.selectedRhythm.feelKeywords, id: \.self) { keyword in
                        Text(keyword)
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                }
                .padding(.vertical, 2)
            }

            if let mishearRisk = viewModel.selectedRhythm.mishearRisk {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Common Mishear")
                        .font(.caption.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)

                    Text(mishearRisk)
                        .font(.footnote)
                        .foregroundStyle(.primary.opacity(0.82))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Lane Roles")
                    .font(.caption.weight(.semibold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedVariant.lanes) { lane in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(lane.role.tint)
                                    .frame(width: 8, height: 8)

                                Text(lane.label)
                                    .font(.footnote.weight(.semibold))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.06))
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if !viewModel.nearbyRhythms.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nearby")
                        .font(.caption.weight(.semibold))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.nearbyRhythms) { rhythm in
                                Button {
                                    viewModel.selectRhythm(rhythm)
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(rhythm.name)
                                            .font(.footnote.weight(.semibold))
                                        Text(rhythm.family)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(Color.white.opacity(0.06))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    private var browseSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.filteredRhythms) { rhythm in
                    RhythmBrowserCard(
                        rhythm: rhythm,
                        isSelected: rhythm.id == viewModel.selectedRhythm.id
                    ) {
                        viewModel.selectRhythm(rhythm)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var mixSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionDivider()

            SectionTitle(title: "Variants", detail: nil)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.selectedRhythm.variants) { variant in
                        Button {
                            viewModel.selectVariant(variant)
                        } label: {
                            SelectionPill(
                                title: variant.name,
                                isSelected: variant.id == viewModel.selectedVariant.id,
                                tint: viewModel.selectedRhythm.region.tint
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var cycleSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionDivider()

            HStack(alignment: .top, spacing: 16) {
                Text(viewModel.selectedVariant.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.selectedRhythm.cycle.meter)
                        .font(.headline.weight(.semibold))

                    Text("\(viewModel.selectedRhythm.cycle.stepCount) steps")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    CountRowView(
                        cycle: viewModel.selectedRhythm.cycle,
                        currentStep: viewModel.currentStep
                    )

                    ForEach(viewModel.selectedVariant.lanes) { lane in
                        LaneRowView(
                            lane: lane,
                            cycle: viewModel.selectedRhythm.cycle,
                            currentStep: viewModel.currentStep,
                            isMuted: viewModel.isLaneMuted(lane.id),
                            onToggleLaneMute: {
                                viewModel.toggleLaneMute(lane.id)
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func appToolbar(contentWidth: CGFloat, horizontalInset: CGFloat) -> some View {
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: 8) {
                Button(action: viewModel.togglePlayback) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(ToolbarIconButtonStyle(tint: viewModel.selectedRhythm.region.tint))

                Button {
                    showsTempoOverlay = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "metronome")
                            .font(.system(size: 11, weight: .semibold))

                        Text("\(Int(viewModel.bpm.rounded()))")
                            .font(.footnote.weight(.semibold))
                            .monospacedDigit()
                    }
                }
                .buttonStyle(ToolbarPillButtonStyle())

                Menu {
                    ForEach(viewModel.samplePacks) { samplePack in
                        Button {
                            viewModel.selectSamplePack(samplePack)
                        } label: {
                            if samplePack.id == viewModel.selectedSamplePack.id {
                                Label(samplePack.name, systemImage: "checkmark")
                            } else {
                                Text(samplePack.name)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 11, weight: .semibold))

                        Text(viewModel.selectedSamplePack.name)
                            .font(.footnote.weight(.semibold))
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(maxWidth: 128)
                }
                .buttonStyle(ToolbarPillButtonStyle())
            }
        }
        .frame(maxWidth: contentWidth, alignment: .leading)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalInset)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var tempoOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    showsTempoOverlay = false
                }

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BPM")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text("\(Int(viewModel.bpm.rounded()))")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    }

                    Spacer()

                    Button {
                        showsTempoOverlay = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(ToolbarIconButtonStyle(tint: .white))
                }

                HStack {
                    Text("\(Int(viewModel.selectedRhythm.tempoRange.lowerBound))-\(Int(viewModel.selectedRhythm.tempoRange.upperBound)) BPM")
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)

                    Spacer()
                }

                TempoTrack(
                    value: viewModel.bpm,
                    nativeRange: viewModel.selectedRhythm.tempoRange,
                    sliderBounds: viewModel.sliderRange,
                    tint: viewModel.selectedRhythm.region.tint
                )
                .frame(height: 20)

                Slider(
                    value: Binding(
                        get: { viewModel.bpm },
                        set: { viewModel.setTempo($0) }
                    ),
                    in: viewModel.sliderRange,
                    step: 1
                )
                .tint(viewModel.selectedRhythm.region.tint)
            }
            .padding(20)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.94))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(24)
        }
    }
}

private struct AppBackground: View {
    var body: some View {
        Color.black
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(Color.blue.opacity(0.22))
                    .frame(width: 360)
                    .blur(radius: 120)
                    .offset(x: -80, y: -120)
            }
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.teal.opacity(0.16))
                    .frame(width: 320)
                    .blur(radius: 140)
                    .offset(x: 100, y: -140)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.14),
                        Color.black.opacity(0.32)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
    }
}

private struct DotSeparator: View {
    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(0.7))
            .frame(width: 4, height: 4)
    }
}

private struct SectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 0.5)
    }
}

private struct SectionTitle: View {
    let title: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)

            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.primary.opacity(0.88))
            }
        }
    }
}

private struct RhythmSpaceMap: View {
    let selectedRegion: RhythmRegion
    let onSelect: (RhythmRegion) -> Void
    @State private var hasCentered = false

    private let viewportHeight: CGFloat = 236

    var body: some View {
        GeometryReader { proxy in
            let viewportSize = proxy.size
            let canvasSize = CGSize(
                width: max(viewportSize.width * 1.32, 720),
                height: max(viewportHeight + 72, 308)
            )

            ScrollViewReader { reader in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack {
                        mapCanvas(size: canvasSize)

                        Color.clear
                            .frame(width: 1, height: 1)
                            .position(x: canvasSize.width * 0.5, y: canvasSize.height * 0.5)
                            .id("rhythm-space-center")
                    }
                    .frame(width: canvasSize.width, height: canvasSize.height)
                }
                .onAppear {
                    guard !hasCentered else { return }
                    hasCentered = true

                    DispatchQueue.main.async {
                        reader.scrollTo("rhythm-space-center", anchor: .center)
                    }
                }
                .onChange(of: selectedRegion) { region in
                    DispatchQueue.main.async {
                        withAnimation(.snappy(duration: 0.32)) {
                            reader.scrollTo(region.id, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: viewportHeight)
        .background(
            ZStack {
                Color.white.opacity(0.035)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.clear,
                        Color.white.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.vertical, 4)
    }

    private func connectionColor(for connection: RhythmSpaceConnection) -> Color {
        if selectedRegion == .all || connection.contains(selectedRegion) {
            return selectedRegion.tint.opacity(0.34)
        }
        return Color.white.opacity(0.10)
    }

    @ViewBuilder
    private func mapCanvas(size: CGSize) -> some View {
        ZStack {
            ForEach(RhythmSpaceConnection.allCases) { connection in
                let start = connection.from.spacePoint.point(in: size)
                let end = connection.to.spacePoint.point(in: size)

                Path { path in
                    path.move(to: start)
                    path.addLine(to: end)
                }
                .stroke(
                    connectionColor(for: connection),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round)
                )
            }

            ForEach(RhythmRegion.allCases) { region in
                RhythmSpaceNode(
                    title: region.title,
                    isSelected: selectedRegion == region,
                    tint: region.tint,
                    isPrimary: region == .all
                ) {
                    onSelect(region)
                }
                .id(region.id)
                .position(region.spacePoint.point(in: size))
            }
        }
    }
}

private struct RhythmSpaceNode: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(isPrimary ? .bold : .semibold))
                .lineLimit(1)
                .padding(.horizontal, isPrimary ? 16 : 14)
                .padding(.vertical, isPrimary ? 10 : 9)
                .background(
                    Capsule()
                        .fill(isSelected ? tint.opacity(0.22) : Color.white.opacity(0.06))
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? tint.opacity(0.72) : Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
                .foregroundStyle(isSelected ? tint : Color.primary.opacity(0.92))
                .shadow(color: isSelected ? tint.opacity(0.28) : .clear, radius: 18)
        }
        .buttonStyle(.plain)
    }
}

private struct RhythmSpacePoint {
    let x: CGFloat
    let y: CGFloat

    func point(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

private struct RhythmSpaceConnection: Identifiable, CaseIterable {
    let from: RhythmRegion
    let to: RhythmRegion

    var id: String { "\(from.id)-\(to.id)" }

    static let allCases: [RhythmSpaceConnection] = [
        .init(from: .all, to: .globalElectronic),
        .init(from: .all, to: .uk),
        .init(from: .all, to: .northAmerica),
        .init(from: .all, to: .caribbeanLatin),
        .init(from: .all, to: .afroCuban),
        .init(from: .all, to: .brazil),
        .init(from: .all, to: .jazzTradition),
        .init(from: .all, to: .world),
        .init(from: .globalElectronic, to: .uk),
        .init(from: .northAmerica, to: .uk),
        .init(from: .caribbeanLatin, to: .afroCuban),
        .init(from: .afroCuban, to: .brazil),
        .init(from: .jazzTradition, to: .world)
    ]

    func contains(_ region: RhythmRegion) -> Bool {
        from == region || to == region
    }
}

private struct RhythmBrowserCard: View {
    let rhythm: RhythmDefinition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 8) {
                    Text(rhythm.name)
                        .font(.headline.weight(.bold))
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    TierBadge(tier: rhythm.tier)
                }

                Text("\(rhythm.tradition) • \(rhythm.cycle.meter)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(rhythm.region.tint)
                    .lineLimit(1)

                Text(rhythm.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Text(rhythm.family)
                        .font(.caption.weight(.semibold))

                    Spacer(minLength: 8)

                    Text("\(Int(rhythm.defaultTempo)) BPM")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(width: 228, height: 138, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? rhythm.region.tint.opacity(0.20) : Color.white.opacity(0.05))
            )
            .overlay(alignment: .bottomLeading) {
                Capsule()
                    .fill(isSelected ? rhythm.region.tint : Color.clear)
                    .frame(width: 42, height: 4)
                    .padding(.leading, 16)
                    .padding(.bottom, 14)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct TierBadge: View {
    let tier: RhythmTier

    var body: some View {
        Text(tier.rawValue.uppercased())
            .font(.caption2.weight(.black))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(tier.tint.opacity(0.24))
            )
            .foregroundStyle(tier.tint)
    }
}

private struct HeroMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

private struct SelectionPill: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    var compact: Bool = false

    var body: some View {
        Text(title)
            .font((compact ? Font.footnote : Font.subheadline).weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, compact ? 12 : 14)
            .padding(.vertical, compact ? 8 : 10)
            .background(
                Capsule()
                    .fill(isSelected ? tint.opacity(0.22) : Color.white.opacity(0.06))
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? tint.opacity(0.72) : Color.clear, lineWidth: 1)
                    )
            )
            .foregroundStyle(isSelected ? tint : Color.primary.opacity(0.92))
    }
}

private struct TempoTrack: View {
    let value: Double
    let nativeRange: ClosedRange<Double>
    let sliderBounds: ClosedRange<Double>
    let tint: Color

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let nativeStart = CGFloat(normalized(nativeRange.lowerBound)) * totalWidth
            let nativeWidth = CGFloat(normalized(nativeRange.upperBound) - normalized(nativeRange.lowerBound)) * totalWidth
            let currentX = CGFloat(normalized(value)) * totalWidth

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))

                Capsule()
                    .fill(tint.opacity(0.24))
                    .frame(width: max(nativeWidth, 12))
                    .offset(x: nativeStart)

                Circle()
                    .fill(tint)
                    .frame(width: 12, height: 12)
                    .offset(x: currentX - 6)
            }
        }
    }

    private func normalized(_ tempo: Double) -> Double {
        let span = sliderBounds.upperBound - sliderBounds.lowerBound
        guard span > 0 else { return 0 }
        return (tempo - sliderBounds.lowerBound) / span
    }
}

private struct CountRowView: View {
    let cycle: RhythmCycle
    let currentStep: Int?

    var body: some View {
        HStack(spacing: 10) {
            Text("Count")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: CycleGridMetrics.leadingWidth, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(0..<cycle.stepCount, id: \.self) { step in
                    ZStack(alignment: .trailing) {
                        Text(cycle.label(for: step))
                            .font(.caption2.weight(cycle.isPulseStart(step) ? .bold : .regular))
                            .monospacedDigit()
                            .foregroundStyle(currentStep == step ? Color.black : Color.secondary)
                            .frame(width: cellWidth, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(currentStep == step ? Color.white.opacity(0.94) : headerFill(for: step))
                            )

                        if cycle.isBarBreak(after: step) {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 2, height: 24)
                        }
                    }
                }
            }
        }
    }

    private var cellWidth: CGFloat {
        switch cycle.stepCount {
        case 0...16: 28
        case 17...24: 24
        default: 20
        }
    }

    private func headerFill(for step: Int) -> Color {
        cycle.isPulseStart(step) ? Color.white.opacity(0.10) : Color.white.opacity(0.04)
    }
}

private struct LaneRowView: View {
    let lane: RhythmLane
    let cycle: RhythmCycle
    let currentStep: Int?
    let isMuted: Bool
    let onToggleLaneMute: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleLaneMute) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(lane.role.tint)
                            .frame(width: 10, height: 10)

                        Text(lane.label)
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(isMuted ? .secondary : .primary)
                            .lineLimit(1)
                    }

                    Text(lane.role.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(width: CycleGridMetrics.leadingWidth, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isMuted ? Color.white.opacity(0.03) : lane.role.tint.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isMuted ? Color.white.opacity(0.06) : lane.role.tint.opacity(0.24), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                ForEach(0..<cycle.stepCount, id: \.self) { step in
                    let event = lane.event(at: step)

                    ZStack(alignment: .trailing) {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(cellFill(for: step))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(borderColor(for: step), lineWidth: currentStep == step ? 1.2 : 0)
                            )

                        if let event {
                            Circle()
                                .fill(lane.role.tint.opacity(isMuted ? 0.18 : (event.isAccent ? 0.98 : 0.60)))
                                .frame(width: event.isAccent ? cellWidth * 0.56 : cellWidth * 0.42)
                                .overlay(
                                    Circle()
                                        .stroke(lane.role.tint.opacity(isMuted ? 0.28 : 0.90), lineWidth: 1)
                                )
                        }

                        if cycle.isBarBreak(after: step) {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 2, height: 30)
                        }
                    }
                    .frame(width: cellWidth, height: 30)
                }
            }
        }
        .opacity(isMuted ? 0.52 : 1)
    }

    private var cellWidth: CGFloat {
        switch cycle.stepCount {
        case 0...16: 28
        case 17...24: 24
        default: 20
        }
    }

    private func cellFill(for step: Int) -> Color {
        if currentStep == step {
            return lane.role.tint.opacity(isMuted ? 0.10 : 0.20)
        }
        if cycle.isPulseStart(step) {
            return Color.white.opacity(isMuted ? 0.04 : 0.08)
        }
        return Color.white.opacity(isMuted ? 0.015 : 0.035)
    }

    private func borderColor(for step: Int) -> Color {
        currentStep == step ? lane.role.tint : .clear
    }
}

private struct ToolbarIconButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.20 : 0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(tint.opacity(0.32), lineWidth: 1)
                        )
            )
            .foregroundStyle(tint.opacity(0.92))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private struct ToolbarPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.07))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .foregroundStyle(.primary.opacity(0.92))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct AdaptiveFlow<Content: View>: View {
    let minimum: CGFloat
    let spacing: CGFloat
    let content: Content

    init(minimum: CGFloat, spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.minimum = minimum
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimum, maximum: .infinity), spacing: spacing, alignment: .leading)],
            alignment: .leading,
            spacing: spacing
        ) {
            content
        }
    }
}

private extension RhythmRegion {
    var spacePoint: RhythmSpacePoint {
        switch self {
        case .all: RhythmSpacePoint(x: 0.50, y: 0.50)
        case .globalElectronic: RhythmSpacePoint(x: 0.24, y: 0.18)
        case .uk: RhythmSpacePoint(x: 0.56, y: 0.16)
        case .caribbeanLatin: RhythmSpacePoint(x: 0.33, y: 0.74)
        case .brazil: RhythmSpacePoint(x: 0.76, y: 0.56)
        case .afroCuban: RhythmSpacePoint(x: 0.57, y: 0.72)
        case .northAmerica: RhythmSpacePoint(x: 0.16, y: 0.48)
        case .jazzTradition: RhythmSpacePoint(x: 0.78, y: 0.24)
        case .world: RhythmSpacePoint(x: 0.50, y: 0.90)
        }
    }

    var tint: Color {
        switch self {
        case .all: Color.white.opacity(0.78)
        case .globalElectronic: .teal
        case .uk: .orange
        case .caribbeanLatin: .red
        case .brazil: .green
        case .afroCuban: .pink
        case .northAmerica: .blue
        case .jazzTradition: .indigo
        case .world: .purple
        }
    }
}

private extension LaneRole {
    var title: String {
        switch self {
        case .pulse: "Pulse"
        case .lowDrum: "Low Drum"
        case .backbeatHand: "Backbeat / Hand"
        case .closedHigh: "Closed High"
        case .openHigh: "Open High"
        case .timeline: "Timeline / Bell / Clave"
        case .texture: "Texture / Shaker"
        case .aux1: "Aux 1"
        case .aux2: "Aux 2"
        }
    }

    var tint: Color {
        switch self {
        case .pulse: Color.white.opacity(0.88)
        case .lowDrum: .green
        case .backbeatHand: .orange
        case .closedHigh: .blue
        case .openHigh: .mint
        case .timeline: .red
        case .texture: .yellow
        case .aux1: .purple
        case .aux2: .teal
        }
    }
}

private extension RhythmTier {
    var tint: Color {
        switch self {
        case .deep: .green
        case .solid: .orange
        case .stub: Color.white.opacity(0.68)
        }
    }
}

#Preview {
    ContentView()
}
