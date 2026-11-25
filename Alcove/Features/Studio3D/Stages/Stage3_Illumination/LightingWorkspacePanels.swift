import SwiftUI

struct LightingSourcePanel: View {
    @Bindable var editor: LightingSetupViewModel
    let isAdding: Bool
    let onAdd: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sourceHeader
            StudioStageButton(title: isAdding ? "Save Lights" : "Add light", role: .add,
                              systemImage: isAdding ? "checkmark" : "plus.circle", fillsWidth: true, action: onAdd)
            if editor.isSelectingMultiple || editor.selectionCount > 0 {
                selectionControls.transition(.opacity)
            }
            ScrollView {
                LazyVStack(spacing: 12) {
                    if editor.drafts.isEmpty {
                        Text(isAdding ? "Tap the room to place a light." : "Tap Add light to get started.")
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 24)
                    }
                    ForEach(editor.drafts) { fixture in
                        sourceButton(fixture)
                    }
                }
                .padding(2)
            }
            .frame(maxHeight: .infinity)
            if editor.hasUnsavedChanges {
                Label("Unsaved changes", systemImage: "circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .animation(.easeInOut(duration: 0.16), value: editor.isSelectingMultiple)
        .animation(.easeInOut(duration: 0.16), value: isAdding)
        .lightingPanel()
    }

    private var sourceHeader: some View {
        HStack(spacing: 8) {
            Label("Your Lights", systemImage: "lightbulb")
                .font(.custom("Cleanow", size: 20, relativeTo: .headline))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button { editor.toggleMultipleSelection() } label: {
                Text(editor.isSelectingMultiple ? "Done" : "Select")
                    .font(.subheadline.bold())
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .disabled(editor.drafts.isEmpty)
            .opacity(editor.drafts.isEmpty ? 0.4 : 1)
            .accessibilityLabel(editor.isSelectingMultiple ? "Finish selecting lights" : "Select multiple lights")
        }
    }

    private var selectionControls: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("\(editor.selectionCount) selected")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                Spacer(minLength: 0)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .disabled(editor.selectionCount == 0)
                .accessibilityLabel(editor.selectionCount > 1 ? "Delete selected lights" : "Delete selected light")
            }
            if editor.isSelectingMultiple {
                HStack(spacing: 5) {
                    Button { editor.selectAll() } label: {
                        Text("Select all").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                    }
                    .disabled(editor.selectionCount == editor.drafts.count)
                    Spacer(minLength: 0)
                    Button { editor.clearSelection() } label: {
                        Text("Clear").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                    }
                    .disabled(editor.selectionCount == 0)
                }
                .font(.caption.bold())
                .buttonStyle(.plain)
            }
        }
    }

    private func sourceButton(_ fixture: LightFixture) -> some View {
        let selected = editor.selectedIDs.contains(fixture.id)
        return Button { editor.select(fixture.id) } label: {
            HStack(spacing: 8) {
                Image(systemName: fixture.resolvedKind.icon)
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 24)
                    .opacity(fixture.isOn ? 1 : 0.5)
                Text(fixture.name)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if editor.isSelectingMultiple {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                } else if selected {
                    Image(systemName: "checkmark")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: 48)
            .background(selected ? Color.alcoveItemSurface : LightingTheme.row,
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(LightingTheme.ink, lineWidth: 2))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.16), value: selected)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint(editor.isSelectingMultiple ? (selected ? "Tap to deselect this light." : "Tap to add this light to your selection.") : "Tap to edit this light.")
    }
}

struct LightingSimulationPanel: View {
    @Binding var settings: LightingSimulationSettings
    let activeFixtureCount: Int
    var titleTopInset: Double = 16

    var body: some View {
        ViewThatFits(in: .vertical) {
            previewContent(compact: false)
            previewContent(compact: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, titleTopInset)
        .lightingPanel()
    }

    private func previewContent(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Label("Lighting Preview", systemImage: "sun.max")
                .font(.custom("Cleanow", size: 20, relativeTo: .headline))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 8)
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: compact ? (titleTopInset > 16 ? 8 : 0) : 16) {
                    lightToggle("Lights", isOn: $settings.artificialLightsOn, compact: compact)
                    lightToggle("Show fixtures", isOn: $settings.showsLightFixtures, compact: compact)
                        .accessibilityHint("Shows or hides the lamp models while keeping their light on.")
                }
                .frame(maxWidth: .infinity)
                lightToggle("Sunlight", isOn: $settings.sunlightOn, compact: compact)
            }
            Spacer(minLength: 8)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("12 AM")
                    Spacer()
                    Text(settings.timeLabel).monospacedDigit()
                    Spacer()
                    Text("12 AM")
                }
                .font(.caption)
                Slider(value: Binding(get: { Double(settings.clampedMinute) },
                                      set: { settings.minuteOfDay = Int($0) }), in: 0...1439, step: 1)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .tint(Color("AlcoveLightingToggle"))
                    .accessibilityLabel("Time of day")
                    .accessibilityValue(settings.timeLabel)
            }
            .disabled(!settings.sunlightOn)
            let sunlightActive = settings.sunlightOn &&
                IlluminationSimulationEngine().calculateDaylight(hourOfDay: settings.hourOfDay).intensityLux > 0
            if let limit = StudioLightBudget.maximumFixtures(sunlightActive: sunlightActive), activeFixtureCount > limit {
                Text("Showing the \(limit) brightest lights on this device.")
                    .font(.caption)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.bottom, compact ? (titleTopInset > 16 ? 16 : 0) : 24)
    }
    private func lightToggle(_ title: String, isOn: Binding<Bool>, compact: Bool) -> some View {
        VStack(spacing: compact ? 0 : 4) {
            Text(title).font(.subheadline.bold())
            Toggle(title, isOn: isOn)
                .labelsHidden()
                .tint(Color("AlcoveLightingToggle"))
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
    }

}

struct LightingEditPanel: View {
    @Binding var typePickerPresented: Bool
    @Bindable var editor: LightingSetupViewModel
    var titleTopInset: Double = 16

    var body: some View {
        ViewThatFits(in: .vertical) {
            settingsContent(compact: false, inlineValues: false)
            settingsContent(compact: true, inlineValues: false)
            settingsContent(compact: true, inlineValues: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, titleTopInset)
        .lightingPanel()
    }

    private func settingsContent(compact: Bool, inlineValues: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Label("Light Settings", systemImage: "lamp.desk.fill")
                    .font(.custom("Cleanow", size: 20, relativeTo: .headline))
                Spacer(minLength: 0)
                if editor.selectionCount > 1 {
                    Text("\(editor.selectionCount)")
                        .font(.caption.bold())
                        .accessibilityLabel("Editing \(editor.selectionCount) lights together")
                }
            }
            lampTypePicker
                .padding(.top, 4)
            if !inlineValues, editor.selected != nil {
                Text("Changes apply to all selected lights")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(Color.alcoveMutedInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .opacity(editor.selectionCount > 1 ? 1 : 0)
                    .accessibilityHidden(editor.selectionCount <= 1)
            }
            if let fixture = editor.selected {
                fixtureControls(fixture, compact: compact, inlineValues: inlineValues)
                    .padding(.top, compact ? 8 : 16)
                    .transition(.opacity)
            } else {
                Text(editor.isSelectingMultiple ? "Select lights from the list or the room to edit them together." : "Choose a lamp type, then tap the room to place it.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.bottom, compact ? 8 : 24)
    }

    private var lampTypePicker: some View {
        let current = editor.selected == nil ? editor.placementKind : editor.commonKind
        return Button { typePickerPresented.toggle() } label: {
            HStack(spacing: 8) {
                if let current { Image(systemName: current.icon).frame(width: 24) }
                Text(current?.title ?? "Mixed types")
                Image(systemName: "chevron.up.chevron.down").font(.caption.bold())
                Spacer(minLength: 0)
            }
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(LightingTheme.ink)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(LightingTheme.row, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(LightingTheme.ink, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Lamp type")
        .disabled(editor.isSelectingMultiple && editor.selected == nil)
        .anchorPreference(key: LightingLampTypeAnchorKey.self, value: .bounds) { $0 }
    }

    private func fixtureControls(_ fixture: LightFixture, compact: Bool, inlineValues: Bool) -> some View {
        let selected = editor.selectedFixtures
        let temperatures = selected.map(\.colorTemperatureKelvin)
        let lowerTemperature = temperatures.min() ?? fixture.colorTemperatureKelvin
        let upperTemperature = temperatures.max() ?? fixture.colorTemperatureKelvin
        let brightnesses = selected.map { Int($0.lumens) }
        let lowerBrightness = brightnesses.min() ?? Int(fixture.lumens)
        let upperBrightness = brightnesses.max() ?? Int(fixture.lumens)
        let colorValue = lowerTemperature == upperTemperature
            ? "\(lowerTemperature) K" : "\(lowerTemperature)–\(upperTemperature) K"
        let brightnessValue = lowerBrightness == upperBrightness
            ? "\(lowerBrightness) lm" : "\(lowerBrightness)–\(upperBrightness) lm"
        return VStack(alignment: .leading, spacing: 24) {
            sliderSection("Color Temperature", value: colorValue, lower: "2200 K", upper: "6500 K",
                          compact: compact, inlineValues: inlineValues) {
                LightingGradientSlider(value: Binding(
                    get: { Double(editor.selected?.colorTemperatureKelvin ?? fixture.colorTemperatureKelvin) },
                    set: { value in editor.updateSelected { $0.colorTemperatureKelvin = Int(value) } }
                ), range: 2200...6500, step: 100, colors: [.orange, .yellow, LightingTheme.row, .cyan],
                                       label: "Color Temperature", formattedValue: editor.commonTemperature.map { "\($0) Kelvin" } ?? "Mixed values")
            }
            sliderSection("Brightness", value: brightnessValue, lower: "0 lm", upper: "3000 lm",
                          compact: compact, inlineValues: inlineValues) {
                LightingGradientSlider(value: Binding(
                    get: { editor.selected?.lumens ?? fixture.lumens },
                    set: { value in editor.updateSelected { $0.lumens = value; $0.isOn = value > 0 } }
                ), range: 0...3000, step: 50,
                                       colors: [Color(uiColor: .darkGray), Color(uiColor: .systemGray6)],
                                       label: "Brightness", formattedValue: editor.commonBrightness.map { "\(Int($0)) lumens" } ?? "Mixed values")
            }
        }.padding(.top, 10)
    }

    private func sliderSection<Control: View>(
        _ title: String, value: String, lower: String, upper: String,
        compact: Bool, inlineValues: Bool, @ViewBuilder control: () -> Control
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(compact ? .caption.bold() : .subheadline.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 4)
                if inlineValues {
                    Text(value)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(LightingTheme.ink)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            if !inlineValues {
                Text(value)
                    .font(compact ? .caption2 : .subheadline)
                    .monospacedDigit()
                    .foregroundStyle(LightingTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.top, compact ? 0 : 8)
            }
            control()
            HStack {
                Text(lower)
                Spacer()
                Text(upper)
            }
            .font(compact ? .caption2 : .caption)
            .foregroundStyle(LightingTheme.ink)
        }
    }

}

/// Rendered by the workspace above every panel, without native popover chrome.
struct LightingLampTypeAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

struct LightingLampTypeMenu: View {
    let current: LightKind?
    let onSelect: (LightKind) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(LightKind.lightingKinds) { kind in
                Button { onSelect(kind) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark").frame(width: 18)
                            .opacity(current == kind ? 1 : 0)
                        Image(systemName: kind.icon).frame(width: 24)
                        Text(kind.title)
                        Spacer(minLength: 0)
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(LightingTheme.ink)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(current == kind ? .isSelected : [])
            }
        }
        .padding(.vertical, 12)
        .frame(width: 270)
        .background(LightingTheme.row, in: RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).strokeBorder(LightingTheme.ink, lineWidth: 3))
    }
}
