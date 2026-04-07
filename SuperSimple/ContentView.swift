import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RhythmExplorerViewModel()

    var body: some View {
        GeometryReader { proxy in
            let compactLayout = proxy.size.width < 860

            ZStack {
                AppBackground()

                if compactLayout {
                    ScrollView {
                        VStack(spacing: 16) {
                            browserSection
                            lensSection
                            cycleSection
                        }
                        .padding(16)
                    }
                } else {
                    VStack(spacing: 16) {
                        browserSection
                            .frame(height: proxy.size.height * 0.27)

                        lensSection
                            .frame(height: proxy.size.height * 0.24)

                        cycleSection
                            .frame(maxHeight: .infinity)
                    }
                    .padding(16)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var browserSection: some View {
        ExplorerCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Rhythm Explorer")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .tracking(-0.5)

                        Text("Atlas-first rhythm browsing with a cycle-aware grid.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Label("Auto-play", systemImage: "speaker.wave.2.fill")
                        Label("Tap hits to mute", systemImage: "hand.tap.fill")
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(RhythmRegion.allCases) { region in
                            FilterChip(
                                title: region.title,
                                subtitle: region.subtitle,
                                isSelected: viewModel.selectedRegion == region,
                                tint: region.tint
                            ) {
                                viewModel.selectRegion(region)
                            }
                        }
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
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
        }
    }

    private var lensSection: some View {
        ExplorerCard {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 18) {
                    lensTextColumn
                    Divider()
                        .overlay(Color.white.opacity(0.08))
                    controlsColumn
                }

                VStack(alignment: .leading, spacing: 18) {
                    lensTextColumn
                    controlsColumn
                }
            }
        }
    }

    private var lensTextColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.selectedRhythm.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    HStack(spacing: 8) {
                        Label(viewModel.selectedRhythm.tradition, systemImage: "globe.europe.africa.fill")
                        Text(viewModel.selectedRhythm.family)
                        Text(viewModel.selectedRhythm.cycle.meter)
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                TierBadge(tier: viewModel.selectedRhythm.tier)
            }

            Text(viewModel.selectedRhythm.summary)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.92))

            Text(viewModel.selectedRhythm.hearingCue)
                .font(.headline.weight(.medium))
                .foregroundStyle(viewModel.selectedRhythm.region.tint.opacity(0.95))

            HStack(spacing: 10) {
                MetricPill(title: "Pulse", value: viewModel.selectedRhythm.cycle.pulseUnitName)
                MetricPill(title: "Grid", value: viewModel.selectedRhythm.cycle.stepUnitName)
                MetricPill(title: "Feel", value: viewModel.selectedRhythm.cycle.nativeFeel)
                MetricPill(title: "Swing", value: "\(Int((viewModel.selectedVariant.swingAmount * 100).rounded()))%")
            }

            AdaptiveFlow(minimum: 110, spacing: 8) {
                ForEach(viewModel.selectedRhythm.identityMarkers, id: \.self) { keyword in
                    Text(keyword)
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.06))
                        )
                }
            }

            if let mishearRisk = viewModel.selectedRhythm.mishearRisk {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Common Mishear")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(mishearRisk)
                        .font(.footnote)
                        .foregroundStyle(.primary.opacity(0.88))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Lane Roles")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                AdaptiveFlow(minimum: 150, spacing: 8) {
                    ForEach(viewModel.selectedVariant.lanes) { lane in
                        Label(lane.label, systemImage: "circle.fill")
                            .font(.footnote)
                            .foregroundStyle(lane.role.tint)
                    }
                }
            }

            if !viewModel.nearbyRhythms.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nearby")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    AdaptiveFlow(minimum: 150, spacing: 8) {
                        ForEach(viewModel.nearbyRhythms) { rhythm in
                            Button {
                                viewModel.selectRhythm(rhythm)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(rhythm.name)
                                        .font(.footnote.weight(.bold))
                                    Text(rhythm.family)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.white.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var controlsColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Button(action: viewModel.togglePlayback) {
                    Label(
                        viewModel.isPlaying ? "Pause" : "Play",
                        systemImage: viewModel.isPlaying ? "pause.fill" : "play.fill"
                    )
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryTransportStyle(tint: viewModel.selectedRhythm.region.tint))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tempo")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(Int(viewModel.bpm.rounded())) BPM")
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                }

                Button("Reset Mutes") {
                    viewModel.resetMutes()
                }
                .buttonStyle(SecondaryPillStyle())
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Native Tempo Range")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(viewModel.selectedRhythm.tempoRange.lowerBound))-\(Int(viewModel.selectedRhythm.tempoRange.upperBound)) BPM")
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Listening Focus")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                AdaptiveFlow(minimum: 130, spacing: 8) {
                    ForEach(ListeningMode.allCases) { mode in
                        Button {
                            viewModel.setListeningMode(mode)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.title)
                                    .font(.footnote.weight(.bold))
                                Text(mode.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(10)
                            .frame(width: 140, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(viewModel.listeningMode == mode ? viewModel.selectedRhythm.region.tint.opacity(0.18) : Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(viewModel.listeningMode == mode ? viewModel.selectedRhythm.region.tint : Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    Button("Audition Pulse") {
                        viewModel.clearSolo()
                        viewModel.setListeningMode(.pulseOnly)
                    }
                    .buttonStyle(SecondaryPillStyle())

                    Button("Hear Skeleton") {
                        viewModel.clearSolo()
                        viewModel.setListeningMode(.skeleton)
                    }
                    .buttonStyle(SecondaryPillStyle())

                    if viewModel.soloLaneID != nil {
                        Button("Clear Solo") {
                            viewModel.clearSolo()
                        }
                        .buttonStyle(SecondaryPillStyle())
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Variants")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                AdaptiveFlow(minimum: 190, spacing: 8) {
                    ForEach(viewModel.selectedRhythm.variants) { variant in
                        Button {
                            viewModel.selectVariant(variant)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(variant.name)
                                    .font(.footnote.weight(.bold))
                                Text(variant.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(10)
                            .frame(width: 190, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(variant.id == viewModel.selectedVariant.id ? viewModel.selectedRhythm.region.tint.opacity(0.18) : Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(variant.id == viewModel.selectedVariant.id ? viewModel.selectedRhythm.region.tint : Color.white.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cycleSection: some View {
        ExplorerCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Cycle Grid")
                            .font(.title3.weight(.bold))
                        Text(viewModel.selectedVariant.hearingFocus)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text("\(viewModel.selectedRhythm.cycle.stepCount) steps")
                            .font(.headline)
                            .monospacedDigit()
                        Text(viewModel.soloLaneID == nil ? "Mute hits or solo lanes to isolate structure" : "Solo is active")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        StructureOverlayView(
                            variant: viewModel.selectedVariant,
                            cycle: viewModel.selectedRhythm.cycle,
                            currentStep: viewModel.currentStep,
                            listeningMode: viewModel.listeningMode
                        )

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
                                isSoloed: viewModel.isLaneSoloed(lane.id),
                                isEmphasized: viewModel.shouldEmphasizeLane(lane),
                                isHitMuted: { step in
                                    viewModel.isHitMuted(laneID: lane.id, step: step)
                                },
                                onToggleLaneMute: {
                                    viewModel.toggleLaneMute(lane.id)
                                },
                                onToggleLaneSolo: {
                                    viewModel.toggleLaneSolo(lane.id)
                                },
                                onToggleHitMute: { step in
                                    viewModel.toggleHitMute(laneID: lane.id, step: step)
                                }
                            )
                        }
                    }
                    .padding(.bottom, 4)
                }

                AdaptiveFlow(minimum: 220, spacing: 8) {
                    ForEach(viewModel.selectedRhythm.teachingOverlays, id: \.self) { overlay in
                        Label(overlay, systemImage: "waveform.path.ecg")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.05))
                            )
                    }
                }
            }
        }
    }
}

private struct ExplorerCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            )
    }
}

private struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.05, blue: 0.08),
                Color(red: 0.02, green: 0.03, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            ZStack {
                Circle()
                    .fill(Color(red: 0.09, green: 0.24, blue: 0.24).opacity(0.38))
                    .frame(width: 520)
                    .blur(radius: 110)
                    .offset(x: -180, y: -220)

                Circle()
                    .fill(Color(red: 0.65, green: 0.39, blue: 0.14).opacity(0.18))
                    .frame(width: 440)
                    .blur(radius: 120)
                    .offset(x: 210, y: 240)
            }
        )
        .ignoresSafeArea()
    }
}

private struct FilterChip: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.footnote.weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(width: 170, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.18) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? tint : Color.white.opacity(0.07), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct RhythmBrowserCard: View {
    let rhythm: RhythmDefinition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(rhythm.name)
                        .font(.headline.weight(.bold))
                    Spacer()
                    TierBadge(tier: rhythm.tier)
                }

                Text(rhythm.tradition)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(rhythm.region.tint)

                Text(rhythm.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                Spacer()

                HStack {
                    Label(rhythm.cycle.meter, systemImage: "metronome")
                    Spacer()
                    Text("\(Int(rhythm.defaultTempo)) BPM")
                }
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(width: 230, height: 150, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? rhythm.region.tint.opacity(0.18) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? rhythm.region.tint : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
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
                    .fill(tier.tint.opacity(0.2))
            )
            .foregroundStyle(tier.tint)
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.weight(.bold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
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
                    .fill(Color.white.opacity(0.06))

                Capsule()
                    .fill(tint.opacity(0.22))
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

    private let labelWidth: CGFloat = 136

    var body: some View {
        HStack(spacing: 8) {
            Text("Count")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: labelWidth, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(0..<cycle.stepCount, id: \.self) { step in
                    ZStack(alignment: .trailing) {
                        Text(cycle.label(for: step))
                            .font(.caption2.weight(cycle.isPulseStart(step) ? .bold : .regular))
                            .monospacedDigit()
                            .foregroundStyle(currentStep == step ? Color.black : Color.secondary)
                            .frame(width: cellWidth, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(currentStep == step ? Color.white.opacity(0.92) : headerFill(for: step))
                            )

                        if cycle.isBarBreak(after: step) {
                            Rectangle()
                                .fill(Color.white.opacity(0.25))
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

private struct StructureOverlayView: View {
    let variant: RhythmVariant
    let cycle: RhythmCycle
    let currentStep: Int?
    let listeningMode: ListeningMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Structure")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            StructureLaneRow(
                title: "Pulse Rail",
                subtitle: cycle.pulseUnitName,
                cycle: cycle,
                currentStep: currentStep,
                tint: LaneRole.pulse.tint,
                weights: (0..<cycle.stepCount).map { cycle.isPulseStart($0) ? 1.0 : 0.0 }
            )

            StructureLaneRow(
                title: "Offbeats",
                subtitle: "Subdivision lift",
                cycle: cycle,
                currentStep: currentStep,
                tint: Color(red: 0.95, green: 0.73, blue: 0.30),
                weights: (0..<cycle.stepCount).map(offbeatWeight)
            )

            StructureLaneRow(
                title: "Anchors",
                subtitle: listeningMode == .fullMix ? "Low / hand / timeline" : listeningMode.subtitle,
                cycle: cycle,
                currentStep: currentStep,
                tint: listeningMode == .pulseOnly ? LaneRole.pulse.tint : Color(red: 0.46, green: 0.81, blue: 0.71),
                weights: anchorWeights
            )

            StructureLaneRow(
                title: "Accents",
                subtitle: "Where the shape peaks",
                cycle: cycle,
                currentStep: currentStep,
                tint: Color(red: 0.98, green: 0.56, blue: 0.38),
                weights: accentWeights
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.035))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private var anchorWeights: [Double] {
        let anchorRoles = listeningMode == .pulseOnly
            ? Set([LaneRole.pulse])
            : Set([LaneRole.pulse, .lowDrum, .backbeatHand, .timeline])

        let weights = (0..<cycle.stepCount).map { step in
            variant.lanes
                .filter { anchorRoles.contains($0.role) }
                .compactMap { $0.event(at: step)?.intensity }
                .reduce(0, +)
        }

        return normalize(weights)
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

    private func offbeatWeight(for step: Int) -> Double {
        guard !cycle.isPulseStart(step) else { return 0 }
        let label = cycle.label(for: step)
        if label == "&" {
            return 1
        }
        return 0.58
    }

    private func normalize(_ values: [Double]) -> [Double] {
        guard let maxValue = values.max(), maxValue > 0 else { return values }
        return values.map { $0 / maxValue }
    }
}

private struct StructureLaneRow: View {
    let title: String
    let subtitle: String
    let cycle: RhythmCycle
    let currentStep: Int?
    let tint: Color
    let weights: [Double]

    private let labelWidth: CGFloat = 136

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.footnote.weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: labelWidth, alignment: .leading)

            HStack(spacing: 4) {
                ForEach(Array(weights.indices), id: \.self) { step in
                    let weight = weights[step]
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(backgroundFill(for: step))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(currentStep == step ? tint.opacity(0.8) : Color.white.opacity(0.05), lineWidth: currentStep == step ? 1.4 : 1)
                            )

                        if weight > 0 {
                            Capsule()
                                .fill(tint.opacity(0.9))
                                .frame(width: max(cellWidth * 0.24, 6), height: max(6, CGFloat(weight) * 22))
                                .padding(.bottom, 4)
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

private struct LaneRowView: View {
    let lane: RhythmLane
    let cycle: RhythmCycle
    let currentStep: Int?
    let isMuted: Bool
    let isSoloed: Bool
    let isEmphasized: Bool
    let isHitMuted: (Int) -> Bool
    let onToggleLaneMute: () -> Void
    let onToggleLaneSolo: () -> Void
    let onToggleHitMute: (Int) -> Void

    private let labelWidth: CGFloat = 136

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(lane.role.tint)
                            .frame(width: 10, height: 10)
                        Text(lane.label)
                            .font(.footnote.weight(.bold))
                    }

                    Text(lane.role.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(isMuted ? .secondary : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(width: labelWidth, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isMuted ? Color.white.opacity(0.03) : lane.role.tint.opacity(isEmphasized ? 0.12 : 0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isMuted ? Color.white.opacity(0.06) : lane.role.tint.opacity(isEmphasized ? 0.35 : 0.16), lineWidth: 1)
                        )
                )
                .frame(width: labelWidth, alignment: .leading)

                HStack(spacing: 6) {
                    Button(isMuted ? "Unmute" : "Mute", action: onToggleLaneMute)
                        .buttonStyle(MiniLaneButtonStyle(isActive: !isMuted, tint: lane.role.tint))

                    Button(isSoloed ? "Soloed" : "Solo", action: onToggleLaneSolo)
                        .buttonStyle(MiniLaneButtonStyle(isActive: isSoloed, tint: lane.role.tint))
                }
            }
            .opacity(isEmphasized ? 1 : 0.62)

            HStack(spacing: 4) {
                ForEach(0..<cycle.stepCount, id: \.self) { step in
                    let event = lane.event(at: step)
                    let hitMuted = event != nil && isHitMuted(step)
                    Button {
                        guard event != nil else { return }
                        onToggleHitMute(step)
                    } label: {
                        ZStack(alignment: .trailing) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(cellFill(for: step))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(borderColor(for: step), lineWidth: currentStep == step ? 1.5 : 1)
                                )

                            if let event {
                                Circle()
                                    .fill(lane.role.tint.opacity(hitMuted || isMuted ? 0.18 : (event.isAccent ? (isEmphasized ? 0.98 : 0.54) : (isEmphasized ? 0.72 : 0.36))))
                                    .frame(width: event.isAccent ? cellWidth * 0.55 : cellWidth * 0.42)
                                    .overlay(
                                        Circle()
                                            .stroke(lane.role.tint.opacity(hitMuted || isMuted ? 0.35 : (isEmphasized ? 1 : 0.45)), lineWidth: 1)
                                    )

                                if hitMuted {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.9))
                                    }
                            }

                            if cycle.isBarBreak(after: step) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.20))
                                    .frame(width: 2, height: 30)
                            }
                        }
                        .frame(width: cellWidth, height: 30)
                    }
                    .buttonStyle(.plain)
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

    private func cellFill(for step: Int) -> Color {
        if currentStep == step {
            return lane.role.tint.opacity(isEmphasized ? 0.22 : 0.12)
        }
        if cycle.isPulseStart(step) {
            return Color.white.opacity(isEmphasized ? 0.08 : 0.05)
        }
        return Color.white.opacity(isEmphasized ? 0.035 : 0.02)
    }

    private func borderColor(for step: Int) -> Color {
        currentStep == step ? lane.role.tint : Color.white.opacity(0.05)
    }
}

private struct MiniLaneButtonStyle: ButtonStyle {
    let isActive: Bool
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(minWidth: 56)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? tint.opacity(configuration.isPressed ? 0.18 : 0.24) : Color.white.opacity(configuration.isPressed ? 0.08 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isActive ? tint.opacity(0.9) : Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .foregroundStyle(isActive ? tint : Color.primary)
    }
}

private struct PrimaryTransportStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.72 : 0.92))
            )
            .foregroundStyle(Color.black.opacity(0.92))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct SecondaryPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.11 : 0.05))
            )
            .foregroundStyle(.primary)
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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum, maximum: .infinity), spacing: spacing, alignment: .leading)], alignment: .leading, spacing: spacing) {
            content
        }
    }
}

private extension RhythmRegion {
    var tint: Color {
        switch self {
        case .all: Color(red: 0.65, green: 0.68, blue: 0.74)
        case .globalElectronic: Color(red: 0.30, green: 0.88, blue: 0.80)
        case .uk: Color(red: 0.92, green: 0.70, blue: 0.22)
        case .caribbeanLatin: Color(red: 0.96, green: 0.48, blue: 0.24)
        case .brazil: Color(red: 0.38, green: 0.82, blue: 0.44)
        case .afroCuban: Color(red: 0.92, green: 0.38, blue: 0.34)
        case .northAmerica: Color(red: 0.48, green: 0.70, blue: 0.98)
        case .jazzTradition: Color(red: 0.88, green: 0.50, blue: 0.70)
        case .world: Color(red: 0.62, green: 0.56, blue: 0.94)
        }
    }
}

private extension LaneRole {
    var tint: Color {
        switch self {
        case .pulse: Color(red: 0.90, green: 0.90, blue: 0.92)
        case .lowDrum: Color(red: 0.32, green: 0.80, blue: 0.66)
        case .backbeatHand: Color(red: 0.99, green: 0.58, blue: 0.34)
        case .closedHigh: Color(red: 0.58, green: 0.74, blue: 0.99)
        case .openHigh: Color(red: 0.80, green: 0.92, blue: 0.44)
        case .timeline: Color(red: 0.98, green: 0.52, blue: 0.52)
        case .texture: Color(red: 0.88, green: 0.74, blue: 0.42)
        case .aux1: Color(red: 0.76, green: 0.56, blue: 0.98)
        case .aux2: Color(red: 0.52, green: 0.86, blue: 0.90)
        }
    }
}

private extension RhythmTier {
    var tint: Color {
        switch self {
        case .deep: Color(red: 0.39, green: 0.88, blue: 0.62)
        case .solid: Color(red: 0.95, green: 0.73, blue: 0.28)
        case .stub: Color(red: 0.64, green: 0.68, blue: 0.80)
        }
    }
}

#Preview {
    ContentView()
}
