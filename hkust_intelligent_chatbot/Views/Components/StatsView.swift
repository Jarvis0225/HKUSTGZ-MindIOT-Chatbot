import SwiftUI

struct StatsView: View {
    let data: [HealthSample]
    let unit: String
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(title: "Average", value: average, unit: unit)
            StatItem(title: "Maximum", value: maximum, unit: unit)
            StatItem(title: "Minimum", value: minimum, unit: unit)
            StatItem(title: "Total", value: total, unit: unit)
        }
    }
    
    private var average: Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }
    
    private var maximum: Double {
        data.map(\.value).max() ?? 0
    }
    
    private var minimum: Double {
        data.map(\.value).min() ?? 0
    }
    
    private var total: Double {
        data.map(\.value).reduce(0, +)
    }
}

struct StatItem: View {
    let title: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(String(format: "%.1f", value))
                .font(.headline)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
} 