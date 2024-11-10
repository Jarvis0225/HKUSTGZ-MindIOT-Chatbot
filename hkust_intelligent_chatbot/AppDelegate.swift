//
//  AppDelegate.swift
//  hkust_intelligent_chatbot
//  this file is use to registry the background tasks.
//  suggested not to set the time span too short!

import UIKit
import BackgroundTasks
import HealthKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    let healthStore = HKHealthStore()
    var heartRates: [HealthSample] = []
    var hrvs: [HealthSample] = []

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerBackgroundTasks()
        scheduleAppRefresh()
        return true
    }

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.yourapp.fetchHeartRate", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.yourapp.fetchHeartRate")
        request.earliestBeginDate = Date().addingTimeInterval(60 * 60) // 1 hour in seconds
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("无法提交后台任务: \(error)")
        }
    }

    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh() // Reschedule next task

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let operation = BlockOperation {
            self.fetchHeartRateData()
            self.fetchHRVData()
        }

        task.expirationHandler = {
            queue.cancelAllOperations()
        }

        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }

        queue.addOperation(operation)
    }

    // Fetch Heart Rate Data in Background
    func fetchHeartRateData() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: twelveHoursAgo, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            guard let results = results as? [HKQuantitySample], error == nil else {
                print("查询心率数据失败: \(String(describing: error))")
                return
            }

            self.heartRates = results.map { sample in
                HealthSample(value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")), date: sample.startDate)
            }

            // Send heart rate data to the cloud
            NetworkManager.shared.sendDataToCloud(data: self.heartRates, endpoint: "<YOUR_HEART_RATE_ENDPOINT>")
        }

        healthStore.execute(query)
    }

    // Fetch HRV Data in Background
    func fetchHRVData() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let now = Date()
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: twelveHoursAgo, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            guard let results = results as? [HKQuantitySample], error == nil else {
                print("查询心率变异性数据失败: \(String(describing: error))")
                return
            }

            self.hrvs = results.map { sample in
                HealthSample(value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)), date: sample.startDate)
            }

            // Send HRV data to the cloud
            NetworkManager.shared.sendDataToCloud(data: self.hrvs, endpoint: "<YOUR_HRV_ENDPOINT>")
        }

        healthStore.execute(query)
    }
}
