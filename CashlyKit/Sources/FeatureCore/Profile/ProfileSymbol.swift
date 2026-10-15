import CashlyDomain

public enum ProfileSymbol: String, CaseIterable, Identifiable, Sendable {
    case paw = "pawprint.fill"
    case cat = "cat.fill"
    case dog = "dog.fill"
    case bird = "bird.fill"
    case fish = "fish.fill"
    case turtle = "tortoise.fill"
    case leaf = "leaf.fill"
    case tree = "tree.fill"
    case flower = "camera.macro"
    case sun = "sun.max.fill"
    case moon = "moon.stars.fill"
    case flame = "flame.fill"
    case star = "star.fill"
    case heart = "heart.fill"
    case crown = "crown.fill"
    case music = "music.note"
    case palette = "paintpalette.fill"
    case book = "book.fill"
    case game = "gamecontroller.fill"
    case airplane = "airplane"
    case soccer = "soccerball"
    case basketball = "basketball.fill"
    case tennis = "tennis.racket"
    case bicycle = "bicycle"
    case running = "figure.run"
    case dumbbell = "dumbbell.fill"
    case coffee = "cup.and.saucer.fill"
    case carrot = "carrot.fill"
    case cake = "birthday.cake.fill"
    case cutlery = "fork.knife"
    case popcorn = "popcorn.fill"
    case takeout = "takeoutbag.and.cup.and.straw.fill"

    public static let `default` = ProfileSymbol.paw

    public var id: String { rawValue }

    public static func name(for symbol: String) -> String {
        ProfileSymbol(rawValue: symbol)?.name ?? String(appLocalized: "Symbol")
    }

    public var name: String {
        switch self {
        case .paw: String(appLocalized: "Paw")
        case .cat: String(appLocalized: "Cat")
        case .dog: String(appLocalized: "Dog")
        case .bird: String(appLocalized: "Bird")
        case .fish: String(appLocalized: "Fish")
        case .turtle: String(appLocalized: "Turtle")
        case .leaf: String(appLocalized: "Leaf")
        case .tree: String(appLocalized: "Tree")
        case .flower: String(appLocalized: "Flower")
        case .sun: String(appLocalized: "Sun")
        case .moon: String(appLocalized: "Moon")
        case .flame: String(appLocalized: "Flame")
        case .star: String(appLocalized: "Star")
        case .heart: String(appLocalized: "Heart")
        case .crown: String(appLocalized: "Crown")
        case .music: String(appLocalized: "Music")
        case .palette: String(appLocalized: "Palette")
        case .book: String(appLocalized: "Book")
        case .game: String(appLocalized: "Game Controller")
        case .airplane: String(appLocalized: "Airplane")
        case .soccer: String(appLocalized: "Soccer Ball")
        case .basketball: String(appLocalized: "Basketball")
        case .tennis: String(appLocalized: "Tennis")
        case .bicycle: String(appLocalized: "Bicycle")
        case .running: String(appLocalized: "Running")
        case .dumbbell: String(appLocalized: "Dumbbell")
        case .coffee: String(appLocalized: "Coffee Cup")
        case .carrot: String(appLocalized: "Carrot")
        case .cake: String(appLocalized: "Cake")
        case .cutlery: String(appLocalized: "Cutlery")
        case .popcorn: String(appLocalized: "Popcorn")
        case .takeout: String(appLocalized: "Takeout")
        }
    }
}
