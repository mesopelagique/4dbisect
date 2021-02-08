enum BisectResult {
    case good, bad, skip

    var icon: String {
        switch self {
        case .skip:
            return "🌀"
        case .bad:
            return "❌"
        case .good:
            return "✅"
        }
    }

    init(code: Int32) {
        switch code {
        case 0:
            self = .good
        case 125:
            self = .skip
        default:
            self = .bad
        }
    }
}
