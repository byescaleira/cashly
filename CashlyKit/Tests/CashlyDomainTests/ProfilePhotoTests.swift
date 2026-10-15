import CashlyDomain
import Foundation
import Testing

struct ProfilePhotoTests {
    @Test(arguments: [
        ProfilePhoto.initials(color: "2E7D74"),
        .symbol("pawprint.fill", color: "C47C86"),
        .illustration("classics-01"),
        .illustration("fantasy-10"),
    ])
    func photosSurviveEncoding(photo: ProfilePhoto) {
        #expect(photo.isValid)
        #expect(ProfilePhoto(encoded: photo.encoded) == photo)
    }

    @Test func encodingIsReadable() {
        #expect(ProfilePhoto.initials(color: "2E7D74").encoded == "initials:2E7D74")
        #expect(
            ProfilePhoto.symbol("cat.fill", color: "B23A48").encoded == "symbol:B23A48:cat.fill")
        #expect(ProfilePhoto.illustration("ocean-03").encoded == "illustration:ocean-03")
    }

    @Test(arguments: [
        "", "58", "person", "memoji", "initials:zz", "symbol:2E7D74:", "rainbow:1",
        "illustration:", "illustration:Ocean-1", "emoji:DDB040:🌻",
    ])
    func unknownOrBrokenValuesFallBackToInitials(encoded: String) {
        #expect(ProfilePhoto(encoded: encoded) == .default)
    }

    @Test(arguments: [
        ProfilePhoto.initials(color: "red"),
        .symbol("Paw Print", color: "C47C86"),
        .illustration("cat"),
        .illustration("ocean-1"),
        .illustration("ocean-01-x"),
    ])
    func invalidPhotosAreRejected(photo: ProfilePhoto) {
        #expect(!photo.isValid)
    }

    @Test func recoloringKeepsTheKind() {
        #expect(
            ProfilePhoto.symbol("leaf.fill", color: "2E7D74").recolored("B23A48")
                == .symbol("leaf.fill", color: "B23A48"))
        #expect(
            ProfilePhoto.illustration("farm-02").recolored("B23A48") == .illustration("farm-02"))
        #expect(ProfilePhoto.illustration("farm-02").color == nil)
    }

    @Test(arguments: [
        ("Ana Souza", "AS"),
        ("  maria da silva  ", "MS"),
        ("ana", "A"),
        ("José", "J"),
        ("Émile Zola", "ÉZ"),
        ("", ""),
        ("123 Corp", "1C"),
    ])
    func initialsUseTheFirstAndLastName(name: String, initials: String) {
        #expect(User(id: "u", name: name).initials == initials)
    }

    @Test func newUsersStartWithInitials() {
        #expect(User(id: "u", name: "Ana").photo == .default)
    }
}
