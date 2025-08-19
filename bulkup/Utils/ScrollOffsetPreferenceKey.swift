//
//  ScrollOffsetPreferenceKey.swift
//  bulkup
//
//  Created by sebastian.blanco on 19/8/25.
//

import SwiftUI

// MARK: - PreferenceKey para detectar el offset del scroll
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - ViewModifier para detectar cambios en el scroll
struct ScrollOffsetModifier: ViewModifier {
    @Binding var offset: CGFloat
    @State private var isDragging: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                // Solo actualizar si el cambio es significativo para evitar flicks
                if abs(value - offset) > 2 {
                    offset = value
                }
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { _ in
                        isDragging = true
                    }
                    .onEnded { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isDragging = false
                        }
                    }
            )
    }
}

// MARK: - Extension para facilitar el uso
extension View {
    func scrollOffset(_ offset: Binding<CGFloat>) -> some View {
        modifier(ScrollOffsetModifier(offset: offset))
    }
}
