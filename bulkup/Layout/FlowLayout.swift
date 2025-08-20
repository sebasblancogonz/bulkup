//
//  FlowLayout.swift
//  bulkup
//
//  Created by sebastian.blanco on 20/8/25.
//
import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let viewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + viewSize.width > maxWidth, currentX > 0 {
                    currentY += lineHeight + spacing
                    currentX = 0
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: viewSize))
                lineHeight = max(lineHeight, viewSize.height)
                currentX += viewSize.width + spacing
            }
            
            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
