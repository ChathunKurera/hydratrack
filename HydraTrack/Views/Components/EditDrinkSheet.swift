//
//  EditDrinkSheet.swift
//  HydraTrack
//

import SwiftUI

struct EditDrinkSheet: View {
    let drink: DrinkEntry
    let onSave: (Int, Date) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var volumeText: String = ""
    @State private var selectedTime: Date = Date()

    var body: some View {
        NavigationView {
            Form {
                Section("Drink Info") {
                    HStack {
                        Image(systemName: drink.drinkType.icon)
                            .foregroundColor(.primaryBlue)
                            .frame(width: 30)

                        Text(drink.name)
                            .font(.headline)
                    }
                }

                Section("Volume") {
                    HStack {
                        TextField("Volume (mL)", text: $volumeText)
                            .keyboardType(.numberPad)

                        Text("mL")
                            .foregroundColor(.secondary)
                    }

                    if let volume = Int(volumeText), volume > 0 {
                        let effectiveHydration = Int(Double(volume) * drink.drinkType.hydrationFactor)
                        HStack {
                            Text("Effective Hydration")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(effectiveHydration) mL")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    }
                }

                Section("Time") {
                    DatePicker(
                        "Time Logged",
                        selection: $selectedTime,
                        in: ...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
            .navigationTitle("Edit Drink")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let volume = Int(volumeText), volume > 0 {
                            onSave(volume, selectedTime)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(Int(volumeText) == nil || Int(volumeText)! <= 0)
                }
            }
            .onAppear {
                volumeText = "\(drink.volumeMl)"
                selectedTime = drink.timestamp
            }
        }
    }
}

#Preview {
    EditDrinkSheet(
        drink: DrinkEntry(volumeMl: 250, drinkType: .water, name: "Water"),
        onSave: { _, _ in }
    )
}
