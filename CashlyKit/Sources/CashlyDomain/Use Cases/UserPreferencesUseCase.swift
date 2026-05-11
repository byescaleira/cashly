//
//  UserPreferencesUseCase.swift
//  CashlyKit
//
//  Persistence-agnostic abstraction for user-scoped preferences. The
//  concrete implementation lives in CashlyData (UserDefaults-backed);
//  CashlyMock provides an in-memory variant for tests + previews.
//

public protocol UserPreferencesUseCase: Sendable {
    /// The currently-selected user id, or nil if none has been chosen.
    func currentUserId() async -> String?

    /// Persist the supplied user id as the active selection.
    func setCurrentUserId(_ id: String) async

    /// Clear the persisted selection (e.g. on sign-out).
    func clearCurrentUserId() async
}
