//
//  Constants.swift
//  HydraTrack
//

import Foundation

struct Constants {
    static let presetDrinks: [PresetDrink] = [
        PresetDrink(name: "Water", volumeMl: 250, drinkType: .water, icon: "drop.fill"),
        PresetDrink(name: "Coffee", volumeMl: 200, drinkType: .coffee, icon: "cup.and.saucer.fill"),
        PresetDrink(name: "Latte", volumeMl: 240, drinkType: .coffee, icon: "cup.and.saucer.fill"),
        PresetDrink(name: "Tea", volumeMl: 200, drinkType: .tea, icon: "mug.fill"),
        PresetDrink(name: "Juice", volumeMl: 200, drinkType: .juice, icon: "wineglass"),
        PresetDrink(name: "Milk", volumeMl: 250, drinkType: .milk, icon: "waterbottle.fill"),
        PresetDrink(name: "Boba", volumeMl: 500, drinkType: .tea, icon: "bubbles.and.sparkles.fill"),
        PresetDrink(name: "Gatorade", volumeMl: 350, drinkType: .other, icon: "figure.run"),
        PresetDrink(name: "Protein Shake", volumeMl: 414, drinkType: .milk, icon: "figure.strengthtraining.traditional")
    ]

    static let healthDisclaimer = "General guidelines vary; adjust for heat, illness, kidney/heart conditions."
}
