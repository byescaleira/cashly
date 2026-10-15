import CashlyDomain
import CoreGraphics
import FeatureCore
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

struct ProfilePhotoImageTests {
    private func sticker(width: Int, height: Int, face: CGRect) throws -> CGImage {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(
            CGContext(
                data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(srgbRed: 0.9, green: 0.6, blue: 0.2, alpha: 1))
        context.fillEllipse(in: face)
        return try #require(context.makeImage())
    }

    private func encode(_ images: [CGImage], as type: UTType) throws -> Data {
        let data = NSMutableData()
        let destination = try #require(
            CGImageDestinationCreateWithData(data, type.identifier as CFString, images.count, nil))
        for image in images { CGImageDestinationAddImage(destination, image, nil) }
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }

    private func decode(_ data: Data) throws -> CGImage {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        return try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    private func alpha(of image: CGImage, x: Int, y: Int) throws -> UInt8 {
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(
            CGContext(
                data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        let pixels = try #require(context.data?.assumingMemoryBound(to: UInt8.self))
        return pixels[(y * image.width + x) * 4 + 3]
    }

    @Test func stickerIsScaledTrimmedAndKeepsTransparency() throws {
        let image = try sticker(
            width: 1600, height: 1200, face: CGRect(x: 400, y: 200, width: 800, height: 800))
        let normalized = try decode(ProfilePhotoImage.normalized(encode([image], as: .png)))
        #expect(max(normalized.width, normalized.height) <= ProfilePhotoImage.maximumPixelSize)
        #expect(abs(normalized.width - normalized.height) <= 2)
        #expect(normalized.width >= 250)
        #expect(try alpha(of: normalized, x: 0, y: 0) == 0)
        #expect(try alpha(of: normalized, x: normalized.width / 2, y: normalized.height / 2) == 255)
    }

    @Test func largestRepresentationIsUsed() throws {
        let small = try sticker(
            width: 128, height: 128, face: CGRect(x: 0, y: 0, width: 128, height: 128))
        let large = try sticker(
            width: 1024, height: 1024, face: CGRect(x: 0, y: 0, width: 1024, height: 1024))
        let normalized = try decode(
            ProfilePhotoImage.normalized(encode([small, large], as: .tiff)))
        #expect(normalized.width == ProfilePhotoImage.maximumPixelSize)
    }

    @Test func emptyOrBrokenImagesAreRejected() throws {
        let empty = try sticker(width: 64, height: 64, face: .zero)
        let data = try encode([empty], as: .png)
        #expect(throws: CashlyError.self) { try ProfilePhotoImage.normalized(data) }
        #expect(throws: CashlyError.self) { try ProfilePhotoImage.normalized(Data("memoji".utf8)) }
    }

    @Test func plainEmojiBecomesAnEmojiPhoto() throws {
        let photo = try ProfilePhotoCapture.photo(
            from: NSAttributedString(string: "oi 🐶"), color: "2E7D74")
        #expect(photo == .emoji("🐶", color: "2E7D74"))
    }

    @Test func textWithoutEmojiIsIgnored() throws {
        #expect(
            try ProfilePhotoCapture.photo(
                from: NSAttributedString(string: "Ana 1#"), color: "2E7D74") == nil)
    }

    @Test(arguments: [
        ("😀", true), ("❤️", true), ("👍🏽", true), ("1️⃣", true), ("a", false), ("1", false),
        ("#", false),
    ])
    func recognizesEmoji(text: String, isEmoji: Bool) throws {
        let character = try #require(text.first)
        #expect(ProfilePhotoCapture.isEmoji(character) == isEmoji)
    }

    @Test func suggestedColorIsStableAndFromThePalette() {
        let color = ProfilePhoto.suggestedColor(for: "550e8400")
        #expect(ProfilePhoto.suggestedColor(for: "550e8400") == color)
        #expect(ProfilePhoto.suggested(for: "550e8400") == .initials(color: color.hex))
        #expect(Set(["a", "b", "c", "d", "e", "f"].map(ProfilePhoto.suggestedColor)).count > 1)
    }

    @Test func defaultPhotoUsesTheDefaultAccent() {
        #expect(RetroColor.default.hex == ProfilePhoto.defaultColor)
    }

    @Test func everyProfileSymbolIsUniqueAndNamed() {
        #expect(Set(ProfileSymbol.allCases.map(\.rawValue)).count == ProfileSymbol.allCases.count)
        #expect(ProfileSymbol.allCases.allSatisfy { !$0.name.isEmpty })
        #expect(
            ProfileSymbol.allCases.allSatisfy {
                ProfilePhoto.symbol($0.rawValue, color: "2E7D74").isValid
            })
    }
}
