import CashlyDomain
import Foundation
import Testing

struct ProfilePhotoTests {
    @Test(arguments: [
        ProfilePhoto.initials(color: "2E7D74"),
        .symbol("pawprint.fill", color: "C47C86"),
        .emoji("🌻", color: "DDB040"),
        .emoji("👨‍👩‍👧", color: "466A93"),
    ])
    func textPhotosSurviveEncoding(photo: ProfilePhoto) {
        #expect(photo.isValid)
        #expect(photo.data == nil)
        #expect(ProfilePhoto(encoded: photo.encoded) == photo)
    }

    @Test func memojiKeepsItsImageOutsideTheText() {
        let image = Data([1, 2, 3])
        let photo = ProfilePhoto.memoji(image)
        #expect(photo.encoded == "memoji")
        #expect(photo.data == image)
        #expect(photo.color == nil)
        #expect(ProfilePhoto(encoded: photo.encoded, data: photo.data) == photo)
    }

    @Test(arguments: ["", "58", "person", "memoji", "initials:zz", "symbol:2E7D74:", "rainbow:1"])
    func unknownOrBrokenValuesFallBackToInitials(encoded: String) {
        #expect(ProfilePhoto(encoded: encoded) == .default)
    }

    @Test func emojiMayContainTheSeparator() {
        let photo = ProfilePhoto(encoded: "emoji:DDB040:🌻")
        #expect(photo == .emoji("🌻", color: "DDB040"))
    }

    @Test(arguments: [
        ProfilePhoto.initials(color: "red"),
        .symbol("Paw Print", color: "C47C86"),
        .emoji("ab", color: "DDB040"),
        .emoji(" ", color: "DDB040"),
        .memoji(Data()),
        .memoji(Data(count: ProfilePhoto.maximumImageBytes + 1)),
    ])
    func invalidPhotosAreRejected(photo: ProfilePhoto) {
        #expect(!photo.isValid)
    }

    @Test func recoloringKeepsTheKind() {
        #expect(
            ProfilePhoto.symbol("leaf.fill", color: "2E7D74").recolored("B23A48")
                == .symbol("leaf.fill", color: "B23A48"))
        #expect(ProfilePhoto.memoji(Data([1])).recolored("B23A48") == .memoji(Data([1])))
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
