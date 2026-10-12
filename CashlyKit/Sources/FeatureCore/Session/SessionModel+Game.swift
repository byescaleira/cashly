import CashlyDomain

extension SessionModel {
    public func record(_ kind: GameEvent.Kind, value: String = "") async {
        guard user != nil else { return }
        try? await repositories.game.record([GameEvent(kind: kind, value: value)])
    }
}
