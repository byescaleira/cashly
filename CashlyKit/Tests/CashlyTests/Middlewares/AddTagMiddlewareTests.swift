//
//  AddTagMiddlewareTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyPresentation

@Suite("AddTagMiddleware", .tags(.unit, .presentation, .local))
struct AddTagMiddlewareTests {
    private func makeMiddleware(
        tagUseCase: TagUseCaseDouble = TagUseCaseDouble(),
        userUseCase: UserUseCaseDouble = UserUseCaseDouble()
    ) -> AddTagMiddleware {
        AddTagMiddleware(tagUseCase: tagUseCase, userUseCase: userUseCase)
    }

    @Test("update emits .stopLoading")
    func updateEmitsStopLoading() async {
        let mw = makeMiddleware()
        let actions = await collectActions(from: mw.run(
            state: .new(),
            action: .update(id: "x", user: nil, name: "y", color: "#000", icon: "i", isNew: true)
        ))
        if case .stopLoading = actions.first {} else { Issue.record("expected .stopLoading") }
    }

    @Test("passive actions emit nothing")
    func passiveActionsEmitNothing() async {
        let mw = makeMiddleware()
        for action: AddTagAction in [.stopLoading, .saved, .error(.onSave), .replace(.new())] {
            let actions = await collectActions(from: mw.run(state: .new(), action: action))
            #expect(actions.isEmpty)
        }
    }

    @Test("fetch with no tag emits .update isNew=true")
    func fetchNoTag() async {
        let userUC = UserUseCaseDouble()
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        userUC.currentUser = user
        userUC.users = [user]
        let mw = makeMiddleware(userUseCase: userUC)
        let actions = await collectActions(from: mw.run(state: .new(), action: .fetch))
        guard case let .update(_, _, _, _, _, isNew) = actions.first
        else { Issue.record("expected .update"); return }
        #expect(isNew == true)
    }

    @Test("fetch with existing tag emits .update isNew=false")
    func fetchExistingTag() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let tag = Tag(id: "t1", user: user, name: "Coffee", color: "#8B4513", icon: "cup.and.saucer")
        let tagUC = TagUseCaseDouble()
        tagUC.tags = [tag]
        let userUC = UserUseCaseDouble()
        userUC.currentUser = user
        let mw = makeMiddleware(tagUseCase: tagUC, userUseCase: userUC)
        var state = AddTagState.new()
        state.id = "t1"
        let actions = await collectActions(from: mw.run(state: state, action: .fetch))
        guard case let .update(id, _, name, _, icon, isNew) = actions.first
        else { Issue.record("expected .update"); return }
        #expect(id == "t1")
        #expect(name == "Coffee")
        #expect(icon == "cup.and.saucer")
        #expect(isNew == false)
    }

    @Test("save validates name length")
    func saveValidatesName() async {
        let mw = makeMiddleware()
        var state = AddTagState.new()
        state.name = "ab"
        state.icon = "x"
        state.user = User(id: "u", name: "A", photo: "https://x/a.png")
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .error(.onSave) = actions.first {} else { Issue.record("expected .error(.onSave)") }
    }

    @Test("save happy path emits .saved")
    func saveHappyPath() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let mw = makeMiddleware()
        var state = AddTagState.new()
        state.name = "Coffee"
        state.icon = "cup.and.saucer"
        state.color = "#8B4513"
        state.user = user
        let actions = await collectActions(from: mw.run(state: state, action: .save))
        if case .saved = actions.first {} else { Issue.record("expected .saved") }
    }

    @Test("remove existing tag emits .saved")
    func removeHappyPath() async {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let tag = Tag(id: "t-x", user: user, name: "X", color: "#000", icon: "x")
        let tagUC = TagUseCaseDouble()
        tagUC.tags = [tag]
        let mw = makeMiddleware(tagUseCase: tagUC)
        var state = AddTagState.new()
        state.id = "t-x"
        let actions = await collectActions(from: mw.run(state: state, action: .remove))
        if case .saved = actions.first {} else { Issue.record("expected .saved") }
    }

    @Test("remove unknown tag emits .error(.onRemove)")
    func removeUnknown() async {
        let mw = makeMiddleware()
        var state = AddTagState.new()
        state.id = "nope"
        let actions = await collectActions(from: mw.run(state: state, action: .remove))
        if case .error(.onRemove) = actions.first {} else { Issue.record("expected .error(.onRemove)") }
    }
}
