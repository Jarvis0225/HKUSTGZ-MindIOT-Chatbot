import SwiftUI

struct HealthStatusView: View {
    let heartRate: Double
    let hrv: Double
    let steps: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: healthStatus.icon)
                    .foregroundColor(healthStatus.color)
                Text(healthStatus.title)
                    .font(.headline)
                Spacer()
            }
            
            Text(healthStatus.description)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if !healthStatus.recommendation.isEmpty {
                Text(healthStatus.recommendation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func evaluateHeartRate(_ heartRate: Double) -> HealthMetricStatus {
        return heartRate < 60 || heartRate > 100 ? .warning : .normal
    }

    private func evaluateHRV(_ hrv: Double) -> HealthMetricStatus {
        return hrv < 20 ? .warning : .normal
    }

    private func evaluateSteps(_ steps: Double) -> HealthMetricStatus {
        return steps < 5000 ? .warning : .normal
    }

    private var healthStatus: HealthStatusInfo {
        let heartRateStatus = evaluateHeartRate(heartRate)
        let hrvStatus = evaluateHRV(hrv)
        let stepsStatus = evaluateSteps(steps)
        
        switch (heartRateStatus, hrvStatus, stepsStatus) {
        case (.normal, .normal, .normal):
            return HealthStatusInfo(
                title: "Excellent",
                description: "All metrics are within optimal ranges.",
                recommendation: "Keep maintaining your healthy lifestyle!",
                icon: "checkmark.circle.fill",
                color: .green
            )
        case (.warning, _, _), (_, .warning, _), (_, _, .warning):
            return HealthStatusInfo(
                title: "Attention Needed",
                description: "One or more metrics are outside optimal ranges.",
                recommendation: "Consider reviewing your health habits.",
                icon: "exclamationmark.triangle.fill",
                color: .yellow
            )
        }
    }
}