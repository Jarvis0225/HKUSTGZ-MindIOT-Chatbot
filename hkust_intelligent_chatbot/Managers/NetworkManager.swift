import Foundation
import os

class NetworkManager {
    static let shared = NetworkManager()
    private init() {
        // 从环境变量或配置文件中读取 URL
        #if DEBUG
        serverUrl = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:3000/api/health-feedback"
        #else
        // 在发布版本中使用正式服务器
        serverUrl = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? ""
        assert(!serverUrl.isEmpty, "Production API URL must be configured")
        #endif
    }
    
    private let serverUrl: String
    private var messageHandler: ((ChatMessage) -> Void)?
    
    func addMessageHandler(_ handler: @escaping (ChatMessage) -> Void) {
        messageHandler = handler
    }
    
    func sendMessage(_ message: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: serverUrl) else {
            print("错误: 无效的 URL")
            completion(false, nil)
            return
        }
        
        let messageData: [String: Any] = [
            "type": "chat",
            "message": message,
            "require_analysis": true
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: messageData)
            
            print("发送消息到服务器...")
            if let requestData = request.httpBody,
               let requestString = String(data: requestData, encoding: .utf8) {
                print("请求数据: \(requestString)")
            }
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    print("请求失败: \(error.localizedDescription)")
                    completion(false, "抱歉，服务器暂时无法访问，请稍后再试。")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("服务器响应状态码: \(httpResponse.statusCode)")
                }
                
                guard let data = data else {
                    print("没有接收到数据")
                    completion(false, nil)
                    return
                }
                
                // 打印原始响应
                if let responseString = String(data: data, encoding: .utf8) {
                    print("收到原始响应: \(responseString)")
                }
                
                // 尝试解析响应
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("解析的 JSON: \(json)")
                        
                        if let result = json["result"] as? String {
                            completion(true, result)
                            // 创建并发送 AI 消息
                            if let messageHandler = self?.messageHandler {
                                let aiMessage = ChatMessage(
                                    content: result,
                                    isFromAI: true,
                                    healthData: nil
                                )
                                messageHandler(aiMessage)
                            }
                        } else if let message = json["message"] as? String {
                            completion(true, message)
                            // 创建并发送 AI 消息
                            if let messageHandler = self?.messageHandler {
                                let aiMessage = ChatMessage(
                                    content: message,
                                    isFromAI: true,
                                    healthData: nil
                                )
                                messageHandler(aiMessage)
                            }
                        } else {
                            completion(false, "服务器返回的数据格式不正确")
                        }
                    }
                } catch {
                    print("JSON 解析错误: \(error.localizedDescription)")
                    completion(false, "解析服务器响应时出错")
                }
            }
            
            task.resume()
            
        } catch {
            print("准备请求数据失败: \(error.localizedDescription)")
            completion(false, nil)
        }
    }
    
    func sendDataToCloud(heartRates: [HealthSample], hrvs: [HealthSample], steps: [HealthSample], completion: @escaping (Bool, String?) -> Void = { _, _ in }) {
        print("=== 开始发送数据到云端 ===")
        
        // 评估数据状态
        let (requiresIntervention, deviceMessage) = needsAIIntervention(heartRates: heartRates, hrvs: hrvs, steps: steps)
        
        // 如果有设备相关的消息，直接返回
        if let message = deviceMessage {
            print("检测到设备或数据同步问题: \(message)")
            completion(true, message)
            // 创建并发送系统消息
            if let messageHandler = messageHandler {
                let systemMessage = ChatMessage(
                    content: message,
                    isFromAI: true,
                    healthData: nil
                )
                messageHandler(systemMessage)
            }
            return
        }
        
        // 如果不需要干预，返回本地分析结果
        if !requiresIntervention {
            print("健康数据正常，无需 AI 干预")
            let analysis = generateLocalAnalysis(heartRates: heartRates, hrvs: hrvs, steps: steps)
            completion(true, analysis)
            // 创建并发送本地分析消息
            if let messageHandler = messageHandler {
                let healthData = ChatMessage.HealthData(
                    heartRates: heartRates,
                    hrvs: hrvs,
                    steps: steps
                )
                let analysisMessage = ChatMessage(
                    content: analysis,
                    isFromAI: true,
                    healthData: healthData
                )
                messageHandler(analysisMessage)
            }
            return
        }
        
        guard let url = URL(string: serverUrl) else {
            print("错误: 无效的 URL")
            completion(false, nil)
            return
        }
        
        // 修改请求数据格式
        let payload: [String: Any] = [
            "type": "health_data",
            "require_analysis": true,
            "health_data": [
                "heart_rates": heartRates.map { [
                    "value": $0.value,
                    "timestamp": ISO8601DateFormatter().string(from: $0.date)
                ]},
                "hrvs": hrvs.map { [
                    "value": $0.value,
                    "timestamp": ISO8601DateFormatter().string(from: $0.date)
                ]},
                "steps": steps.map { [
                    "value": $0.value,
                    "timestamp": ISO8601DateFormatter().string(from: $0.date)
                ]}
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            print("发送数据到服务器...")
            if let requestData = request.httpBody,
               let requestString = String(data: requestData, encoding: .utf8) {
                print("请求数据: \(requestString)")
            }
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    print("请求失败: \(error.localizedDescription)")
                    // 服务器请求失败时，返回本地分析结果
                    if let localAnalysis = self?.generateLocalAnalysis(heartRates: heartRates, hrvs: hrvs, steps: steps) {
                        let analysisWithNote = localAnalysis + "\n\n(Note: This is a local analysis as the server is currently unavailable)"
                        completion(true, analysisWithNote)
                        // 创建并发送本地分析消息
                        if let messageHandler = self?.messageHandler {
                            let healthData = ChatMessage.HealthData(
                                heartRates: heartRates,
                                hrvs: hrvs,
                                steps: steps
                            )
                            let analysisMessage = ChatMessage(
                                content: analysisWithNote,
                                isFromAI: true,
                                healthData: healthData
                            )
                            messageHandler(analysisMessage)
                        }
                    }
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("服务器响应状态码: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 500 {
                        // 服务器内部错误时，返回本地分析结果
                        if let localAnalysis = self?.generateLocalAnalysis(heartRates: heartRates, hrvs: hrvs, steps: steps) {
                            let analysisWithNote = localAnalysis + "\n\n(Note: Server is experiencing issues, this is a local analysis)"
                            completion(true, analysisWithNote)
                            // 创建并发送本地分析消息
                            if let messageHandler = self?.messageHandler {
                                let healthData = ChatMessage.HealthData(
                                    heartRates: heartRates,
                                    hrvs: hrvs,
                                    steps: steps
                                )
                                let analysisMessage = ChatMessage(
                                    content: analysisWithNote,
                                    isFromAI: true,
                                    healthData: healthData
                                )
                                messageHandler(analysisMessage)
                            }
                        }
                        return
                    }
                }
                
                guard let data = data else {
                    print("没有接收到数据")
                    completion(false, nil)
                    return
                }
                
                // 打印原始响应
                if let responseString = String(data: data, encoding: .utf8) {
                    print("收到原始响应: \(responseString)")
                }
                
                // 尝试解析响应
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("解析的 JSON: \(json)")
                        
                        if let result = json["result"] as? String {
                            completion(true, result)
                            // 创建并发送 AI 消息
                            if let messageHandler = self?.messageHandler {
                                let healthData = ChatMessage.HealthData(
                                    heartRates: heartRates,
                                    hrvs: hrvs,
                                    steps: steps
                                )
                                let aiMessage = ChatMessage(
                                    content: result,
                                    isFromAI: true,
                                    healthData: healthData
                                )
                                messageHandler(aiMessage)
                            }
                        } else if let message = json["message"] as? String {
                            completion(true, message)
                            // 创建并发送 AI 消息
                            if let messageHandler = self?.messageHandler {
                                let healthData = ChatMessage.HealthData(
                                    heartRates: heartRates,
                                    hrvs: hrvs,
                                    steps: steps
                                )
                                let aiMessage = ChatMessage(
                                    content: message,
                                    isFromAI: true,
                                    healthData: healthData
                                )
                                messageHandler(aiMessage)
                            }
                        } else {
                            // 响应格式不符合预期时，返回本地分析
                            if let localAnalysis = self?.generateLocalAnalysis(heartRates: heartRates, hrvs: hrvs, steps: steps) {
                                completion(true, localAnalysis)
                                // 创建并发送本地分析消息
                                if let messageHandler = self?.messageHandler {
                                    let healthData = ChatMessage.HealthData(
                                        heartRates: heartRates,
                                        hrvs: hrvs,
                                        steps: steps
                                    )
                                    let analysisMessage = ChatMessage(
                                        content: localAnalysis,
                                        isFromAI: true,
                                        healthData: healthData
                                    )
                                    messageHandler(analysisMessage)
                                }
                            }
                        }
                    } else {
                        // JSON解析失败时，返回本地分析
                        if let localAnalysis = self?.generateLocalAnalysis(heartRates: heartRates, hrvs: hrvs, steps: steps) {
                            completion(true, localAnalysis)
                            // 创建并发送本地分析消息
                            if let messageHandler = self?.messageHandler {
                                let healthData = ChatMessage.HealthData(
                                    heartRates: heartRates,
                                    hrvs: hrvs,
                                    steps: steps
                                )
                                let analysisMessage = ChatMessage(
                                    content: localAnalysis,
                                    isFromAI: true,
                                    healthData: healthData
                                )
                                messageHandler(analysisMessage)
                            }
                        }
                    }
                } catch {
                    print("JSON 解析错误: \(error.localizedDescription)")
                    // JSON解析错误时，返回本地分析
                    if let localAnalysis = self?.generateLocalAnalysis(heartRates: heartRates, hrvs: hrvs, steps: steps) {
                        completion(true, localAnalysis)
                        // 创建并发送本地分析消息
                        if let messageHandler = self?.messageHandler {
                            let healthData = ChatMessage.HealthData(
                                heartRates: heartRates,
                                hrvs: hrvs,
                                steps: steps
                            )
                            let analysisMessage = ChatMessage(
                                content: localAnalysis,
                                isFromAI: true,
                                healthData: healthData
                            )
                            messageHandler(analysisMessage)
                        }
                    }
                }
            }
            
            task.resume()
            
        } catch {
            print("准备请求数据失败: \(error.localizedDescription)")
            completion(false, nil)
        }
    }
    
    // 生成本地分析结果
    private func generateLocalAnalysis(heartRates: [HealthSample], hrvs: [HealthSample], steps: [HealthSample]) -> String {
        let avgHeartRate = heartRates.map(\.value).reduce(0, +) / Double(max(1, heartRates.count))
        let avgHRV = hrvs.map(\.value).reduce(0, +) / Double(max(1, hrvs.count))
        let totalSteps = steps.map(\.value).reduce(0, +)
        
        var analysis = "Health Data Analysis:\n\n"
        
        // 心率分析
        analysis += "Heart Rate Analysis:\n"
        analysis += "Average: \(String(format: "%.1f", avgHeartRate)) BPM\n"
        if avgHeartRate > 100 {
            analysis += "Your heart rate is elevated. Consider relaxation techniques.\n"
        } else if avgHeartRate < 60 {
            analysis += "Your heart rate is lower than normal. Monitor for any symptoms.\n"
        } else {
            analysis += "Your heart rate is within normal range.\n"
        }
        
        // HRV分析
        analysis += "\nHeart Rate Variability Analysis:\n"
        analysis += "Average: \(String(format: "%.1f", avgHRV)) ms\n"
        if avgHRV < 50 {
            analysis += "Your HRV is lower than optimal. This might indicate stress.\n"
        } else {
            analysis += "Your HRV is in a healthy range.\n"
        }
        
        // 步数分析
        analysis += "\nStep Count Analysis:\n"
        analysis += "Total Steps: \(Int(totalSteps))\n"
        if totalSteps < 5000 {
            analysis += "You might want to increase your daily activity.\n"
        } else if totalSteps >= 10000 {
            analysis += "Great job! You've reached the recommended daily step goal.\n"
        } else {
            analysis += "You're on your way to reaching the daily step goal.\n"
        }
        
        // 建议
        analysis += "\nRecommendations:\n"
        if avgHeartRate > 100 || avgHRV < 50 {
            analysis += "- Practice deep breathing exercises\n"
            analysis += "- Ensure adequate rest\n"
            analysis += "- Consider stress management techniques\n"
        } else {
            analysis += "- Continue maintaining your healthy lifestyle\n"
            analysis += "- Regular exercise and good sleep habits\n"
        }
        
        if totalSteps < 5000 {
            analysis += "- Try to incorporate more walking into your daily routine\n"
            analysis += "- Take short walks during breaks\n"
        }
        
        return analysis
    }
    
    private func needsAIIntervention(heartRates: [HealthSample], hrvs: [HealthSample], steps: [HealthSample]) -> (Bool, String?) {
        // 检查是否有数据
        if heartRates.isEmpty && hrvs.isEmpty && steps.isEmpty {
            return (false, "No health data detected. Please make sure your Apple Watch is properly worn and synced with the Health app.")
        }
        
        // 计算平均值
        let avgHeartRate = heartRates.map(\.value).reduce(0, +) / Double(max(1, heartRates.count))
        let avgHRV = hrvs.map(\.value).reduce(0, +) / Double(max(1, hrvs.count))
        
        // 检查数据是否为0（可能是设备未佩戴）
        if avgHeartRate == 0 && avgHRV == 0 {
            return (false, "Please ensure your Apple Watch is properly worn and check the Health app for data sync.")
        }
        
        // 定义真正的异常标准
        let isHeartRateAbnormal = avgHeartRate < 60 || avgHeartRate > 100
        let isHRVAbnormal = avgHRV < 50  // HRV低于50ms通常被认为需要关注
        
        return (isHeartRateAbnormal || isHRVAbnormal, nil)
    }
}
