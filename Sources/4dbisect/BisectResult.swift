enum BisectResult {
    case good, bad, skip, stop

    var icon: String {
        switch self {
        case .good:
            return "✅"
        case .bad:
            return "❌"
        case .skip:
            return "🌀"
        case .stop:
            return "🛑"
        }
    }

    init(code: Int32) {
        switch code {
        case 0:
            self = .good
        case 125:
            self = .skip
        case 128:
            self = .stop
        default:
            self = .bad
        }
    }

    var code: Int32 {
        switch self {
        case .good:
            return 0
        case .bad:
            return 1
        case .skip:
            return 125
        case .stop:
            return 128
        }
    }
}
