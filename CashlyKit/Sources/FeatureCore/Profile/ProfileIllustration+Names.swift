import CashlyDomain

extension ProfileIllustration {
    public var name: String {
        switch id {
        case "classics-01": String(appLocalized: "Cat")
        case "classics-02": String(appLocalized: "Puppy")
        case "classics-03": String(appLocalized: "Rabbit")
        case "classics-04": String(appLocalized: "Bear Cub")
        case "classics-05": String(appLocalized: "Panda")
        case "classics-06": String(appLocalized: "Fox")
        case "classics-07": String(appLocalized: "Hamster")
        case "classics-08": String(appLocalized: "Koala")
        case "classics-09": String(appLocalized: "Penguin")
        case "classics-10": String(appLocalized: "Lion Cub")
        case "brazil-01": String(appLocalized: "Capybara")
        case "brazil-02": String(appLocalized: "Toucan")
        case "brazil-03": String(appLocalized: "Golden Lion Tamarin")
        case "brazil-04": String(appLocalized: "Armadillo")
        case "brazil-05": String(appLocalized: "Jaguar Cub")
        case "brazil-06": String(appLocalized: "Hyacinth Macaw")
        case "brazil-07": String(appLocalized: "Sloth")
        case "brazil-08": String(appLocalized: "Pink River Dolphin")
        case "brazil-09": String(appLocalized: "Giant Anteater")
        case "brazil-10": String(appLocalized: "Coati")
        case "savers-01": String(appLocalized: "Piglet")
        case "savers-02": String(appLocalized: "Squirrel")
        case "savers-03": String(appLocalized: "Beaver")
        case "savers-04": String(appLocalized: "Bumblebee")
        case "savers-05": String(appLocalized: "Ant")
        case "savers-06": String(appLocalized: "Owl")
        case "savers-07": String(appLocalized: "Camel")
        case "savers-08": String(appLocalized: "Tortoise")
        case "savers-09": String(appLocalized: "Kangaroo")
        case "savers-10": String(appLocalized: "Magpie")
        case "ocean-01": String(appLocalized: "Octopus")
        case "ocean-02": String(appLocalized: "Whale")
        case "ocean-03": String(appLocalized: "Dolphin")
        case "ocean-04": String(appLocalized: "Seal Pup")
        case "ocean-05": String(appLocalized: "Pufferfish")
        case "ocean-06": String(appLocalized: "Crab")
        case "ocean-07": String(appLocalized: "Jellyfish")
        case "ocean-08": String(appLocalized: "Sea Otter")
        case "ocean-09": String(appLocalized: "Clownfish")
        case "ocean-10": String(appLocalized: "Manta Ray")
        case "farm-01": String(appLocalized: "Cow")
        case "farm-02": String(appLocalized: "Chick")
        case "farm-03": String(appLocalized: "Sheep")
        case "farm-04": String(appLocalized: "Goat")
        case "farm-05": String(appLocalized: "Duckling")
        case "farm-06": String(appLocalized: "Horse")
        case "farm-07": String(appLocalized: "Donkey")
        case "farm-08": String(appLocalized: "Rooster")
        case "farm-09": String(appLocalized: "Turkey")
        case "farm-10": String(appLocalized: "Llama")
        case "savanna-01": String(appLocalized: "Elephant")
        case "savanna-02": String(appLocalized: "Giraffe")
        case "savanna-03": String(appLocalized: "Zebra")
        case "savanna-04": String(appLocalized: "Hippo")
        case "savanna-05": String(appLocalized: "Rhino")
        case "savanna-06": String(appLocalized: "Tiger Cub")
        case "savanna-07": String(appLocalized: "Monkey")
        case "savanna-08": String(appLocalized: "Flamingo")
        case "savanna-09": String(appLocalized: "Ostrich")
        case "savanna-10": String(appLocalized: "Meerkat")
        case "cold-01": String(appLocalized: "Polar Bear Cub")
        case "cold-02": String(appLocalized: "Arctic Fox")
        case "cold-03": String(appLocalized: "Wolf Pup")
        case "cold-04": String(appLocalized: "Raccoon")
        case "cold-05": String(appLocalized: "Moose")
        case "cold-06": String(appLocalized: "Fawn")
        case "cold-07": String(appLocalized: "Walrus")
        case "cold-08": String(appLocalized: "Snowy Owl")
        case "cold-09": String(appLocalized: "Reindeer")
        case "cold-10": String(appLocalized: "Red Panda")
        case "tiny-01": String(appLocalized: "Mouse")
        case "tiny-02": String(appLocalized: "Frog")
        case "tiny-03": String(appLocalized: "Snail")
        case "tiny-04": String(appLocalized: "Butterfly")
        case "tiny-05": String(appLocalized: "Caterpillar")
        case "tiny-06": String(appLocalized: "Ladybug")
        case "tiny-07": String(appLocalized: "Axolotl")
        case "tiny-08": String(appLocalized: "Guinea Pig")
        case "tiny-09": String(appLocalized: "Hedgehog")
        case "tiny-10": String(appLocalized: "Chameleon")
        case "birds-01": String(appLocalized: "Parrot")
        case "birds-02": String(appLocalized: "Hummingbird")
        case "birds-03": String(appLocalized: "Pelican")
        case "birds-04": String(appLocalized: "Swan")
        case "birds-05": String(appLocalized: "Peacock")
        case "birds-06": String(appLocalized: "Canary")
        case "birds-07": String(appLocalized: "Pigeon")
        case "birds-08": String(appLocalized: "Seagull")
        case "birds-09": String(appLocalized: "Kiwi Bird")
        case "birds-10": String(appLocalized: "Woodpecker")
        case "fantasy-01": String(appLocalized: "Baby Dragon")
        case "fantasy-02": String(appLocalized: "Unicorn")
        case "fantasy-03": String(appLocalized: "Friendly Ghost")
        case "fantasy-04": String(appLocalized: "Fluffy Monster")
        case "fantasy-05": String(appLocalized: "Yeti")
        case "fantasy-06": String(appLocalized: "Little Alien")
        case "fantasy-07": String(appLocalized: "Phoenix Chick")
        case "fantasy-08": String(appLocalized: "Sea Serpent")
        case "fantasy-09": String(appLocalized: "Griffin Chick")
        case "fantasy-10": String(appLocalized: "Baby Kraken")
        default: String(appLocalized: "Illustration")
        }
    }

    public var background: String {
        switch id {
        case "classics-01", "brazil-08", "savers-09", "ocean-01", "ocean-09", "farm-05", "cold-08",
            "birds-03", "fantasy-09":
            "527194"
        case "classics-02", "brazil-02", "savers-03", "ocean-05", "farm-02", "savanna-02",
            "savanna-09", "cold-05", "tiny-09", "birds-02", "fantasy-02":
            "83A4C2"
        case "classics-03", "brazil-01", "ocean-06", "farm-06", "savanna-08", "tiny-06",
            "fantasy-10":
            "6FA798"
        case "classics-04", "brazil-07", "farm-03", "cold-04", "tiny-03", "birds-10": "99A995"
        case "classics-05", "farm-01", "birds-09": "8C9A47"
        case "classics-06", "brazil-05", "savers-01", "ocean-04", "farm-08", "savanna-04",
            "cold-01", "cold-10", "tiny-07", "fantasy-07":
            "387D75"
        case "classics-07", "brazil-10", "farm-10", "tiny-08": "A798BB"
        case "classics-08", "savers-02": "6E7E3F"
        case "classics-09", "savers-07", "ocean-08", "savanna-07", "cold-07", "birds-08": "479BA0"
        case "classics-10", "savanna-10", "tiny-02", "fantasy-01": "885A75"
        case "brazil-03", "savanna-06", "cold-06": "637D57"
        case "brazil-04", "ocean-02", "savanna-01", "cold-03", "tiny-01", "birds-07": "D3B05C"
        case "brazil-06", "farm-07", "tiny-05": "C07757"
        case "brazil-09", "savers-10", "farm-04", "savanna-05", "birds-05": "C4993F"
        case "savers-04", "ocean-07", "cold-02", "birds-06", "fantasy-03": "686C9F"
        case "savers-05", "ocean-10", "farm-09", "tiny-04", "birds-01", "fantasy-08": "BFAA8C"
        case "savers-06", "fantasy-06": "715275"
        case "savers-08", "ocean-03", "savanna-03", "tiny-10": "D69C87"
        case "cold-09": "B14955"
        case "birds-04": "C48F96"
        case "fantasy-04": "D3914B"
        case "fantasy-05": "74706D"
        default: ProfilePhoto.defaultColor
        }
    }
}
