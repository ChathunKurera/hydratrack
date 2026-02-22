//
//  UndoToastView.swift
//  HydraTrack
//

import SwiftUI

struct UndoToastModifier: ViewModifier {
    @Binding var drinkToUndo: DrinkEntry?
    let unit: VolumeUnit
    let onUndo: (DrinkEntry) -> Void

    @State private var isVisible = false
    @State private var dismissTimer: Timer?
    @State private var displayedDrink: DrinkEntry?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isVisible, let drink = displayedDrink {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(drink.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(unit.format(drink.volumeMl))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button {
                            dismissTimer?.invalidate()
                            withAnimation(.easeOut(duration: 0.2)) {
                                isVisible = false
                            }
                            onUndo(drink)
                            displayedDrink = nil
                            drinkToUndo = nil
                        } label: {
                            Text("Undo")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryBlue)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onChange(of: drinkToUndo) { _, newDrink in
                if let drink = newDrink {
                    // Replace any previous undo opportunity
                    dismissTimer?.invalidate()
                    displayedDrink = drink

                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isVisible = true
                    }

                    // Auto-dismiss after 5 seconds
                    dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isVisible = false
                            }
                            displayedDrink = nil
                            drinkToUndo = nil
                        }
                    }
                }
            }
    }
}

extension View {
    func undoToast(drinkToUndo: Binding<DrinkEntry?>, unit: VolumeUnit, onUndo: @escaping (DrinkEntry) -> Void) -> some View {
        modifier(UndoToastModifier(drinkToUndo: drinkToUndo, unit: unit, onUndo: onUndo))
    }
}
