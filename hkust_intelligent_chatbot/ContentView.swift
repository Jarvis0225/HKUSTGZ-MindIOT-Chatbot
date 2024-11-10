//  ContentView.swift
//  hkust_intelligent_chatbot
import SwiftUI
import HealthKit


// set the time span to 1 hour beacuse of the real-time requirement and the usage of battery~
// high usage of battery or high frequency of getting data will cause ban of the backgroud task
struct ContentView: View {
    @State private var heartRates: [HealthSample] = []
    @State private var hrvs: [HealthSample] = []
    private let healthStore = HKHealthStore()
//    time span of time interval when the app is running in the front stage
    private let fetchInterval: TimeInterval = 60 * 60 // 1 hour in seconds

    var body: some View {
        VStack {
            Text("Heart rate")
                .font(.largeTitle)
                .padding()

            List(heartRates) { sample in
                VStack(alignment: .leading) {
                    Text("心率: \(sample.value, specifier: "%.1f") 次/分钟")
                    Text("时间: \(formattedDate(sample.date))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Text("Heart Rate Variation")
                .font(.title2)
                .padding(.top)

            List(hrvs) { sample in
                VStack(alignment: .leading) {
                    Text("HRV: \(sample.value, specifier: "%.1f") 毫秒")
                    Text("时间: \(formattedDate(sample.date))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            // Button to fetch data immediately
            Button(action: {
                fetchHeartRateData()
                fetchHRVData()
            }) {
                Text("Get data")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            requestAuthorizationAndFetchData()
            startFetchingTimer()
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
// strat the interval
    private func startFetchingTimer() {
        Timer.scheduledTimer(withTimeInterval: fetchInterval, repeats: true) { _ in
            fetchHeartRateData()
            fetchHRVData()
        }
    }
// important, get the authorization
    private func requestAuthorizationAndFetchData() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let typesToRead: Set = [heartRateType, hrvType]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if success {
                fetchHeartRateData()
                fetchHRVData()
            } else {
                print("授权失败: \(String(describing: error))")
            }
        }
    }
//  get data. if you want more data, add the functions here!
    private func fetchHeartRateData() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: oneHourAgo, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            guard let results = results as? [HKQuantitySample], error == nil else {
                print("查询心率数据失败: \(String(describing: error))")
                return
            }

            DispatchQueue.main.async {
                self.heartRates = results.map { sample in
                    HealthSample(value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")), date: sample.startDate)
                }
                // Send heart rate data to the cloud
                NetworkManager.shared.sendDataToCloud(data: self.heartRates, endpoint: "<YOUR_HEART_RATE_ENDPOINT>")
            }
        }

        healthStore.execute(query)
    }

    private func fetchHRVData() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let now = Date()
        let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: oneHourAgo, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            guard let results = results as? [HKQuantitySample], error == nil else {
                print("查询心率变异性数据失败: \(String(describing: error))")
                return
            }

            DispatchQueue.main.async {
                self.hrvs = results.map { sample in
                    HealthSample(value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)), date: sample.startDate)
                }
                // Send HRV data to the cloud
                NetworkManager.shared.sendDataToCloud(data: self.hrvs, endpoint: "<YOUR_HRV_ENDPOINT>")
            }
        }

        healthStore.execute(query)
    }
}
#Preview {
    ContentView()
}
