import CashlyDomain

extension ProfilePhoto {
    public var isProExclusive: Bool {
        guard case .illustration(let id) = self else { return false }
        return ProfileIllustration(id: id)?.section.isProOnly == true
    }
}

extension SessionModel {
    public func dropProPhotos() async {
        let affected = users.filter(\.photo.isProExclusive)
        guard !affected.isEmpty else { return }
        for var user in affected {
            user.photo = .suggested(for: user.id)
            do {
                try await repositories.users.save(user)
            } catch {
                self.error = error as? CashlyError ?? .onSave
            }
        }
        await refreshUsers()
    }
}
