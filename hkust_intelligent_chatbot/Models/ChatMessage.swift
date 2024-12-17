import Foundation

struct ChatMessage: Identifiable, Equatable, Codable {
    let id: String
    let content: String
    let isFromAI: Bool
    let healthData: HealthData?
    let timestamp: Date
    
    struct HealthData: Codable {
        let heartRates: [HealthSample]
        let hrvs: [HealthSample]
        let steps: [HealthSample]
    }
    
    init(id: String = UUID().uuidString, 
         content: String, 
         isFromAI: Bool, 
         healthData: HealthData? = nil,
         timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isFromAI = isFromAI
        self.healthData = healthData
        self.timestamp = timestamp
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 用于持久化存储的编码方法
    func encode() -> Data? {
        try? JSONEncoder().encode(self)
    }
    
    // 从持久化存储解码的方法
    static func decode(from data: Data) -> ChatMessage? {
        try? JSONDecoder().decode(ChatMessage.self, from: data)
    }
}