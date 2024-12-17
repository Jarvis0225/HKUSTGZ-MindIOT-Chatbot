# iOS 健康数据监测 App 零基础部署指南

## 📖 目录
1. [项目介绍](#1-项目介绍)
2. [前期准备](#2-前期准备)
3. [环境配置](#3-环境配置)
4. [项目部署](#4-项目部署)
5. [功能使用](#5-功能使用)
6. [常见问题](#6-常见问题)
7. [注意事项](#7-注意事项)

## 1. 项目介绍

### 1.1 功能概述
- 实时监测心率和心率变异性(HRV)数据
- 数据可视化展示（图表和统计）
- 健康状态评估和建议
- 数据分享功能
- 自动数据同步到云端

### 1.2 系统要求
- macOS 12.0 或更高版本
- Xcode 14.0 或更高版本
- iOS 15.0 或更高版本
- watchOS 8.0 或更高版本（如果使用 Apple Watch）

## 2. 前期准备

### 2.1 必需设备
- Mac 电脑（必需）：用于开发和部署
- iPhone（必需）：运行应用的设备
- Apple Watch（强烈推荐）：用于采集心率数据
- USB 数据线：用于连接 iPhone 和 Mac

### 2.2 账号准备
1. Apple ID
   - 必须是付费开发者账号或免费账号
   - 如果是免费账号，App 只能在设备上运行 7 天
   - 注册地址：https://appleid.apple.com
   - ⚠️ 注意：请使用稳定的网络环境注册

2. GitHub 账号
   - 用于下载和管理代码
   - 注册地址：https://github.com
   - 建议使用常用邮箱注册

### 2.3 网络环境
- 稳定的互联网连接
- VPN 服务（必需，用于数据上传）
- 建议使用家庭 Wi-Fi 而不是移动数据

## 3. 环境配置

### 3.1 安装 Xcode
1. 打开 Mac App Store
   - 点击 Dock 栏中的 App Store 图标
   - 或使用 Spotlight（Command + 空格）搜索 "App Store"

2. 搜索并安装 Xcode
   - 在搜索框输入 "Xcode"
   - 点击 "获取" 或云朵图标
   - 文件大小约 12GB，请确保有足够空间
   - ⚠️ 下载时间可能很长，建议使用稳定网络

3. 首次启动设置
   - 打开 Xcode 后等待组件安装
   - 同意许可协议
   - 输入 Mac 管理员密码

### 3.2 安装命令行工具
1. 打开终端
   ```bash
   Command + 空格，输入 "终端" 或 "Terminal"
   ```

2. 安装 Homebrew
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   - 过程中需要输入管理员密码
   - 密码输入时不会显示字符，这是正常的

3. 安装 Git
   ```bash
   brew install git
   ```

### 3.3 配置 Git
```bash
git config --global user.name "你的GitHub用户名"
git config --global user.email "你的邮箱"
```

## 4. 项目部署

### 4.1 下载项目
1. 创建工作目录
   ```bash
   cd ~/Desktop
   mkdir Projects
   cd Projects
   ```

2. 克隆项目
   ```bash
   git clone https://github.com/your-username/hkust-gz_intelligent_chat.git
   cd hkust-gz_intelligent_chat
   ```

### 4.2 Xcode 项目配置
1. 打开项目
   - 双击 `hkust_intelligent_chatbot.xcodeproj`
   - 或在 Xcode 中选择 File > Open

2. 签名配置
   - 点击左侧导航器中的项目文件
   - 选择 TARGETS 下的 hkust_intelligent_chatbot
   - 在 Signing & Capabilities 标签页：
     * 勾选 "Automatically manage signing"
     * Team 选择你的 Apple ID
     * Bundle Identifier 改为唯一的值（如：com.yourname.healthapp）

3. 添加必要权限
   在 Info.plist 中添加：
   ```xml
   <key>NSHealthShareUsageDescription</key>
   <string>We need access to your health data to monitor your heart rate and HRV.</string>
   <key>NSHealthUpdateUsageDescription</key>
   <string>We need access to your health data to monitor your heart rate and HRV.</string>
   ```

### 4.3 部署到设备
1. 连接 iPhone
   - 使用数据线连接 iPhone 和 Mac
   - 在 iPhone 上点击"信任此电脑"
   - 输入 iPhone 密码

2. 运行项目
   - 在 Xcode 顶部选择你的 iPhone
   - 点击运行按钮（播放图标）
   - 等待编译和安装
   - ⚠️ 首次运行可能需要几分钟

3. 信任开发者证书
   - 在 iPhone 上：
     * 设置 > 通用 > VPN与设备管理
     * 找到开发者应用
     * 点击"信任"

## 5. 功能使用

### 5.1 首次使用设置
1. 健康数据权限
   - 首次启动会请求健康数据访问权限
   - 点击"允许"所有请求的权限
   - 确保在健康 App 中也允许访问

2. Apple Watch 配对
   - 确保 Apple Watch 已正确配对
   - 佩戴 Watch 并确保贴合手腕
   - 等待几分钟让数据同步

### 5.2 主要功能
1. 数据展示
   - 心率数据（上方卡片）
     * 可折叠/展开显示
     * 包含图表和统计信息
     * 显示具体数值和时间
   
   - HRV数据（下方卡片）
     * 同样支持折叠/展开
     * 包含详细统计信息
     * 时间序列展示

2. 数据获取
   - 自动获取：每小时自动更新
   - 手动获取：点击"Fetch Data"按钮
   - 获取成功会有提示和振动反馈

3. 健康状态评估
   - 实时评估健康状态
   - 提供个性化建议
   - 异常情况会有警告提示

4. 数据分享
   - 支持生成报告图片
   - 可分享到其他应用
   - 包含完整统计信息

### 5.3 使用建议
1. 数据采集
   - 保持 Apple Watch 电量充足
   - 确保表带适当紧度
   - 避免剧烈运动时采集数据

2. 网络连接
   - 使用 VPN 确保数据上传
   - 建议使用稳定 Wi-Fi
   - 定期检查数据同步状态

3. 后台运行
   - 允许应用后台刷新
   - 不要强制关闭应用
   - 定期检查数据更新

## 6. 常见问题

### 6.1 部署问题
1. Xcode 编译错误
   ```
   问题：出现红色错误提示
   解决：
   1. Xcode > Product > Clean Build Folder
   2. Xcode > File > Packages > Reset Package Caches
   3. 重新编译
   ```

2. 证书错误
   ```
   问题：提示证书无效
   解决：
   1. Xcode > Preferences > Accounts
   2. 删除并重新添加 Apple ID
   3. 重新生成证书
   ```

3. 安装失败
   ```
   问题：无法安装到设备
   解决：
   1. 检查设备是否解锁
   2. 重新信任开发者证书
   3. 重启 Xcode 和设备
   ```

### 6.2 运行问题
1. 无数据显示
   ```
   原因：
   - 权限未正确设置
   - Apple Watch 未配对
   - 数据未同步
   
   解决：
   1. 检查健康 App 权限
   2. 确认 Watch 配对状态
   3. 等待数据同步（约5-10分钟）
   ```

2. 数据上传失败
   ```
   原因：
   - 网络连接问题
   - VPN 未开启
   - 服务器响应超时
   
   解决：
   1. 检查网络连接
   2. 开启并确认 VPN 状态
   3. 多尝试几次
   ```

3. 应用崩溃
   ```
   解决步骤：
   1. 完全关闭应用
   2. 重启设备
   3. 重新安装应用
   4. 如果问题持续，检查系统日志
   ```

### 6.3 性能问题
1. 电池消耗
   ```
   优化建议：
   - 调整自动更新频率
   - 关闭不必要的后台刷新
   - 保持 Watch 充足电量
   ```

2. 内存占用
   ```
   解决方法：
   - 定期清理应用缓存
   - 不保留过多历史数据
   - 必要时重启应用
   ```

## 7. 注意事项

### 7.1 数据安全
- 所有健康数据都经过加密
- 不要在不信任的网络环境使用
- 定期备份重要数据

### 7.2 隐私保护
- 不要分享敏感健康数据
- 注意保护个人信息
- 遵守相关法律法规

### 7.3 使用限制
- 仅供研究和参考使用
- 不作为医疗诊断依据
- 遇到健康问题及时就医

## 联系与支持

### 技术支持
- GitHub Issues: [项目地址]
- Email: [支持邮箱]
- 响应时间：24-48小时

### 问题反馈
1. 反馈时请提供：
   - 系统版本信息
   - 错误截图
   - 复现步骤
   - 日志信息

2. 获取日志方法：
   ```
   1. Xcode > Window > Devices and Simulators
   2. 选择设备
   3. 点击查看设备日志
   ```

## 版本历史
- v1.0.0 (2024-03-21)
  * 初始版本发布
  * 基本功能实现
  * 用户界面优化

## 许可证
[添加许可证信息]
