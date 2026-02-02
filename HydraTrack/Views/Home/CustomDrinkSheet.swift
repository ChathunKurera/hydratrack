//
//  CustomDrinkSheet.swift
//  HydraTrack
//

import SwiftUI

struct CustomDrinkSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Int, DrinkType) -> Void

    @State private var volumeMl: String = ""
    @State private var selectedDrinkType: DrinkType = .water

    private var effectiveHydration: Int {
        let volume = Int(volumeMl) ?? 0
        return Int(Double(volume) * selectedDrinkType.hydrationFactor)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Volume") {
                    TextField("Amount (mL)", text: $volumeMl)
                        .keyboardType(.numberPad)
                }

                Section("Drink Type") {
                    ForEach(DrinkType.allCases, id: \.self) { type in
                        Button(action: {
                            selectedDrinkType = type
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(selectedDrinkType == type ? .primaryBlue : .gray)
                                    .frame(width: 30)

                                Text(type.rawValue)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedDrinkType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.primaryBlue)
                                }
                            }
                        }
                    }
                }

                if let volume = Int(volumeMl), volume > 0 {
                    Section {
                        HStack {
                            Text("Effective Hydration")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(volume) mL × \(Int(selectedDrinkType.hydrationFactor * 100))% = \(effectiveHydration) mL")
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .navigationTitle("Add Custom Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if let volume = Int(volumeMl), volume > 0 {
                            onAdd(volume, selectedDrinkType)
                            dismiss()
                        }
                    }
                    .disabled(volumeMl.isEmpty || Int(volumeMl) == nil || Int(volumeMl)! <= 0)
                }
            }
        }
    }
}
