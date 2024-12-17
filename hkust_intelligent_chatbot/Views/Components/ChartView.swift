import SwiftUI

struct ChartView: View {
    let data: [HealthSample]
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            if data.isEmpty {
                Text("No data available")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Path { path in
                    let points = data.enumerated().map { (index, sample) -> CGPoint in
                        let x = CGFloat(index) * (geometry.size.width / CGFloat(max(1, data.count - 1)))
                        let y = geometry.size.height * (1 - CGFloat((sample.value - minValue) / max(1, maxValue - minValue)))
                        return CGPoint(x: x, y: y)
                    }
                    
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(color, lineWidth: 2)
            }
        }
    }
    
    private var maxValue: Double {
        data.map(\.value).max() ?? 0
    }
    
    private var minValue: Double {
        data.map(\.value).min() ?? 0
    }
} 