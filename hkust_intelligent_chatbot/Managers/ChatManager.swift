import Foundation
import HealthKit

class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private let healthStore = HKHealthStore()
    private var currentHealthData: ChatMessage.HealthData?
    private let userDefaults = UserDefaults.standard
    private let messagesKey = "chatMessages"
    
    init() {
        loadMessages()
        setupNetworkHandlers()
    }
    
    private func setupNetworkHandlers() {
        NetworkManager.shared.addMessageHandler { [weak self] message in
            DispatchQueue.main.async {
                self?.messages.append(message)
                self?.saveMessages()
            }
        }
    }
    
    private func loadMessages() {
        if let data = userDefaults.data(forKey: messagesKey),
           let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            self.messages = messages
        }
    }
    
    private func saveMessages() {
        if let data = try? JSONEncoder().encode(messages) {
            userDefaults.set(data, forKey: messagesKey)
        }
    }
    
    func sendHealthData(heartRates: [HealthSample], hrvs: [HealthSample], steps: [HealthSample]) {
        print("开始分析健康数据")
        print("发送心率数据: \(heartRates.count) 条")
        print("发送HRV数据: \(hrvs.count) 条")
        print("发送步数数据: \(steps.count) 条")
        
        // 保存当前的健康数据
        currentHealthData = ChatMessage.HealthData(heartRates: heartRates, hrvs: hrvs, steps: steps)
        
        // 添加用户的健康数据消息
        let userMessage = ChatMessage(
            content: "Here's my latest health data",
            isFromAI: false,
            healthData: currentHealthData
        )
        
        messages.append(userMessage)
        saveMessages()
        
        // 调用 NetworkManager 发送数据并获取响应
        NetworkManager.shared.sendDataToCloud(
            heartRates: heartRates,
            hrvs: hrvs,
            steps: steps
        ) { [weak self] success, response in
            DispatchQueue.main.async {
                if success {
                    if let response = response {
                        let aiMessage = ChatMessage(
                            content: response,
                            isFromAI: true
                        )
                        self?.messages.append(aiMessage)
                        self?.saveMessages()
                    }
                } else {
                    let errorMessage = ChatMessage(
                        content: response ?? "抱歉，处理健康数据时出错了。请稍后再试。",
                        isFromAI: true
                    )
                    self?.messages.append(errorMessage)
                    self?.saveMessages()
                }
            }
        }
    }
    
    func sendMessage(_ content: String) {
        // 添加用户消息
        let userMessage = ChatMessage(content: content, isFromAI: false)
        messages.append(userMessage)
        saveMessages()
        
        // 调用 NetworkManager 发送消息并获取响应
        NetworkManager.shared.sendMessage(content) { [weak self] success, response in
            DispatchQueue.main.async {
                if success {
                    if let response = response {
                        let aiMessage = ChatMessage(
                            content: response,
                            isFromAI: true
                        )
                        self?.messages.append(aiMessage)
                        self?.saveMessages()
                    }
                } else {
                    let errorMessage = ChatMessage(
                        content: response ?? "抱歉，我暂时无法回复。请稍后再试。",
                        isFromAI: true
                    )
                    self?.messages.append(errorMessage)
                    self?.saveMessages()
                }
            }
        }
    }
    
    func clearMessages() {
        messages.removeAll()
        saveMessages()
    }
    
    private func formatHealthData() -> String {
        guard let healthData = currentHealthData else {
            return "目前没有健康数据记录。"
        }
        
        var description = ""
        
        if !healthData.heartRates.isEmpty {
            let avgHeartRate = healthData.heartRates.map(\.value).reduce(0, +) / Double(healthData.heartRates.count)
            description += "心率数据:\n"
            description += "- 平均心率: \(String(format: "%.1f", avgHeartRate)) BPM\n"
            description += "- 记录数量: \(healthData.heartRates.count)\n\n"
        }
        
        if !healthData.hrvs.isEmpty {
            let avgHRV = healthData.hrvs.map(\.value).reduce(0, +) / Double(healthData.hrvs.count)
            description += "心率变异性(HRV)数据:\n"
            description += "- 平均HRV: \(String(format: "%.1f", avgHRV)) ms\n"
            description += "- 记录数量: \(healthData.hrvs.count)\n\n"
        }
        
        if !healthData.steps.isEmpty {
            let totalSteps = healthData.steps.map(\.value).reduce(0, +)
            description += "步数数据:\n"
            description += "- 总步数: \(Int(totalSteps))\n"
            description += "- 记录数量: \(healthData.steps.count)\n"
        }
        
        if description.isEmpty {
            description = "目前没有健康数据记录。"
        }
        
        return description
    }
    
    private func handleAPIError(_ message: String) {
        DispatchQueue.main.async {
            let errorMessage = ChatMessage(
                content: "⚠️ \(message)",
                isFromAI: true
            )
            self.messages.append(errorMessage)
            self.saveMessages()
        }
    }
    
    private func generateHealthAnalysis() -> String {
        var analysis = "Based on your health data:\n\n"
        
        if let healthData = currentHealthData {
            // 分析心率数据
            if !healthData.heartRates.isEmpty {
                let avgHeartRate = healthData.heartRates.map(\.value).reduce(0, +) / Double(healthData.heartRates.count)
                analysis += "💓 Heart Rate: \(String(format: "%.1f", avgHeartRate)) BPM\n"
                
                if avgHeartRate < 60 {
                    analysis += "Your heart rate is below normal range. This could indicate rest state or potential bradycardia.\n"
                } else if avgHeartRate > 100 {
                    analysis += "Your heart rate is elevated. This could be due to physical activity or stress.\n"
                } else {
                    analysis += "Your heart rate is within normal range.\n"
                }
            }
            
            // 分析HRV数据
            if !healthData.hrvs.isEmpty {
                let avgHRV = healthData.hrvs.map(\.value).reduce(0, +) / Double(healthData.hrvs.count)
                analysis += "\n❤️ HRV: \(String(format: "%.1f", avgHRV)) ms\n"
                
                if avgHRV < 50 {
                    analysis += "Your HRV is relatively low. This might indicate stress or need for recovery.\n"
                } else {
                    analysis += "Your HRV is in a good range, suggesting good cardiac health.\n"
                }
            }
            
            // 分析步数数据
            if !healthData.steps.isEmpty {
                let totalSteps = healthData.steps.map(\.value).reduce(0, +)
                analysis += "\n👣 Steps: \(Int(totalSteps))\n"
                
                if totalSteps < 5000 {
                    analysis += "You might want to move more to reach the daily goal of 10,000 steps.\n"
                } else if totalSteps >= 10000 {
                    analysis += "Great job! You've reached the recommended daily step count.\n"
                } else {
                    analysis += "You're on your way to reaching the daily goal of 10,000 steps.\n"
                }
            }
        }
        
        if analysis == "Based on your health data:\n\n" {
            return "I don't have enough health data to provide an analysis. Please make sure your health data is being recorded correctly."
        }
        
        return analysis
    }

    func fetchHealthData() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample] else {
                return
            }
            let heartRates = results.map { HealthSample(value: $0.quantity.doubleValue(for: HKUnit(from: "count/min")), date: $0.startDate) }
            DispatchQueue.main.async {
                self.sendHealthData(heartRates: heartRates, hrvs: [], steps: [])
            }
        }

        let hrvQuery = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample] else {
                return
            }
            let hrvs = results.map { HealthSample(value: $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)), date: $0.startDate) }
            DispatchQueue.main.async {
                self.sendHealthData(heartRates: [], hrvs: hrvs, steps: [])
            }
        }

        let stepCountQuery = HKSampleQuery(sampleType: stepCountType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample] else {
                return
            }
            let steps = results.map { HealthSample(value: $0.quantity.doubleValue(for: HKUnit.count()), date: $0.startDate) }
            DispatchQueue.main.async {
                self.sendHealthData(heartRates: [], hrvs: [], steps: steps)
            }
        }

        healthStore.execute(heartRateQuery)
        healthStore.execute(hrvQuery)
        healthStore.execute(stepCountQuery)
    }
}