import Foundation

public enum AppError: Error, LocalizedError {
    case assetLoadingError(description: String)
    case environmentSetupError(reason: String)
    
    public var errorDescription: String? {
        switch self {
        case .assetLoadingError(let description):
            return "Asset Loading Error: \(description)"
        case .environmentSetupError(let reason):
            return "Environment Setup Error: \(reason)"
        }
    }
}
