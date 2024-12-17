import SwiftUI

enum HealthMetricStatus {
    case normal
    case warning
}

struct HealthStatusInfo {
    let title: String
    let description: String
    let recommendation: String
    let icon: String
    let color: Color
} 