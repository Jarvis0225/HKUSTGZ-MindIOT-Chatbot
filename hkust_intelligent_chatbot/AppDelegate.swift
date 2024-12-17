import UIKit
import BackgroundTasks
import HealthKit
import os

class AppDelegate: UIResponder, UIApplicationDelegate {
    let healthStore = HKHealthStore()
    var heartRates: [HealthSample] = []
    var hrvs: [HealthSample] = []
    var steps: [HealthSample] = []

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerBackgroundTasks()
        scheduleAppRefresh()
        requestHealthKitAuthorization()
        os_log("Application launched and background tasks registered.", type: .info)
        return true
    }

    private func requestHealthKitAuthorization() {
        let healthDataToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: healthDataToRead) { success, error in
            if !success {
                os_log("HealthKit authorization failed.", type: .error)
            }
        }
    }

    func registerBackgroundTasks() {
        if UserDefaults.standard.bool(forKey: "backgroundUpdates") {
            print("注册后台任务")
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.agent.fetchHeartRate", using: nil) { task in
                self.handleAppRefresh(task: task as! BGAppRefreshTask)
            }
        } else {
            print("后台更新已禁用，不注册后台任务")
        }
    }

    func scheduleAppRefresh() {
        if UserDefaults.standard.bool(forKey: "backgroundUpdates") {
            print("调度后台任务")
            let request = BGAppRefreshTaskRequest(identifier: "com.agent.fetchHeartRate")
            request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
            
            do {
                try BGTaskScheduler.shared.submit(request)
                print("后台任务已调度")
            } catch {
                print("无法调度后台任务: \(error)")
            }
        } else {
            print("后台更新已禁用，不调度后台任务")
        }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        guard UserDefaults.standard.bool(forKey: "backgroundUpdates") else {
            print("后台更新已禁用，取消任务")
            task.setTaskCompleted(success: true)
            return
        }
        
        print("处理后台刷新任务")
        scheduleAppRefresh() // 重新调度下一个任务

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = BlockOperation {
            os_log("Starting heart rate and HRV data fetch.", type: .info)
            self.fetchHeartRateData()
            self.fetchHRVData()
            self.fetchStepData()
        }

        task.expirationHandler = {
            os_log("Background task expired.", type: .error)
            queue.cancelAllOperations()
        }

        operation.completionBlock = {
            os_log("Background task completed.", type: .info)
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        queue.addOperation(operation)
    }

    func fetchHeartRateData() {
        os_log("Fetching heart rate data...", type: .info)
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: twelveHoursAgo, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            if let error = error {
                os_log("Failed to fetch heart rate data: %{public}@", type: .error, String(describing: error))
                return
            }

            guard let results = results as? [HKQuantitySample] else {
                os_log("No heart rate data available.", type: .error)
                return
            }

            self.heartRates = results.map { sample in
                HealthSample(id: UUID().uuidString,
                             value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")),
                             date: sample.startDate)
            }
            os_log("Fetched heart rate data: %{public}@", type: .info, String(describing: self.heartRates))
        }
    }

    func fetchHRVData() {
        os_log("Fetching HRV data...", type: .info)
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let now = Date()
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: twelveHoursAgo, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            if let error = error {
                os_log("Failed to fetch HRV data: %{public}@", type: .error, String(describing: error))
                return
            }

            guard let results = results as? [HKQuantitySample] else {
                os_log("No HRV data available.", type: .error)
                return
            }

            self.hrvs = results.map { sample in
                HealthSample(id: UUID().uuidString,
                             value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
                             date: sample.startDate)
            }
            os_log("Fetched HRV data: %{public}@", type: .info, String(describing: self.hrvs))
        }
    }

    func fetchStepData() {
        os_log("Fetching step data...", type: .info)
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: twelveHoursAgo, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: stepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            if let error = error {
                os_log("Failed to fetch step data: %{public}@", type: .error, String(describing: error))
                return
            }

            guard let results = results as? [HKQuantitySample] else {
                os_log("No step data available.", type: .error)
                return
            }

            self.steps = results.map { sample in
                HealthSample(id: UUID().uuidString,
                             value: sample.quantity.doubleValue(for: HKUnit.count()),
                             date: sample.startDate)
            }
            os_log("Fetched step data: %{public}@", type: .info, String(describing: self.steps))

            NetworkManager.shared.sendDataToCloud(
                heartRates: self.heartRates,
                hrvs: self.hrvs,
                steps: self.steps
            ) { success, _ in
                if success {
                    os_log("Health data sent successfully", type: .info)
                } else {
                    os_log("Failed to send health data", type: .error)
                }
            }
        }

        healthStore.execute(query)
    }
}
