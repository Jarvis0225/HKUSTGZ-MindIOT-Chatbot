import SwiftUI

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromAI {
                AIMessageView(message: message)
                    .layoutPriority(1)
            } else {
                UserMessageView(message: message)
                    .layoutPriority(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isFromAI ? .leading : .trailing)
        .padding(.horizontal, 8)
    }
}

struct AIMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "brain.head.profile")
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
            
            Text(message.content)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
    }
}

struct UserMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            Spacer(minLength: 0)
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(16)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let healthData = message.healthData {
                    HealthDataPreview(heartRates: healthData.heartRates, 
                                    hrvs: healthData.hrvs)
                        .padding(.horizontal, 4)
                }
            }
        }
    }
}

struct HealthDataPreview: View {
    let heartRates: [HealthSample]
    let hrvs: [HealthSample]
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if let lastHeartRate = heartRates.first {
                Text("Heart Rate: \(Int(lastHeartRate.value)) BPM")
                    .font(.caption)
            }
            
            if let lastHRV = hrvs.first {
                Text("HRV: \(Int(lastHRV.value)) ms")
                    .font(.caption)
            }
        }
    }
}