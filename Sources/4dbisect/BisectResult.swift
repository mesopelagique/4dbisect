enum BisectResult {
    case good, bad //, skip TODO support skip for test not possible
    
    var icon: String {
        switch self {
        case .bad:
            return "🔴"
        case .good:
            return "✅"
        }
    }
}
