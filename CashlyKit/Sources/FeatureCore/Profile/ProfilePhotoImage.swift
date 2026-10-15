import CashlyDomain
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum ProfilePhotoImage {
    public static let maximumPixelSize = 512
    @MainActor private static let cache = NSCache<NSData, CGImage>()

    public static func normalized(_ data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let index = largestImage(in: source),
            let scaled = CGImageSourceCreateThumbnailAtIndex(
                source, index,
                [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: maximumPixelSize,
                ] as CFDictionary),
            let trimmed = trimmed(scaled),
            let encoded = encoded(trimmed), encoded.count <= ProfilePhoto.maximumImageBytes
        else {
            throw CashlyError.invalidInput(
                String(appLocalized: "This sticker couldn't be used. Try another one."))
        }
        return encoded
    }

    @MainActor public static func image(from data: Data) -> CGImage? {
        let key = data as NSData
        if let cached = cache.object(forKey: key) { return cached }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }

    private static func largestImage(in source: CGImageSource) -> Int? {
        (0..<CGImageSourceGetCount(source)).max {
            pixels(in: source, at: $0) < pixels(in: source, at: $1)
        }
    }

    private static func pixels(in source: CGImageSource, at index: Int) -> Int {
        let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
        let width = properties?[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = properties?[kCGImagePropertyPixelHeight] as? Int ?? 0
        return width * height
    }

    private static func trimmed(_ image: CGImage) -> CGImage? {
        let width = image.width
        let height = image.height
        guard let space = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: nil, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else { return nil }
        var minX = width
        var minY = height
        var maxX = -1
        var maxY = -1
        for y in 0..<height {
            for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 8 {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
        guard maxX >= 0, let rendered = context.makeImage() else { return nil }
        return rendered.cropping(
            to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))
    }

    private static func encoded(_ image: CGImage) -> Data? {
        for type in [UTType.heic, .png] {
            let data = NSMutableData()
            guard
                let destination = CGImageDestinationCreateWithData(
                    data, type.identifier as CFString, 1, nil)
            else { continue }
            CGImageDestinationAddImage(
                destination, image,
                [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
            if CGImageDestinationFinalize(destination), data.length > 0 { return data as Data }
        }
        return nil
    }
}
