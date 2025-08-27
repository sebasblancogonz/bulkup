//
//  UIImage+Extensions.swift
//  bulkup
//
//  Created by sebastian.blanco on 27/8/25.
//
import SwiftUI

// MARK: - UIImage Extension for Resizing
extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        // Mantener aspecto ratio
        let ratio = min(widthRatio, heightRatio)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        self.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
    
    func getDominantColors(count: Int = 3) -> [UIColor] {
            guard let inputImage = CIImage(image: self) else { return [.blue] }
            
            let extentVector = CIVector(x: inputImage.extent.origin.x,
                                      y: inputImage.extent.origin.y,
                                      z: inputImage.extent.size.width,
                                      w: inputImage.extent.size.height)
            
            guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return [.blue] }
            guard let outputImage = filter.outputImage else { return [.blue] }
            
            var bitmap = [UInt8](repeating: 0, count: 4)
            let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
            context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
            
            let color = UIColor(red: CGFloat(bitmap[0]) / 255,
                               green: CGFloat(bitmap[1]) / 255,
                               blue: CGFloat(bitmap[2]) / 255,
                               alpha: 1.0)
            
            // Crear variaciones del color dominante
            return [color, color.withAlphaComponent(0.8), color.withAlphaComponent(0.6)]
        }
}
