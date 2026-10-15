import CashlyDesignSystem
import CashlyDomain
import SwiftUI

public struct ProfileAvatar: View {
    private let photo: ProfilePhoto
    private let initials: String
    private let size: CGFloat

    public init(_ user: User?, size: CGFloat = .badgeL) {
        self.init(photo: user?.photo ?? .default, initials: user?.initials ?? "", size: size)
    }

    public init(photo: ProfilePhoto, initials: String, size: CGFloat = .badgeL) {
        self.photo = photo
        self.initials = initials
        self.size = size
    }

    public var body: some View {
        Avatar(photo.avatarContent(initials: initials), color: photo.tint, size: size)
            .accessibilityLabel(photo.accessibilityLabel(initials: initials))
    }

    @MainActor public static func image(for user: User, size: CGFloat, scale: CGFloat) -> Image {
        let renderer = ImageRenderer(content: ProfileAvatar(user, size: size))
        renderer.scale = scale
        guard let image = renderer.cgImage else { return Image(systemName: "person.crop.circle") }
        return Image(decorative: image, scale: scale)
    }
}
