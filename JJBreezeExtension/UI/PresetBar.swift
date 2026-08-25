import AudioToolbox
import SwiftUI

struct PresetBar: View {
    let audioUnit: JJBreezeAudioUnit?

    @State private var title = "Default"
    @State private var userPresets: [AUAudioUnitPreset] = []
    @State private var showSave = false
    @State private var showManage = false
    @State private var saveName = ""
    @State private var errorMessage: String?

    var body: some View {
        HStack(spacing: 6) {
            stepButton(systemName: "chevron.left") {
                audioUnit?.stepPreset(by: -1)
            }

            Menu {
                Section("Factory") {
                    ForEach(FactoryPresets.all, id: \.number) { preset in
                        Button(preset.name) {
                            selectFactory(preset.number)
                        }
                    }
                }
                Section("User") {
                    if userPresets.isEmpty {
                        Text("No user presets")
                    } else {
                        ForEach(userPresets, id: \.number) { preset in
                            Button(preset.name) {
                                select(preset)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    DirtyDot(audioUnit: audioUnit)
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(GearTheme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(GearTheme.panelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GearTheme.metalDark, lineWidth: 1)
                )
            }
            .id("user-presets-\(userPresets.count)-\(title)")

            stepButton(systemName: "chevron.right") {
                audioUnit?.stepPreset(by: 1)
            }

            presetButton("SAVE") {
                saveName = suggestedSaveName
                showSave = true
            }
            presetButton("MANAGE") {
                reload()
                showManage = true
            }
        }
        .onAppear(perform: reload)
        .onReceive(NotificationCenter.default.publisher(for: .jjBreezePresetChanged)) { _ in
            reload()
        }
        .sheet(isPresented: $showSave) {
            PresetNameSheet(
                title: "Save Preset",
                caption: "Saves the current knobs. A preset with the same name is replaced.",
                name: $saveName,
                confirmTitle: "Save",
                onCancel: { showSave = false },
                onConfirm: { save() }
            )
        }
        .alert("Preset", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showManage) {
            PresetManagerSheet(
                userPresets: userPresets,
                onLoad: { preset in
                    select(preset)
                    showManage = false
                },
                onRename: { preset, name in
                    rename(preset, to: name)
                },
                onDelete: { preset in
                    delete(preset)
                }
            )
            .presentationDetents([.medium, .large])
        }
    }

    private var suggestedSaveName: String {
        if let current = audioUnit?.currentPreset, current.number < 0 {
            return current.name
        }
        return ""
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(GearTheme.textLight)
                .frame(width: 44, height: 44)
                .background(GearTheme.panelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GearTheme.metalDark, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(audioUnit == nil)
        .accessibilityLabel(systemName.contains("left") ? "Previous preset" : "Next preset")
    }

    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(GearTheme.textLight)
                .padding(.horizontal, 10)
                .frame(minHeight: 44)
                .background(GearTheme.panelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GearTheme.metalDark, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(audioUnit == nil)
    }

    private func reload() {
        userPresets = (audioUnit?.userPresets ?? []).sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        title = audioUnit?.currentPreset?.name ?? "Default"
    }

    private func selectFactory(_ number: Int) {
        audioUnit?.currentPreset = audioUnit?.factoryPresets?.first { $0.number == number }
        reload()
    }

    private func select(_ preset: AUAudioUnitPreset) {
        audioUnit?.currentPreset = preset
        reload()
    }

    private func save() {
        guard let audioUnit else {
            errorMessage = "Effect is not loaded."
            return
        }
        do {
            try audioUnit.saveCurrentStateAsUserPreset(name: saveName)
            showSave = false
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func rename(_ preset: AUAudioUnitPreset, to name: String) {
        do {
            try audioUnit?.renameUserPreset(preset, to: name)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ preset: AUAudioUnitPreset) {
        do {
            try audioUnit?.removeUserPreset(preset)
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PresetNameSheet: View {
    let title: String
    let caption: String
    @Binding var name: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(caption)
                    .font(.system(size: 13))
                    .foregroundStyle(GearTheme.textMuted)
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)
                    .padding(10)
                    .background(GearTheme.panelFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(GearTheme.metalDark, lineWidth: 1)
                    )
                    .foregroundStyle(GearTheme.textLight)
                Spacer()
            }
            .padding(16)
            .background(GearTheme.chassisBottom)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(GearTheme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmTitle, action: onConfirm)
                        .foregroundStyle(GearTheme.accent)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(220), .medium])
        .tint(GearTheme.accent)
    }
}

private struct PresetManagerSheet: View {
    let userPresets: [AUAudioUnitPreset]
    let onLoad: (AUAudioUnitPreset) -> Void
    let onRename: (AUAudioUnitPreset, String) -> Void
    let onDelete: (AUAudioUnitPreset) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var renameTarget: AUAudioUnitPreset?
    @State private var renameText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if userPresets.isEmpty {
                        Text("No user presets yet. Turn the knobs, then tap SAVE.")
                            .font(.system(size: 13))
                            .foregroundStyle(GearTheme.textMuted)
                    } else {
                        ForEach(userPresets, id: \.number) { preset in
                            Button {
                                onLoad(preset)
                            } label: {
                                Text(preset.name)
                                    .foregroundStyle(GearTheme.textLight)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", role: .destructive) {
                                    onDelete(preset)
                                }
                                Button("Rename") {
                                    renameTarget = preset
                                    renameText = preset.name
                                }
                                .tint(GearTheme.accent)
                            }
                        }
                    }
                } header: {
                    Text("User presets")
                } footer: {
                    Text("Factory presets stay in the menu and cannot be changed. User presets are stored on this device. The standalone player and GarageBand each keep their own list until an App Group is enabled for both targets.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(GearTheme.chassisBottom)
            .navigationTitle("Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(GearTheme.accent)
                }
            }
            .sheet(isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )) {
                PresetNameSheet(
                    title: "Rename Preset",
                    caption: "The new name replaces this user preset.",
                    name: $renameText,
                    confirmTitle: "Rename",
                    onCancel: { renameTarget = nil },
                    onConfirm: {
                        if let preset = renameTarget {
                            onRename(preset, renameText)
                        }
                        renameTarget = nil
                    }
                )
            }
        }
        .tint(GearTheme.accent)
    }
}

private struct DirtyDot: View {
    let audioUnit: JJBreezeAudioUnit?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { _ in
            Circle()
                .fill((audioUnit?.isPresetDirty() ?? false) ? GearTheme.accent : Color.clear)
                .frame(width: 7, height: 7)
        }
    }
}
