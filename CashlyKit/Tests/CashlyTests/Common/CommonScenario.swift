struct TestScenario<Input: Sendable, Expected: Sendable>: Sendable {
    let input: Input
    let expected: Expected
    let description: String
}
