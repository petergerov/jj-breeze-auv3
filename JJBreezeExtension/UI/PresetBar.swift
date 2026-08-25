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
        HStack(spacing: 8) {
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
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(GearTheme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GearTheme.panelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GearTheme.metalDark, lineWidth: 1)
                )
            }
            .id("user-presets-\(userPresets.count)-\(title)")

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
        .sheet(isPresented: $showSave) {
            saveSheet
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

    private var saveSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Saves the current knobs. A preset with the same name is replaced.")
                    .font(.system(size: 13))
                    .foregroundStyle(GearTheme.textMuted)
                TextField("Name", text: $saveName)
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
            .navigationTitle("Save Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSave = false }
                        .foregroundStyle(GearTheme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(GearTheme.accent)
                        .disabled(saveName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(220), .medium])
        .tint(GearTheme.accent)
    }

    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(GearTheme.textLight)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
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
        audioUnit?.currentPreset = audioUnit?.factoryPresets?[number]
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
                    Text("Factory presets stay in the menu and cannot be changed. User presets are stored on this device and available in GarageBand, Logic, and this app.")
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
            .alert("Rename Preset", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )) {
                TextField("Name", text: $renameText)
                Button("Rename") {
                    if let preset = renameTarget {
                        onRename(preset, renameText)
                    }
                    renameTarget = nil
                }
                Button("Cancel", role: .cancel) { renameTarget = nil }
            }
        }
        .tint(GearTheme.accent)
    }
}
