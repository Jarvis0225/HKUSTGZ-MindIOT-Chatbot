import Foundation

struct HealthSample: Identifiable, Codable {
    let id: String
    let value: Double
    let date: Date // 修改为 Date 类型

    init(id: String = UUID().uuidString, value: Double, date: Date) {
        self.id = id
        self.value = value
        self.date = date
    }
}
