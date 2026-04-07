import SwiftUI

private enum CycleGridMetrics {
    static let leadingWidth: CGFloat = 156
}

struct ContentView: View {
    @StateObject private var viewModel = RhythmExplorerViewModel()
    @State private var showsTempoPopover = false

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset = max(20, min(proxy.size.width * 0.055, 34))
            let contentWidth = min(proxy.size.width - (horizontalInset * 2), 1180)
            let topInset = proxy.safeAreaInsets.top

            ZStack {
                AppBackground()

                VStack(spacing: 0) {
                    mapSection(horizontalInset: horizontalInset, topInset: topInset)
                        .frame(maxWidth: .infinity)
                        .frame(height: 286 + topInset)
                        .padding(.top, -topInset)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 30) {
                            heroSection
                            explanationSection
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
        }
        .preferredColorScheme(.dark)
    }

    private func mapSection(horizontalInset: CGFloat, topInset: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            Color.black

            RhythmSpaceMap(
                rhythms: viewModel.rhythms,
                selectedRhythmID: viewModel.selectedRhythm.id,
                relatedRhythmIDs: Set(viewModel.selectedRhythm.relatedRhythmIDs),
                relatedTint: viewModel.selectedRhythm.region.tint
            ) { rhythm in
                viewModel.selectRhythm(rhythm)
            }
            .padding(.top, topInset + 34)

            appToolbar
                .padding(.trailing, horizontalInset)
                .padding(.top, topInset + 12)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
        }
    }

    private func bottomSequencer(contentWidth: CGFloat, horizontalInset: CGFloat) -> some View {
        cycleSection
            .frame(maxWidth: contentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, horizontalInset)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Color.black)
            .opacity(viewModel.hasPendingCycleChange ? 0.42 : 1)
            .disabled(viewModel.hasPendingCycleChange)
            .animation(.easeInOut(duration: 0.18), value: viewModel.hasPendingCycleChange)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionDivider()

            HStack(alignment: .center, spacing: 16) {
                HStack(spacing: 8) {
                    Text(viewModel.selectedRhythm.tradition)
                    DotSeparator()
                    Text(viewModel.selectedRhythm.family)
                    DotSeparator()
                    Text(viewModel.selectedRhythm.cycle.meter)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

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

        }
    }

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionDivider()

            Text(viewModel.selectedVariant.hearingFocus)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.84))
                .fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                StructureOverlayView(
                    variant: viewModel.selectedVariant,
                    cycle: viewModel.selectedRhythm.cycle,
                    currentStep: viewModel.currentStep
                )
                .padding(.vertical, 2)
            }
        }
    }

    private var cycleSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionDivider()

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

    private var appToolbar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                Button(action: viewModel.togglePlayback) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(ToolbarIconButtonStyle(tint: viewModel.selectedRhythm.region.tint))

                Button {
                    showsTempoPopover.toggle()
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
                .overlay(alignment: .topLeading) {
                    if showsTempoPopover {
                        tempoPopover
                            .padding(.top, 44)
                    }
                }

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
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var tempoPopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("BPM")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 12)

                Text("\(Int(viewModel.bpm.rounded()))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            TempoTrack(
                value: viewModel.bpm,
                preferredValue: viewModel.selectedRhythm.preferredTempo,
                nativeRange: viewModel.selectedRhythm.tempoRange,
                sliderBounds: viewModel.sliderRange,
                tint: viewModel.selectedRhythm.region.tint,
                onChange: viewModel.setTempo
            )
            .frame(width: 272, height: 72)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
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
    let rhythms: [RhythmDefinition]
    let selectedRhythmID: String
    let relatedRhythmIDs: Set<String>
    let relatedTint: Color
    let onSelect: (RhythmDefinition) -> Void
    @State private var hasCentered = false

    private let viewportHeight: CGFloat = 248

    var body: some View {
        GeometryReader { proxy in
            let viewportSize = proxy.size
            let canvasSize = CGSize(
                width: max(viewportSize.width * 1.34, 760),
                height: max(viewportHeight + 84, 336)
            )

            ScrollViewReader { reader in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack {
                        zoneCanvas(size: canvasSize)
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
                .onChange(of: selectedRhythmID) { rhythmID in
                    DispatchQueue.main.async {
                        withAnimation(.snappy(duration: 0.32)) {
                            reader.scrollTo(rhythmID, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: viewportHeight)
    }

    @ViewBuilder
    private func zoneCanvas(size: CGSize) -> some View {
        ZStack {
            ForEach(RhythmMapZone.allCases) { zone in
                Ellipse()
                    .fill(zone.color.opacity(0.16))
                    .frame(
                        width: size.width * zone.widthRatio,
                        height: size.height * zone.heightRatio
                    )
                    .blur(radius: 26)
                    .position(zone.center.point(in: size))
            }
        }
    }

    @ViewBuilder
    private func mapCanvas(size: CGSize) -> some View {
        ZStack {
            ForEach(rhythms) { rhythm in
                RhythmSpaceNode(
                    title: rhythm.name,
                    isSelected: selectedRhythmID == rhythm.id,
                    isRelated: relatedRhythmIDs.contains(rhythm.id),
                    tint: rhythm.mapZone.color,
                    relatedTint: relatedTint
                ) {
                    onSelect(rhythm)
                }
                .id(rhythm.id)
                .position(rhythm.mapPoint.point(in: size))
            }
        }
    }
}

private struct RhythmSpaceNode: View {
    let title: String
    let isSelected: Bool
    let isRelated: Bool
    let tint: Color
    let relatedTint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            nodeLabel
        }
        .buttonStyle(.plain)
    }

    private var nodeLabel: some View {
        Text(title)
            .font(.footnote.weight(fontWeight))
            .lineLimit(1)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(nodeBackground)
            .foregroundStyle(foregroundColor)
            .shadow(color: shadowColor, radius: 18)
    }

    private var nodeBackground: some View {
        Capsule()
            .fill(backgroundFill)
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    private var fontWeight: Font.Weight {
        isSelected ? .bold : .semibold
    }

    private var horizontalPadding: CGFloat {
        isSelected ? 16 : 14
    }

    private var verticalPadding: CGFloat {
        isSelected ? 10 : 9
    }

    private var backgroundFill: Color {
        if isSelected {
            return tint.opacity(0.22)
        }
        if isRelated {
            return relatedTint.opacity(0.10)
        }
        return Color.white.opacity(0.06)
    }

    private var borderColor: Color {
        if isSelected {
            return tint.opacity(0.72)
        }
        if isRelated {
            return relatedTint.opacity(0.46)
        }
        return Color.white.opacity(0.08)
    }

    private var foregroundColor: Color {
        if isSelected {
            return tint
        }
        if isRelated {
            return relatedTint.opacity(0.96)
        }
        return Color.primary.opacity(0.92)
    }

    private var shadowColor: Color {
        if isSelected {
            return tint.opacity(0.28)
        }
        if isRelated {
            return relatedTint.opacity(0.16)
        }
        return .clear
    }
}

private struct RhythmSpacePoint {
    let x: CGFloat
    let y: CGFloat

    func point(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

private struct StructureOverlayView: View {
    let variant: RhythmVariant
    let cycle: RhythmCycle
    let currentStep: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StructureLaneRow(
                title: "Pulse",
                cycle: cycle,
                currentStep: currentStep,
                tint: LaneRole.pulse.tint,
                weights: pulseWeights
            )

            StructureLaneRow(
                title: "Offbeats",
                cycle: cycle,
                currentStep: currentStep,
                tint: .yellow,
                weights: offbeatWeights
            )

            StructureLaneRow(
                title: "Backbeat / Anchors",
                cycle: cycle,
                currentStep: currentStep,
                tint: LaneRole.backbeatHand.tint,
                weights: backbeatWeights
            )

            StructureLaneRow(
                title: "Accents",
                cycle: cycle,
                currentStep: currentStep,
                tint: .orange,
                weights: accentWeights
            )
        }
    }

    private var pulseWeights: [Double] {
        (0..<cycle.stepCount).map { cycle.isPulseStart($0) ? 1 : 0 }
    }

    private var offbeatWeights: [Double] {
        (0..<cycle.stepCount).map(offbeatWeight)
    }

    private var backbeatWeights: [Double] {
        let focusedRoles: Set<LaneRole> = [.backbeatHand, .timeline]
        let focusedWeights = normalizedWeights(for: focusedRoles)
        if focusedWeights.contains(where: { $0 > 0.01 }) {
            return focusedWeights
        }
        return normalizedWeights(for: [.backbeatHand, .timeline, .lowDrum])
    }

    private var accentWeights: [Double] {
        let weights = (0..<cycle.stepCount).map { step in
            variant.lanes
                .compactMap { lane in
                    lane.event(at: step).map { event in
                        event.isAccent ? event.intensity : event.intensity * 0.55
                    }
                }
                .reduce(0, +)
        }

        return normalize(weights)
    }

    private func normalizedWeights(for roles: Set<LaneRole>) -> [Double] {
        let weights = (0..<cycle.stepCount).map { step in
            variant.lanes
                .filter { roles.contains($0.role) }
                .compactMap { $0.event(at: step)?.intensity }
                .reduce(0, +)
        }

        return normalize(weights)
    }

    private func offbeatWeight(for step: Int) -> Double {
        guard !cycle.isPulseStart(step) else { return 0 }
        return cycle.label(for: step) == "&" ? 1 : 0.58
    }

    private func normalize(_ values: [Double]) -> [Double] {
        guard let maxValue = values.max(), maxValue > 0 else { return values }
        return values.map { $0 / maxValue }
    }
}

private struct StructureLaneRow: View {
    let title: String
    let cycle: RhythmCycle
    let currentStep: Int?
    let tint: Color
    let weights: [Double]

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: CycleGridMetrics.leadingWidth, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(Array(weights.indices), id: \.self) { step in
                    let weight = weights[step]

                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(backgroundFill(for: step))

                        if weight > 0 {
                            Capsule()
                                .fill(tint.opacity(0.92))
                                .frame(
                                    width: max(cellWidth * 0.24, 6),
                                    height: max(6, CGFloat(weight) * 22)
                                )
                                .padding(.bottom, 4)
                        }

                        if currentStep == step {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(tint.opacity(0.84), lineWidth: 1.2)
                        }

                        if cycle.isBarBreak(after: step) {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 2, height: 26)
                        }
                    }
                    .frame(width: cellWidth, height: 26)
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

    private func backgroundFill(for step: Int) -> Color {
        if currentStep == step {
            return tint.opacity(0.16)
        }
        if cycle.isPulseStart(step) {
            return Color.white.opacity(0.07)
        }
        return Color.white.opacity(0.03)
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
    let preferredValue: Double
    let nativeRange: ClosedRange<Double>
    let sliderBounds: ClosedRange<Double>
    let tint: Color
    let onChange: (Double) -> Void

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = max(proxy.size.width, 1)
            let nativeStart = xPosition(for: nativeRange.lowerBound, width: totalWidth)
            let nativeEnd = xPosition(for: nativeRange.upperBound, width: totalWidth)
            let preferredX = xPosition(for: preferredValue, width: totalWidth)
            let currentX = xPosition(for: value, width: totalWidth)

            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    Capsule()
                        .fill(tint.opacity(0.24))
                        .frame(width: max(nativeEnd - nativeStart, 12), height: 8)
                        .offset(x: nativeStart)

                    Capsule()
                        .fill(tint.opacity(0.55))
                        .frame(width: 2, height: 20)
                        .offset(x: preferredX - 1)

                    Circle()
                        .fill(tint)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.48), lineWidth: 2)
                        )
                        .offset(x: currentX - 9)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            updateValue(at: gesture.location.x, width: totalWidth)
                        }
                )

                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int(nativeRange.lowerBound.rounded()))")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Pref \(Int(preferredValue.rounded()))")
                        .foregroundStyle(tint.opacity(0.96))
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("\(Int(nativeRange.upperBound.rounded()))")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
        }
    }

    private func xPosition(for tempo: Double, width: CGFloat) -> CGFloat {
        CGFloat(normalized(tempo)) * width
    }

    private func normalized(_ tempo: Double) -> Double {
        let span = sliderBounds.upperBound - sliderBounds.lowerBound
        guard span > 0 else { return 0 }
        return (tempo - sliderBounds.lowerBound) / span
    }

    private func updateValue(at locationX: CGFloat, width: CGFloat) {
        let clampedX = min(max(locationX, 0), width)
        let normalizedX = Double(clampedX / width)
        let span = sliderBounds.upperBound - sliderBounds.lowerBound
        let rawValue = sliderBounds.lowerBound + (normalizedX * span)
        onChange(rawValue.rounded())
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

private enum RhythmMapZone: String, CaseIterable, Identifiable {
    case electronic
    case jazz
    case latin
    case world

    var id: String { rawValue }

    var center: RhythmSpacePoint {
        switch self {
        case .electronic: RhythmSpacePoint(x: 0.24, y: 0.24)
        case .jazz: RhythmSpacePoint(x: 0.78, y: 0.23)
        case .latin: RhythmSpacePoint(x: 0.34, y: 0.73)
        case .world: RhythmSpacePoint(x: 0.77, y: 0.72)
        }
    }

    var widthRatio: CGFloat {
        switch self {
        case .electronic: 0.34
        case .jazz: 0.24
        case .latin: 0.42
        case .world: 0.28
        }
    }

    var heightRatio: CGFloat {
        switch self {
        case .electronic: 0.46
        case .jazz: 0.34
        case .latin: 0.44
        case .world: 0.36
        }
    }

    var color: Color {
        switch self {
        case .electronic: .blue
        case .jazz: .indigo
        case .latin: .orange
        case .world: .teal
        }
    }
}

private extension RhythmDefinition {
    var mapZone: RhythmMapZone {
        switch id {
        case "classic-techno", "house-core", "two-step", "four-by-four-garage", "boom-bap":
            .electronic
        case "jazz-ride", "jazz-waltz":
            .jazz
        case "cumbia", "bossa-nova", "samba", "son-clave", "dembow":
            .latin
        default:
            .world
        }
    }

    var mapPoint: RhythmSpacePoint {
        switch id {
        case "classic-techno": RhythmSpacePoint(x: 0.14, y: 0.23)
        case "house-core": RhythmSpacePoint(x: 0.26, y: 0.29)
        case "two-step": RhythmSpacePoint(x: 0.28, y: 0.12)
        case "four-by-four-garage": RhythmSpacePoint(x: 0.40, y: 0.16)
        case "boom-bap": RhythmSpacePoint(x: 0.43, y: 0.31)
        case "jazz-ride": RhythmSpacePoint(x: 0.73, y: 0.26)
        case "jazz-waltz": RhythmSpacePoint(x: 0.83, y: 0.16)
        case "cumbia": RhythmSpacePoint(x: 0.12, y: 0.69)
        case "dembow": RhythmSpacePoint(x: 0.24, y: 0.56)
        case "son-clave": RhythmSpacePoint(x: 0.28, y: 0.80)
        case "samba": RhythmSpacePoint(x: 0.47, y: 0.61)
        case "bossa-nova": RhythmSpacePoint(x: 0.57, y: 0.76)
        default: RhythmSpacePoint(x: 0.72, y: 0.72)
        }
    }
}

private extension RhythmRegion {

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
