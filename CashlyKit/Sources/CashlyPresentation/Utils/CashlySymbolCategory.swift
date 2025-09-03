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
            return [
                "cart", "cart.fill",
                "basket", "basket.fill",
                "bag", "bag.fill",
                "takeoutbag.and.cup.and.straw", "takeoutbag.and.cup.and.straw.fill",
                "fork.knife", "fork.knife.circle", "fork.knife.circle.fill",
                "cup.and.saucer", "cup.and.saucer.fill",
                "wineglass", "wineglass.fill",
                "birthday.cake", "birthday.cake.fill",
                "carrot",
                "fish",
                "applelogo",
                "leaf", "leaf.fill"
            ]
            
        case .transport:
            return [
                "car", "car.fill",
                "bus", "bus.fill",
                "tram", "tram.fill",
                "bicycle", "bicycle.circle", "bicycle.circle.fill",
                "scooter",
                "airplane", "airplane.circle", "airplane.circle.fill",
                "fuelpump", "fuelpump.fill",
                "train.side.front.car",
                "sailboat", "sailboat.fill",
                "ferry", "ferry.fill",
                "figure.walk", "figure.walk.circle", "figure.walk.circle.fill"
            ]
            
        case .housing:
            return [
                "house", "house.fill",
                "building", "building.fill",
                "building.2", "building.2.fill",
                "bed.double", "bed.double.fill",
                "sofa", "sofa.fill",
                "lamp.desk", "lamp.desk.fill",
                "fan.oscillation", "fan.oscillation.fill",
                "lightbulb", "lightbulb.fill",
                "wrench", "wrench.fill",
                "hammer", "hammer.fill",
                "wrench.and.screwdriver", "wrench.and.screwdriver.fill",
                "paintbrush", "paintbrush.fill",
                "key", "key.fill"
            ]
            
        case .utilities:
            return [
                "bolt", "bolt.fill",
                "drop", "drop.fill",
                "flame", "flame.fill",
                "wifi", "wifi.slash",
                "antenna.radiowaves.left.and.right",
                "creditcard", "creditcard.fill",
                "banknote", "banknote.fill",
                "dollarsign.circle", "dollarsign.circle.fill",
                "calendar", "calendar.badge.clock",
                "envelope", "envelope.fill",
                "doc.text", "doc.text.fill",
                "doc.on.doc", "doc.on.doc.fill"
            ]
            
        case .health:
            return [
                "heart", "heart.fill",
                "cross.case", "cross.case.fill",
                "stethoscope",
                "pills", "pills.fill",
                "bandage", "bandage.fill",
                "figure.walk", "figure.walk.circle", "figure.walk.circle.fill",
                "figure.run", "figure.run.circle", "figure.run.circle.fill",
                "dumbbell",
                "lungs", "lungs.fill",
                "brain.head.profile",
                "eyeglasses",
                "staroflife", "staroflife.fill"
            ]
            
        case .entertainment:
            return [
                "gamecontroller", "gamecontroller.fill",
                "ticket", "ticket.fill",
                "music.note", "music.note.list",
                "music.mic", "music.mic.circle", "music.mic.circle.fill",
                "headphones", "headphones.circle", "headphones.circle.fill",
                "play.tv", "play.tv.fill",
                "popcorn", "popcorn.fill",
                "theatermasks", "theatermasks.fill",
                "guitars", "guitars.fill",
                "dice", "dice.fill",
                "balloon", "balloon.fill",
                "soccerball",
                "basketball", "basketball.fill",
                "tennis.racket"
            ]
            
        case .education:
            return [
                "book", "book.fill",
                "books.vertical", "books.vertical.fill",
                "graduationcap", "graduationcap.fill",
                "pencil", "pencil.circle", "pencil.circle.fill",
                "pencil.and.outline",
                "highlighter",
                "paperclip",
                "doc.text", "doc.text.fill",
                "doc.richtext",
                "laptopcomputer",
                "desktopcomputer",
                "briefcase", "briefcase.fill",
                "folder", "folder.fill"
            ]
            
        case .technology:
            return [
                "iphone",
                "ipad",
                "applewatch",
                "headphones", "headphones.circle", "headphones.circle.fill",
                "tv", "tv.fill",
                "speaker", "speaker.fill",
                "printer", "printer.fill",
                "keyboard", "keyboard.fill",
                "gamecontroller", "gamecontroller.fill",
                "display",
                "camera", "camera.fill",
                "video", "video.fill",
                "mic", "mic.fill",
                "antenna.radiowaves.left.and.right",
                "server.rack"
            ]
        }
    }

    
    public static var random: CashlySymbolCategory {
        allCases.randomElement() ?? .technology
    }
    
    public static var randomSymbol: String {
        CashlySymbolCategory.random.symbols.randomElement() ?? "questionmark"
    }
}
