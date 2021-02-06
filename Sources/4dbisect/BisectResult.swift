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
}
