# HKUST 智能健康聊天机器人

## 项目简介

这是一个基于 iOS 平台的智能健康聊天应用，结合了 AI 对话能力和实时健康数据分析。通过与 Apple HealthKit 的深度集成，应用能够实时监测用户的健康数据，并提供个性化的健康建议和分析。

## 主要功能

### 1. 智能对话系统
- 自然语言交互：支持用户使用自然语言进行健康相关的对话
- 上下文理解：能够理解并保持对话上下文，提供连贯的交互体验
- 情感识别：通过表情选择器支持用户表达情感状态

### 2. 健康数据监测
- **心率监测**
  - 实时心率数据采集
  - 异常心率检测和提醒
  - 心率趋势分析和可视化
  
- **心率变异性(HRV)分析**
  - HRV 实时监测
  - 压力水平评估
  - 身体恢复能力分析
  
- **运动追踪**
  - 步数统计
  - 活动量分析
  - 运动建议生成

### 3. 智能健康分析
- 健康数据异常检测
- 个性化健康建议生成
- 健康趋势分析和预警
- 生活方式改善建议

### 4. 用户界面特性
- 现代化的 SwiftUI 界面设计
- 流畅的动画效果
- 直观的健康数据可视化
- 深色模式支持

## 技术架构

### 项目结构
```
App
├── Models（数据模型）
│   ├── ChatMessage.swift     # 聊天消息模型
│   ├── HealthSample.swift    # 健康数据样本模型
│   └── HealthData.swift      # 健康数据聚合模型
│
├── Views（视图层）
│   ├── ChatView/
│   │   ├── ChatView.swift           # 主聊天界面
│   │   └── EmojiPickerView.swift    # 表情选择器
│   │
│   └── MessageView.swift    # 消息气泡视图
│
└── Managers（管理层）
    ├── ChatManager.swift     # 聊天管理器
    ├── NetworkManager.swift  # 网络请求管理
    └── HealthKitManager.swift # 健康数据管理
```

### 核心组件说明

#### 1. 数据模型层
- **ChatMessage**
  - 消息内容管理
  - 发送时间记录
  - 消息类型标识
  - 健康数据关联

- **HealthSample**
  - 健康数据采样
  - 数据类型分类
  - 时间戳记录
  - 数值存储

- **HealthData**
  - 健康数据聚合
  - 数据分析功能
  - 趋势计算
  - 异常检测

#### 2. 视图层
- **ChatView**
  - 消息列表展示
  - 用户输入处理
  - 健康数据展示
  - 动画效果管理

- **MessageView**
  - 消息气泡布局
  - 健康数据可视化
  - 交互动画
  - 样式定制

#### 3. 管理层
- **ChatManager**
  - 消息状态管理
  - 对话逻辑处理
  - 消息队列控制
  - 会话管理

- **NetworkManager**
  - API 通信处理
  - 数据传输加密
  - 错误处理
  - 重试机制

- **HealthKitManager**
  - HealthKit 授权管理
  - 健康数据读取
  - 数据同步
  - 隐私保护

## 系统要求

- iOS 15.0 或更高版本
- Xcode 13.0 或更高版本
- Swift 5.5 或更高版本
- 有效的 Apple 开发者账号（用于 HealthKit 功能）

## 安装和配置

### 1. 获取项目
```bash
git clone https://github.com/yourusername/hkust-intelligent-chatbot.git
cd hkust-intelligent-chatbot
```

### 2. Xcode 配置
1. 打开项目
```bash
open hkust_intelligent_chatbot.xcodeproj
```

2. 配置开发者账号
   - 在 Xcode 中选择项目
   - 选择目标设备
   - 在 "Signing & Capabilities" 中配置开发者账号

3. 配置 HealthKit
   - 添加 HealthKit capability
   - 在 Info.plist 中配置所需的健康数据类型
   - 设置隐私描述文案

### 3. 运行项目
- 选择目标设备（真机或模拟器）
- 点击运行按钮或使用快捷键 ⌘R

## 配置说明

### 环境变量配置
1. 复制配置模板文件：
```bash
cp Config.template.xcconfig Config.xcconfig
```

2. 编辑 `Config.xcconfig` 文件，设置你的环境变量：
```
API_BASE_URL = your_api_url_here
```

3. 确保 `Config.xcconfig` 已添加到 `.gitignore` 中，避免敏感信息泄露

### 安全注意事项
- 不要将包含实际 API URL 的配置文件提交到版本控制系统
- 在团队内部通过安全渠道共享配置信息
- 定期更新和轮换 API 密钥（如果使用）
- 在生产环境中使用 HTTPS 进行所有网络通信

## 隐私和安全

### 数据安全
- 所有健康数据本地处理
- 使用标准加密协议
- 不永久存储敏感信息
- 遵循 Apple 隐私准则

### 用户授权
- 首次使用需要健康数据访问授权
- 可随时在设置中修改授权
- 明确的数据使用说明
- 透明的隐私政策

## 开发指南

### 代码规范
- 遵循 Swift 标准编码规范
- 使用清晰的命名约定
- 添加适当的代码注释
- 保持代码模块化

### 版本控制
- 使用 Git 进行版本控制
- 遵循 Git Flow 工作流
- 提交信息要清晰明确
- 保持合理的分支管理

### 测试
- 单元测试覆盖核心功能
- UI 测试保证界面稳定
- 性能测试确保流畅运行
- 定期进行集成测试

## 贡献指南

1. Fork 项目仓库
2. 创建特性分支 (`git checkout -b feature/新特性`)
3. 提交更改 (`git commit -m '添加新特性'`)
4. 推送到分支 (`git push origin feature/新特性`)
5. 提交 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 LICENSE 文件

## 致谢

- 感谢香港科技大学（广州）实践研究项目（G01RF000051）及广州市高等教育教学质量与教学改革工程项目（2024YBJG077）的项目支持和指导
- 感谢 Apple HealthKit 提供的健康数据集成能力
- 感谢 SwiftUI 框架提供的现代化 UI 开发能力

## 联系方式

如有问题或建议，请通过以下方式联系我们：
- 项目 Issues
- 电子邮件：[jli801@connect.hkust-gz.edu.cn]
