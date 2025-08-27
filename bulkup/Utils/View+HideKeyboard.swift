//
//  View+HideKeyboard.swift
//  bulkup
//
//  Created by sebastian.blanco on 26/8/25.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
