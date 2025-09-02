//
//  CashlySymbolCategory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import SwiftUI

public enum CashlySymbolCategory: Int, Hashable, CaseIterable {
    case food
    case transport
    case housing
    case utilities
    case health
    case entertainment
    case education
    case technology
    
    public var name: String {
        switch self {
        case .food: return "Food & Shopping"
        case .transport: return "Transport & Travel"
        case .housing: return "Housing & Home"
        case .utilities: return "Bills & Utilities"
        case .health: return "Health & Wellness"
        case .entertainment: return "Entertainment & Leisure"
        case .education: return "Education & Work"
        case .technology: return "Technology & Communication"
        }
    }
    
    public var symbols: [String] {
        switch self {
        case .food:
            return ["cart", "cart.fill", "basket", "basket.fill", "bag", "bag.fill", "takeoutbag.and.cup.and.straw", "fork.knife", "cup.and.saucer", "wineglass", "birthday.cake", "carrot", "fish"]
        case .transport:
            return ["car", "car.fill", "bus", "bus.fill", "tram", "bicycle", "scooter", "airplane", "airplane.circle", "fuelpump", "fuelpump.fill", "train.side.front.car", "sailboat", "ferry"]
        case .housing:
            return ["house", "house.fill", "building", "building.2", "bed.double", "bed.double.fill", "sofa", "sofa.fill", "lamp.desk", "fan.oscillation", "lightbulb", "wrench", "hammer", "paintbrush"]
        case .utilities:
            return ["bolt.fill", "drop.fill", "flame.fill", "wifi", "antenna.radiowaves.left.and.right", "creditcard", "creditcard.fill", "banknote", "banknote.fill", "dollarsign.circle", "dollarsign.circle.fill", "calendar", "calendar.badge.clock", "envelope", "envelope.fill"]
        case .health:
            return ["heart", "heart.fill", "cross.case", "cross.case.fill", "stethoscope", "pills", "bandage", "figure.walk", "figure.run", "dumbbell", "lungs", "brain.head.profile", "eyeglasses"]
        case .entertainment:
            return ["gamecontroller", "gamecontroller.fill", "ticket", "ticket.fill", "music.note", "music.mic", "headphones", "play.tv", "popcorn", "theatermasks", "guitars", "dice", "balloon", "soccerball", "basketball", "tennis.racket"]
        case .education:
            return ["book", "book.fill", "books.vertical", "graduationcap", "graduationcap.fill", "pencil", "pencil.and.outline", "highlighter", "paperclip", "doc.text", "doc.richtext", "laptopcomputer", "desktopcomputer", "briefcase", "briefcase.fill"]
        case .technology:
            return ["iphone", "ipad", "applewatch", "headphones", "tv", "speaker", "printer", "keyboard", "gamecontroller", "display", "camera", "video", "mic", "antenna.radiowaves.left.and.right", "server.rack"]
        }
    }
    
    public static var random: CashlySymbolCategory {
        allCases.randomElement() ?? .technology
    }
    
    public static var randomSymbol: String {
        CashlySymbolCategory.random.symbols.randomElement() ?? "questionmark"
    }
}
