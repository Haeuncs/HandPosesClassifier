//
//  UIImage+.swift
//  HandPoseVision
//
//  Created by LEE HAEUN on 2020/11/02.
//

import UIKit

extension UIImage {
    func resize(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: newSize.width, height: newSize.height), true, 1.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return resizedImage
    }

    func imageByApplyingMaskingBezierPath(_ path: UIBezierPath) -> UIImage? {

        UIGraphicsBeginImageContext(self.size)
        let context = UIGraphicsGetCurrentContext()!

        context.addPath(path.cgPath)
        context.clip()
        draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))

        let maskedImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return maskedImage
    }


    func toBlackAndWhite() -> UIImage? {
        guard let ciImage = CIImage(image: self) else {
            return nil
        }
        guard let grayImage = CIFilter(name: "CIPhotoEffectNoir", parameters: [kCIInputImageKey:     ciImage])?.outputImage else {
            return nil
        }
        let bAndWParams: [String: Any] = [kCIInputImageKey: grayImage,
                                          kCIInputContrastKey: 50.0,
                                          kCIInputBrightnessKey: 10.0]
        guard let bAndWImage = CIFilter(name: "CIColorControls", parameters: bAndWParams)?.outputImage else {
            return nil
        }
        guard let cgImage = CIContext(options: nil).createCGImage(bAndWImage, from: bAndWImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    func pixelBuffer() -> CVPixelBuffer? {
        let width = self.size.width
        let height = self.size.height
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)

        guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(resultPixelBuffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                                        return nil
        }

        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return resultPixelBuffer
    }

}
