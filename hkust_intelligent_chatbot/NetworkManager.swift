//  NetworkManager.swift
//  hkust_intelligent_chatbot

import Foundation

// Struct to hold health data and make it Codable for JSON encoding
struct HealthSample: Identifiable, Codable {
    let id = UUID()
    let value: Double
    let date: Date
}

class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    // Function to send health data to a cloud endpoint
    // this param called endpoint is the url~
    func sendDataToCloud(data: [HealthSample], endpoint: String) {
        guard let url = URL(string: endpoint) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode the HealthSample array to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let jsonData = try encoder.encode(data)
            request.httpBody = jsonData
        } catch {
            print("Failed to encode data: \(error)")
            return
        }

        // Execute the network request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to send data: \(error)")
            } else {
                print("Data sent successfully.")
            }
        }
        task.resume()
    }
}
