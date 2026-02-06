//
//  View+HideKeyboard.swift
//  bulkup
//
//  Created by sebastian.blanco on 26/8/25.
//

import SwiftUI

extension View {
    func numbersOnlyKeyboardWithDone() -> some View {
            self.toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                }
            }
        }
}
