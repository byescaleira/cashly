struct Expectation {
    let name: String
    let expected: String
    let actual: String

    init(
        _ name: String, expected: some CustomStringConvertible, actual: some CustomStringConvertible
    ) {
        self.name = name
        self.expected = expected.description
        self.actual = actual.description
    }

    var passed: Bool { expected == actual }

    var line: String {
        passed ? "PASS \(name)" : "FAIL \(name) expected=\(expected) actual=\(actual)"
    }
}
