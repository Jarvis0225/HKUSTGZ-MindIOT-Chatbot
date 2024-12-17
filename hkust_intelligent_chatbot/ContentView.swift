import SwiftUI
import HealthKit
import os

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var heartRates: [HealthSample] = []
    @State private var hrvs: [HealthSample] = []
    @State private var steps: [HealthSample] = []
    @State private var isLoading = false
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    private let healthStore = HKHealthStore()
    private let fetchInterval: TimeInterval = 60 * 60
    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("backgroundUpdates") private var backgroundUpdates = true
    @State private var refreshTimer: Timer?
    @State private var heartRateObserverQuery: HKObserverQuery?
    @State private var hrvObserverQuery: HKObserverQuery?
    @State private var stepsObserverQuery: HKObserverQuery?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 聊天主页面
            NavigationView {
                ChatView(heartRates: heartRates, hrvs: hrvs, steps: steps)
                    .navigationBarTitle("AI Health Assistant", displayMode: .large)
            }
            .tabItem {
                Image(systemName: "message.circle.fill")
                Text("Chat")
            }
            .tag(0)
            
            // 健康状态页面
            NavigationView {
                HealthStatusView(heartRate: heartRates.first?.value ?? 0, hrv: hrvs.first?.value ?? 0, steps: steps.first?.value ?? 0)
                    .navigationTitle("Health Status")
            }
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Health Status")
            }
            .tag(1)
            
            // 健康数据页面
            NavigationView {
                HealthDataView(heartRates: heartRates, hrvs: hrvs, steps: steps, isLoading: $isLoading, onRefresh: {
                    fetchHeartRateData()
                    fetchHRVData()
                    fetchStepsData()
                })
                .navigationTitle("Health Data")
            }
            .tabItem {
                Image(systemName: "heart.fill")
                Text("Health")
            }
            .tag(2)
            
            // 统计分析页面
            NavigationView {
                AnalysisView(heartRates: heartRates, hrvs: hrvs, steps: steps)
                    .navigationTitle("Analysis")
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Stats")
            }
            .tag(3)
            
            // 设置页面
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(4)
        }
        .onAppear {
            requestAuthorization()
        }
        .onDisappear {
            if let heartRateQuery = heartRateObserverQuery {
                healthStore.stop(heartRateQuery)
            }
            if let hrvQuery = hrvObserverQuery {
                healthStore.stop(hrvQuery)
            }
            if let stepsQuery = stepsObserverQuery {
                healthStore.stop(stepsQuery)
            }
        }
        .onChange(of: autoRefresh) { newValue in
            if newValue {
                setupTimers()
            } else {
                refreshTimer?.invalidate()
                refreshTimer = nil
                print("自动刷新已停止")
            }
        }
    }
    
    private func setupTimers() {
        print("设置定时器，间隔: \(fetchInterval) 秒")
        refreshTimer?.invalidate()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: fetchInterval, repeats: true) { [self] _ in
            print("定时器触发，开始获取数据")
            self.fetchHeartRateData()
            self.fetchHRVData()
            self.fetchStepsData()
            
            if selectedTab == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NewHealthDataAvailable"),
                        object: nil,
                        userInfo: ["heartRates": self.heartRates, "hrvs": self.hrvs, "steps": self.steps]
                    )
                }
            }
        }
        
        fetchHeartRateData()
        fetchHRVData()
        fetchStepsData()
    }
    
    private func setupHealthKitObservers() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        heartRateObserverQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { query, completionHandler, error in
            if let error = error {
                print("心率观察者错误: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self.fetchHeartRateData()
            }
            
            completionHandler()
        }
        
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        hrvObserverQuery = HKObserverQuery(sampleType: hrvType, predicate: nil) { query, completionHandler, error in
            if let error = error {
                print("HRV观察者错误: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self.fetchHRVData()
            }
            
            completionHandler()
        }
        
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        stepsObserverQuery = HKObserverQuery(sampleType: stepsType, predicate: nil) { query, completionHandler, error in
            if let error = error {
                print("步数观察者错误: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self.fetchStepsData()
            }
            
            completionHandler()
        }
        
        if let heartRateQuery = heartRateObserverQuery {
            healthStore.execute(heartRateQuery)
            healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
                if let error = error {
                    print("启用心率后台更新失败: \(error.localizedDescription)")
                }
            }
        }
        
        if let hrvQuery = hrvObserverQuery {
            healthStore.execute(hrvQuery)
            healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { success, error in
                if let error = error {
                    print("启用HRV后台更新失败: \(error.localizedDescription)")
                }
            }
        }
        
        if let stepsQuery = stepsObserverQuery {
            healthStore.execute(stepsQuery)
            healthStore.enableBackgroundDelivery(for: stepsType, frequency: .immediate) { success, error in
                if let error = error {
                    print("启用步数后台更新失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func requestAuthorization() {
        // 定义需要读取的数据类型
        let typesToRead: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!
        ]
        
        // 请求授权
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if let error = error {
                print("健康数据授权错误: \(error.localizedDescription)")
                return
            }
            
            if success {
                print("健康数据授权成功")
                DispatchQueue.main.async {
                    self.fetchHeartRateData()
                    self.fetchHRVData()
                    self.fetchStepsData()
                    if self.backgroundUpdates {
                        self.setupHealthKitObservers()
                    }
                }
            } else {
                print("用户拒绝了健康数据访问权限")
            }
        }
    }

    private func fetchHeartRateData() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: heartRateType, 
                                predicate: predicate, 
                                limit: HKObjectQueryNoLimit, 
                                sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("获取心率数据时出错: \(error.localizedDescription)")
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            DispatchQueue.main.async {
                self.heartRates = samples.map { sample in
                    HealthSample(
                        id: UUID().uuidString,
                        value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")),
                        date: sample.startDate
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }

    private func fetchHRVData() {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: hrvType, 
                                predicate: predicate, 
                                limit: HKObjectQueryNoLimit, 
                                sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("获取HRV数据时出错: \(error.localizedDescription)")
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            DispatchQueue.main.async {
                self.hrvs = samples.map { sample in
                    HealthSample(
                        id: UUID().uuidString,
                        value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
                        date: sample.startDate
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }

    private func fetchStepsData() {
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        let query = HKSampleQuery(sampleType: stepsType, 
                                predicate: predicate, 
                                limit: HKObjectQueryNoLimit, 
                                sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("获取步数数据时出错: \(error.localizedDescription)")
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            DispatchQueue.main.async {
                self.steps = samples.map { sample in
                    HealthSample(
                        id: UUID().uuidString,
                        value: sample.quantity.doubleValue(for: HKUnit.count()),
                        date: sample.startDate
                    )
                }
            }
        }
        
        healthStore.execute(query)
    }
}

// 添加健康数据视图
struct HealthDataView: View {
    let heartRates: [HealthSample]
    let hrvs: [HealthSample]
    let steps: [HealthSample]
    @Binding var isLoading: Bool
    let onRefresh: () -> Void
    @State private var isHeartRateExpanded = true
    @State private var isHRVExpanded = true
    @State private var isStepsExpanded = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView(
                    title: "Heart Rate",
                    icon: "heart.fill",
                    iconColor: .red,
                    isExpanded: $isHeartRateExpanded
                ) {
                    VStack {
                        ChartView(data: heartRates, color: .red)
                            .frame(height: 100)
                        StatsView(data: heartRates, unit: "BPM")
                    }
                }
                
                CardView(
                    title: "Heart Rate Variability",
                    icon: "waveform.path.ecg",
                    iconColor: .blue,
                    isExpanded: $isHRVExpanded
                ) {
                    VStack {
                        ChartView(data: hrvs, color: .blue)
                            .frame(height: 100)
                        StatsView(data: hrvs, unit: "ms")
                    }
                }
                
                CardView(
                    title: "Steps",
                    icon: "figure.walk",
                    iconColor: .green,
                    isExpanded: $isStepsExpanded
                ) {
                    VStack {
                        ChartView(data: steps, color: .green)
                            .frame(height: 100)
                        StatsView(data: steps, unit: "steps")
                    }
                }
                
                Button(action: onRefresh) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isLoading ? "Updating..." : "Refresh Data")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
                .padding(.horizontal)
            }
            .padding()
        }
    }
}

// 添加分析视图
struct AnalysisView: View {
    let heartRates: [HealthSample]
    let hrvs: [HealthSample]
    let steps: [HealthSample]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !heartRates.isEmpty || !hrvs.isEmpty {
                    HealthStatusView(
                        heartRate: heartRates.first?.value ?? 0,
                        hrv: hrvs.first?.value ?? 0,
                        steps: steps.first?.value ?? 0
                    )
                }
                StatsView(data: heartRates, unit: "BPM")
                StatsView(data: hrvs, unit: "ms")
                StatsView(data: steps, unit: "steps")
            }
            .padding()
        }
    }
}

// 添加设置视图
struct SettingsView: View {
    @AppStorage("autoRefresh") private var autoRefresh = true
    @AppStorage("backgroundUpdates") private var backgroundUpdates = true
    
    var body: some View {
        List {
            Section(header: Text("Data Collection")) {
                Toggle("Auto Refresh", isOn: $autoRefresh)
                    .onChange(of: autoRefresh) { newValue in
                        NotificationCenter.default.post(
                            name: NSNotification.Name("AutoRefreshChanged"),
                            object: nil,
                            userInfo: ["enabled": newValue]
                        )
                    }
                
                Toggle("Background Updates", isOn: $backgroundUpdates)
                    .onChange(of: backgroundUpdates) { newValue in
                        if newValue {
                            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                                appDelegate.registerBackgroundTasks()
                                appDelegate.scheduleAppRefresh()
                            }
                        }
                    }
            }
            
            Section(header: Text("Research Info")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (Research Build)")
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Text("Researchers")
                    Spacer()
                    Text("Jarvis LI & Yanying Zhu")
                        .foregroundColor(.gray)
                }
                
                Link("Contact Jarvis LI", 
                     destination: URL(string: "mailto:jli801@connect.hkust-gz.edu.cn")!)
                
                Link("Contact Yanying Zhu", 
                     destination: URL(string: "mailto:zhu_yanying@foxmail.com")!)
            }
            
            Section(header: Text("Legal")) {
                NavigationLink("Terms of Service") {
                    LegalView(title: "Terms of Service", content: termsOfService)
                }
                
                NavigationLink("Privacy Policy") {
                    LegalView(title: "Privacy Policy", content: privacyPolicy)
                }
                
                NavigationLink("Research Disclaimer") {
                    LegalView(title: "Research Disclaimer", content: researchDisclaimer)
                }
            }
            
            Section(header: Text("About")) {
                Text("This application is developed for academic research purposes at HKUST-GZ. It is designed to study the relationship between heart rate metrics and health status using AI-powered analysis.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Section(footer: Text(" 2024 HKUST-GZ. For research purposes only.\nIntelligent Health Monitor Research Project v1.0.0")) {
                EmptyView()
            }
        }
    }
}

// 法律文本
let termsOfService = """
Terms of Service

Last updated: March 2024

1. Research Purpose
This application is developed solely for academic research purposes at the Hong Kong University of Science and Technology (Guangzhou).

2. License
This application is licensed for research and non-commercial use only.

3. Restrictions
You may not:
- Use the data or application for commercial purposes
- Redistribute the application
- Modify or reverse engineer the application

4. Disclaimer
This app is a research tool and not intended for medical diagnosis.

For research inquiries:
Contact: jli801@connect.hkust-gz.edu.cn
"""

let privacyPolicy = """
Privacy Policy

Last updated: March 2024

1. Data Collection and Usage
- Health data is collected through Apple HealthKit for research purposes
- Data is used for academic research only
- All data collection complies with HKUST-GZ research protocols

2. Data Protection
- Data is encrypted and stored securely
- Access is limited to authorized researchers
- Data anonymization protocols are in place

3. Research Participant Rights
- You can withdraw from the study at any time
- You can request your data to be deleted
- You have access to your collected data

For privacy concerns:
Contact: jli801@connect.hkust-gz.edu.cn
"""

let researchDisclaimer = """
Research Disclaimer

This application is part of an academic research project at HKUST-GZ investigating the relationship between heart rate metrics and health status using artificial intelligence.

Research Purpose:
- Study heart rate and HRV patterns
- Develop AI-based health monitoring systems
- Advance understanding of cardiovascular health indicators

Limitations:
- This is a research tool, not a medical device
- Results should not be used for medical diagnosis
- Consult healthcare professionals for medical advice

Research Contact:
Jarvis LI
HKUST-GZ
Email: jli801@connect.hkust-gz.edu.cn
"""
