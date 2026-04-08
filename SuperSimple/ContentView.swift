import SwiftUI

private enum CycleGridMetrics {
    static let leadingWidth: CGFloat = 220
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

                mapSection(horizontalInset: horizontalInset, topInset: topInset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, -topInset)
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
            .padding(.top, topInset)

            appToolbar
                .padding(.trailing, horizontalInset)
                .padding(.top, topInset + 12)
        }
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.58),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 44)
            .allowsHitTesting(false)
        }
        .clipped()
    }

    private func bottomSequencer(contentWidth: CGFloat, horizontalInset: CGFloat) -> some View {
        cycleSection
            .frame(maxWidth: contentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, horizontalInset)
            .padding(.top, 4)
            .padding(.bottom, 10)
            .background(Color.black)
    }

    private var cycleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepSequencerGrid
            variantSelector
        }
    }

    private var stepSequencerGrid: some View {
        let guideData = EmbeddedSequencerGuides(
            variant: viewModel.selectedVariant,
            cycle: viewModel.selectedRhythm.cycle
        )

        return ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                CountRowView(
                    cycle: viewModel.selectedRhythm.cycle,
                    currentStep: viewModel.currentStep
                )

                ForEach(viewModel.selectedVariant.lanes) { lane in
                    let isMuted = viewModel.isLaneMuted(lane.id)

                    VStack(alignment: .leading, spacing: 6) {
                        LaneRowView(
                            lane: lane,
                            cycle: viewModel.selectedRhythm.cycle,
                            variantSwingAmount: viewModel.selectedVariant.swingAmount,
                            currentStep: viewModel.currentStep,
                            isMuted: isMuted,
                            offbeatWeights: lane.slot == .pulse ? guideData.offbeatWeights : nil,
                            onToggleLaneMute: {
                                viewModel.toggleLaneMute(lane.id)
                            }
                        )

                        if let note = lane.note {
                            LaneEditorialNoteView(
                                text: note,
                                cycle: viewModel.selectedRhythm.cycle,
                                tint: lane.role.tint,
                                isDimmed: isMuted
                            )
                        }

                        ForEach(guideData.attachedGuides(for: lane)) { guide in
                            EmbeddedGuideRowView(
                                title: guide.title,
                                cycle: viewModel.selectedRhythm.cycle,
                                currentStep: viewModel.currentStep,
                                tint: guide.tint,
                                weights: guide.weights,
                                isInset: true,
                                isDimmed: guide.dimsWithHostLane ? isMuted : false
                            )
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var variantSelector: some View {
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
                .overlay(alignment: .topTrailing) {
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
                sliderBounds: viewModel.sliderRange,
                highlightedRange: viewModel.selectedRhythm.tempoRange,
                preferredValue: viewModel.selectedRhythm.preferredTempo,
                tint: viewModel.selectedRhythm.region.tint,
                onChange: viewModel.setTempo
            )
            .frame(width: 304, height: 24)
        }
        .frame(width: 332)
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

private struct RhythmSpaceMap: View {
    let rhythms: [RhythmDefinition]
    let selectedRhythmID: String
    let relatedRhythmIDs: Set<String>
    let relatedTint: Color
    let onSelect: (RhythmDefinition) -> Void
    @State private var hasCentered = false

    var body: some View {
        GeometryReader { proxy in
            let viewportSize = proxy.size
            let canvasSize = CGSize(
                width: max(viewportSize.width * 1.34, 760),
                height: max(viewportSize.height * 1.18, 420)
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
        .frame(maxHeight: .infinity)
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

private struct EmbeddedSequencerGuides {
    struct Guide: Identifiable {
        let id: String
        let title: String
        let tint: Color
        let weights: [Double]
        let hostLaneID: String
        let dimsWithHostLane: Bool
    }

    let variant: RhythmVariant
    let cycle: RhythmCycle

    var offbeatWeights: [Double] {
        (0..<cycle.stepCount).map(offbeatWeight)
    }

    func attachedGuides(for lane: RhythmLane) -> [Guide] {
        guides.filter { $0.hostLaneID == lane.id }
    }

    private var guides: [Guide] {
        [backbeatGuide, accentGuide].compactMap { $0 }
    }

    private var backbeatGuide: Guide? {
        let candidateLanes = structuralCandidateLanes
        guard !candidateLanes.isEmpty else { return nil }

        let weights = normalizedWeights(for: candidateLanes)
        guard weights.contains(where: { $0 > 0.01 }) else { return nil }

        let hostLaneID = resolveHostLaneID(preferred: variant.backbeatGuideHostLaneID)
        guard let hostLaneID else { return nil }

        return Guide(
            id: "backbeat-anchors",
            title: "Anchors",
            tint: tint(
                for: hostLaneID,
                preferred: variant.backbeatGuideHostLaneID,
                fallback: SharedLineRole.timeline.tint
            ),
            weights: weights,
            hostLaneID: hostLaneID,
            dimsWithHostLane: hostLaneID != clickLaneID
        )
    }

    private var accentGuide: Guide? {
        let candidateLanes = accentCandidateLanes
        guard !candidateLanes.isEmpty else { return nil }

        let weights = normalizedAccentWeights(for: candidateLanes)
        guard weights.contains(where: { $0 > 0.01 }) else { return nil }

        let hostLaneID = resolveHostLaneID(preferred: variant.accentGuideHostLaneID)
        guard let hostLaneID else { return nil }

        return Guide(
            id: "accents",
            title: "Accents",
            tint: tint(
                for: hostLaneID,
                preferred: variant.accentGuideHostLaneID,
                fallback: .pink
            ),
            weights: weights,
            hostLaneID: hostLaneID,
            dimsWithHostLane: hostLaneID != clickLaneID
        )
    }

    private var clickLaneID: String? {
        variant.lanes.first(where: { $0.voice == .click })?.id ?? variant.lanes.first?.id
    }

    private var structuralCandidateLanes: [RhythmLane] {
        let relevantRoles: [SharedLineRole] = [.frame, .counterline, .timeline, .foundation]
        return relevantRoles.compactMap { role in
            variant.lanes.first { $0.role == role && !$0.events.isEmpty }
        }
    }

    private var accentCandidateLanes: [RhythmLane] {
        variant.lanes.filter { lane in
            lane.role != .guide && lane.events.contains(where: \.isAccent)
        }
    }

    private func normalizedWeights(for lanes: [RhythmLane]) -> [Double] {
        let weights = (0..<cycle.stepCount).map { step in
            lanes
                .compactMap { $0.event(at: step)?.intensity }
                .reduce(0.0, +)
        }

        return normalize(weights)
    }

    private func normalizedAccentWeights(for lanes: [RhythmLane]) -> [Double] {
        let weights = (0..<cycle.stepCount).map { step in
            lanes
                .compactMap { lane in
                    guard let event = lane.event(at: step), event.isAccent else { return nil }
                    return event.intensity
                }
                .reduce(0.0, +)
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

    private func resolveHostLaneID(preferred: String?) -> String? {
        if let preferred, variant.lanes.contains(where: { $0.id == preferred }) {
            return preferred
        }
        return clickLaneID
    }

    private func tint(
        for hostLaneID: String,
        preferred: String?,
        fallback: Color
    ) -> Color {
        if preferred == nil, hostLaneID == clickLaneID {
            return fallback
        }
        variant.lanes.first(where: { $0.id == hostLaneID })?.role.tint ?? fallback
    }
}

private struct EmbeddedGuideRowView: View {
    let title: String
    let cycle: RhythmCycle
    let currentStep: Int?
    let tint: Color
    let weights: [Double]
    let isInset: Bool
    let isDimmed: Bool

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                if isInset {
                    Image(systemName: "arrow.turn.down.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.82))
                }

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, isInset ? 18 : 0)
            .frame(width: CycleGridMetrics.leadingWidth, alignment: .leading)

            HStack(spacing: cycle.sequencerStepSpacing) {
                ForEach(Array(weights.indices), id: \.self) { step in
                    let weight = weights[step]

                    ZStack(alignment: .trailing) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(backgroundFill(for: step))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(currentStep == step ? tint.opacity(0.64) : .clear, lineWidth: 1)
                            )

                        if weight > 0 {
                            Capsule()
                                .fill(tint.opacity(isDimmed ? 0.34 : 0.84))
                                .frame(
                                    width: max(cellWidth * 0.26, 6),
                                    height: max(4, CGFloat(weight) * 11)
                                )
                                .padding(.bottom, 2)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        }

                        if cycle.isBarBreak(after: step) {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 2, height: 20)
                        }
                    }
                    .frame(width: cellWidth, height: 18)
                }
            }
        }
        .opacity(isDimmed ? 0.78 : 1)
    }

    private var cellWidth: CGFloat {
        cycle.sequencerCellWidth
    }

    private func backgroundFill(for step: Int) -> Color {
        if currentStep == step {
            return tint.opacity(0.12)
        }
        if cycle.isBarStart(step) {
            let barLift = cycle.barIndex(for: step).isMultiple(of: 2) ? 0.04 : 0.07
            return Color.white.opacity(barLift)
        }
        if cycle.isPulseStart(step) {
            let barLift = cycle.barIndex(for: step).isMultiple(of: 2) ? 0.05 : 0.07
            return Color.white.opacity(barLift)
        }
        let barLift = cycle.barIndex(for: step).isMultiple(of: 2) ? 0.025 : 0.04
        return Color.white.opacity(barLift)
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
    let sliderBounds: ClosedRange<Double>
    let highlightedRange: ClosedRange<Double>
    let preferredValue: Double
    let tint: Color
    let onChange: (Double) -> Void

    var body: some View {
        GeometryReader { proxy in
            let totalWidth = max(proxy.size.width, 1)
            let knobDiameter: CGFloat = 18
            let knobRadius = knobDiameter * 0.5
            let trackHeight: CGFloat = 8
            let usableWidth = max(totalWidth - knobDiameter, 1)
            let currentX = xPosition(for: value, usableWidth: usableWidth, inset: knobRadius)
            let preferredX = xPosition(for: preferredValue, usableWidth: usableWidth, inset: knobRadius)
            let rangeSegment = segmentPosition(usableWidth: usableWidth, inset: knobRadius)

            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: usableWidth, height: trackHeight)
                    .position(x: totalWidth * 0.5, y: proxy.size.height * 0.5)

                if let rangeSegment {
                    Capsule()
                        .fill(tint.opacity(0.30))
                        .frame(width: rangeSegment.width, height: trackHeight)
                        .position(x: rangeSegment.midX, y: proxy.size.height * 0.5)
                }

                Rectangle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 1, height: 16)
                    .position(x: preferredX, y: proxy.size.height * 0.5)

                Circle()
                    .fill(tint)
                    .frame(width: knobDiameter, height: knobDiameter)
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.48), lineWidth: 2)
                    )
                    .position(x: currentX, y: proxy.size.height * 0.5)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateValue(
                            at: gesture.location.x,
                            totalWidth: totalWidth,
                            usableWidth: usableWidth,
                            inset: knobRadius
                        )
                    }
            )
        }
    }

    private func xPosition(for tempo: Double, usableWidth: CGFloat, inset: CGFloat) -> CGFloat {
        inset + (CGFloat(normalized(tempo)) * usableWidth)
    }

    private func normalized(_ tempo: Double) -> Double {
        let span = sliderBounds.upperBound - sliderBounds.lowerBound
        guard span > 0 else { return 0 }
        let clampedTempo = min(max(tempo, sliderBounds.lowerBound), sliderBounds.upperBound)
        return (clampedTempo - sliderBounds.lowerBound) / span
    }

    private func segmentPosition(usableWidth: CGFloat, inset: CGFloat) -> (midX: CGFloat, width: CGFloat)? {
        let clampedLower = min(max(highlightedRange.lowerBound, sliderBounds.lowerBound), sliderBounds.upperBound)
        let clampedUpper = min(max(highlightedRange.upperBound, sliderBounds.lowerBound), sliderBounds.upperBound)
        guard clampedUpper > clampedLower else { return nil }

        let lowerX = xPosition(for: clampedLower, usableWidth: usableWidth, inset: inset)
        let upperX = xPosition(for: clampedUpper, usableWidth: usableWidth, inset: inset)
        return ((lowerX + upperX) * 0.5, max(upperX - lowerX, 1))
    }

    private func updateValue(at locationX: CGFloat, totalWidth: CGFloat, usableWidth: CGFloat, inset: CGFloat) {
        let clampedX = min(max(locationX, inset), totalWidth - inset)
        let normalizedX = Double((clampedX - inset) / usableWidth)
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
            Color.clear
                .frame(width: CycleGridMetrics.leadingWidth, height: 1)

            HStack(spacing: cycle.sequencerStepSpacing) {
                ForEach(0..<cycle.stepCount, id: \.self) { step in
                    ZStack(alignment: .topTrailing) {
                        Text(cycle.label(for: step))
                            .font(.caption2.weight(cycle.isPulseStart(step) ? .bold : .regular))
                            .monospacedDigit()
                            .foregroundStyle(currentStep == step ? Color.black : Color.secondary)
                            .frame(width: cellWidth, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(currentStep == step ? Color.white.opacity(0.94) : headerFill(for: step))
                            )
                            .overlay(alignment: .topLeading) {
                                if cycle.isBarStart(step) {
                                    Capsule()
                                        .fill(Color.white.opacity(0.58))
                                        .frame(width: max(cellWidth * 0.3, 8), height: 2)
                                        .padding(.leading, 4)
                                        .padding(.top, 4)
                                }
                            }

                        if cycle.isBarBreak(after: step) {
                            Rectangle()
                                .fill(Color.white.opacity(0.28))
                                .frame(width: 2, height: 28)
                        }
                    }
                }
            }
        }
    }

    private var cellWidth: CGFloat {
        cycle.sequencerCellWidth
    }

    private func headerFill(for step: Int) -> Color {
        let barLift = cycle.barIndex(for: step).isMultiple(of: 2) ? 0.0 : 0.03

        if cycle.isBarStart(step) {
            return Color.white.opacity(0.16 + barLift)
        }
        if cycle.isPulseStart(step) {
            return Color.white.opacity(0.10 + barLift)
        }
        return Color.white.opacity(0.04 + barLift)
    }
}

private struct LaneEditorialNoteView: View {
    let text: String
    let cycle: RhythmCycle
    let tint: Color
    let isDimmed: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Capsule()
                .fill(tint.opacity(isDimmed ? 0.42 : 0.68))
                .frame(width: 18, height: 2)
                .padding(.top, 6)

            Text(text)
                .font(.caption2)
                .foregroundStyle(Color.secondary.opacity(isDimmed ? 0.80 : 0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .frame(width: cycle.sequencerRowWidth, alignment: .leading)
    }
}

private struct LaneRowView: View {
    let lane: RhythmLane
    let cycle: RhythmCycle
    let variantSwingAmount: Double
    let currentStep: Int?
    let isMuted: Bool
    let offbeatWeights: [Double]?
    let onToggleLaneMute: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleLaneMute) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(lane.role.tint)
                            .frame(width: 10, height: 10)

                        Text(lane.instrument)
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
                        .fill(isMuted ? Color.white.opacity(0.05) : lane.role.tint.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isMuted ? Color.white.opacity(0.10) : lane.role.tint.opacity(0.24), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: cycle.sequencerStepSpacing) {
                ForEach(0..<cycle.stepCount, id: \.self) { step in
                    let event = lane.event(at: step)
                    let eventOffset = lane.stepOffset(at: step, in: cycle, swingAmount: variantSwingAmount)

                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(cellFill(for: step))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(borderColor(for: step), lineWidth: currentStep == step ? 1.2 : 0)
                            )

                        if let offbeatWeight = offbeatWeight(at: step), offbeatWeight > 0 {
                            Capsule()
                                .fill(Color.yellow.opacity(isMuted ? 0.36 : 0.84))
                                .frame(
                                    width: max(cellWidth * 0.24, 6),
                                    height: max(3, CGFloat(offbeatWeight) * 6)
                                )
                                .padding(.bottom, 4)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        }

                        if let event {
                            Circle()
                                .fill(lane.role.tint.opacity(isMuted ? 0.34 : (event.isAccent ? 0.98 : 0.60)))
                                .frame(width: event.isAccent ? cellWidth * 0.56 : cellWidth * 0.42)
                                .overlay(
                                    Circle()
                                        .stroke(lane.role.tint.opacity(isMuted ? 0.48 : 0.90), lineWidth: 1)
                                )
                                .offset(x: CGFloat(eventOffset) * cycle.sequencerStepStride)
                                .zIndex(1)
                        }
                    }
                    .overlay(alignment: .trailing) {
                        if cycle.isBarBreak(after: step) {
                            Rectangle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 2, height: 34)
                        }
                    }
                    .frame(width: cellWidth, height: 30)
                }
            }
        }
        .opacity(isMuted ? 0.72 : 1)
    }

    private var cellWidth: CGFloat {
        cycle.sequencerCellWidth
    }

    private func cellFill(for step: Int) -> Color {
        if currentStep == step {
            return lane.role.tint.opacity(isMuted ? 0.10 : 0.20)
        }
        if cycle.isBarStart(step) {
            let barLift = cycle.barIndex(for: step).isMultiple(of: 2) ? 0.02 : 0.04
            return Color.white.opacity((isMuted ? 0.06 : 0.11) + barLift)
        }
        if cycle.isPulseStart(step) {
            let barLift = cycle.barIndex(for: step).isMultiple(of: 2) ? 0.0 : 0.02
            return Color.white.opacity((isMuted ? 0.04 : 0.08) + barLift)
        }
        let barLift = cycle.barIndex(for: step).isMultiple(of: 2) ? 0.0 : 0.012
        return Color.white.opacity((isMuted ? 0.015 : 0.035) + barLift)
    }

    private func borderColor(for step: Int) -> Color {
        currentStep == step ? lane.role.tint : .clear
    }

    private func offbeatWeight(at step: Int) -> Double? {
        guard let offbeatWeights, offbeatWeights.indices.contains(step) else { return nil }
        return offbeatWeights[step]
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

private extension RhythmCycle {
    var sequencerCellWidth: CGFloat {
        switch stepCount {
        case 0...16: 28
        case 17...24: 24
        default: 20
        }
    }

    var sequencerGridWidth: CGFloat {
        (CGFloat(stepCount) * sequencerCellWidth) + (CGFloat(max(stepCount - 1, 0)) * sequencerStepSpacing)
    }

    var sequencerRowWidth: CGFloat {
        CycleGridMetrics.leadingWidth + 10 + sequencerGridWidth
    }

    var sequencerStepSpacing: CGFloat {
        4
    }

    var sequencerStepStride: CGFloat {
        sequencerCellWidth + sequencerStepSpacing
    }

    func pulseIndex(for step: Int) -> Int {
        step / stepsPerPulse
    }

    func barIndex(for step: Int) -> Int {
        let pulseIndex = pulseIndex(for: step)
        return barBreakPulseIndices.filter { $0 < pulseIndex }.count
    }

    func isBarStart(_ step: Int) -> Bool {
        guard isPulseStart(step) else { return false }
        let pulseIndex = pulseIndex(for: step)
        return pulseIndex == 0 || barBreakPulseIndices.contains(pulseIndex - 1)
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

private extension SharedLineRole {
    var title: String {
        switch self {
        case .guide: "Guide"
        case .foundation: "Foundation"
        case .frame: "Frame"
        case .counterline: "Answering Line"
        case .timekeeper: "Timekeeper"
        case .lift: "Lift"
        case .timeline: "Timeline"
        case .commentary: "Commentary"
        }
    }

    var tint: Color {
        switch self {
        case .guide: Color.white.opacity(0.88)
        case .foundation: .green
        case .frame: .orange
        case .counterline: .pink
        case .timekeeper: .blue
        case .lift: .mint
        case .timeline: .red
        case .commentary: .yellow
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
