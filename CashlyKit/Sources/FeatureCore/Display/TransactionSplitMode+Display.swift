import CashlyDomain

extension TransactionSplitMode {
    public var summary: String {
        switch self {
        case .equal: "Igual"
        case .fixedAmount: "Valor fixo"
        case .percentage: "Porcentagem"
        case .payerBased: "Quem pagou"
        }
    }

    public var description: String {
        switch self {
        case .equal: "Divide o total igualmente entre todos os participantes."
        case .fixedAmount: "Define um valor fixo para cada participante."
        case .percentage: "Distribui o total por porcentagem."
        case .payerBased: "Uma pessoa paga o valor inteiro e as outras ficam devendo."
        }
    }
}
