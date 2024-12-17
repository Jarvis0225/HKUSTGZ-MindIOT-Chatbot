import SwiftUI

struct ChatView: View {
    @StateObject private var chatManager = ChatManager()
    let heartRates: [HealthSample]
    let hrvs: [HealthSample]
    let steps: [HealthSample]
    @State private var messageText = ""
    @State private var showEmojiPicker = false
    @State private var isTyping = false
    @State private var showingOptions = false
    @State private var lastAIResponseTime: Date?
    @State private var lastHeartRatesCount = 0
    @State private var lastHRVsCount = 0
    
    // 预设的快捷回复
    let quickReplies = [
        "😊 How's my health today?",
        "❤️ Check my heart rate",
        "🏃‍♂️ How many steps today?",
        "🌟 Give me some health tips",
        "📊 Show my weekly progress"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 聊天记录显示区域
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatManager.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                }
                .onChange(of: chatManager.messages) { _ in
                    if let lastMessage = chatManager.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .gesture(DragGesture().onChanged { _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                 to: nil, from: nil, for: nil)
                })
            }
            
            // 快捷回复区域
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quickReplies, id: \.self) { reply in
                        Button(action: {
                            messageText = reply
                            sendMessage()
                        }) {
                            Text(reply)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // 输入区域
            VStack(spacing: 0) {
                Divider()
                HStack(alignment: .bottom, spacing: 8) {
                    // Emoji 选择器按钮
                    Button(action: {
                        showEmojiPicker.toggle()
                    }) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                    }
                    .padding(.bottom, 8)
                    
                    // 文本输入框
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(minHeight: 40)
                        .padding(.vertical, 4)
                    
                    // 发送按钮
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(messageText.isEmpty ? .gray : .blue)
                    }
                    .disabled(messageText.isEmpty)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView(selectedEmoji: $messageText)
        }
        .onAppear {
            print("ChatView appeared")
            print("当前心率数据: \(heartRates.count) 条")
            print("当前HRV数据: \(hrvs.count) 条")
            lastHeartRatesCount = heartRates.count
            lastHRVsCount = hrvs.count
            checkHealthData()
        }
        .onChange(of: heartRates.count) { newCount in
            print("心率数据更新: \(newCount) 条")
            if newCount != lastHeartRatesCount {
                lastHeartRatesCount = newCount
                checkHealthData()
            }
        }
        .onChange(of: hrvs.count) { newCount in
            print("HRV数据更新: \(newCount) 条")
            if newCount != lastHRVsCount {
                lastHRVsCount = newCount
                checkHealthData()
            }
        }
    }
    
    private func checkHealthData() {
        // 检查是否有异常数据需要 AI 分析
        guard !heartRates.isEmpty || !hrvs.isEmpty else {
            print("没有可用的健康数据")
            return
        }
        
        let avgHeartRate = heartRates.map(\.value).reduce(0, +) / Double(max(1, heartRates.count))
        let avgHRV = hrvs.map(\.value).reduce(0, +) / Double(max(1, hrvs.count))
        
        print("平均心率: \(avgHeartRate) BPM")
        print("平均HRV: \(avgHRV) ms")
        
        // 更新ChatManager中的健康数据
        chatManager.sendHealthData(heartRates: heartRates, hrvs: hrvs, steps: steps)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        // 更新ChatManager中的健康数据
        chatManager.sendHealthData(heartRates: heartRates, hrvs: hrvs, steps: steps)
        
        // 发送消息
        chatManager.sendMessage(messageText)
        messageText = ""
        
        // 隐藏键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                     to: nil, from: nil, for: nil)
    }
}

// Emoji选择器视图
struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.presentationMode) var presentationMode
    
    let emojis = ["😊", "😂", "🥰", "😎", "🤔", "👍", "❤️", "💪", "🏃‍♂️", "🎯", 
                  "🌟", "✨", "🎉", "👋", "🤝", "🙌", "👏", "💯", "⭐️", "🔥"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 20) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji += emoji
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(emoji)
                                .font(.system(size: 40))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Emoji")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
