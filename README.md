# lantransmission
A tool for sending files and messages on a local area network

# 局域网文件传输与即时通讯工具

## 概述
本项目是一款基于 Dart + Flutter 开发的跨平台（Windows、macOS、Linux、Android、iOS）局域网文件传输与即时通讯工具。通过局域网通信，无需依赖互联网即可实现高效、快速的文件传输和文本消息交流。

## 功能特点

### 1. 设备发现
- 通过广播端口进行设备发现
- 显示所有在线设备列表

### 2. 文件传输
- 支持文件的发送与接收
- 保留文件原格式
- 实时显示文件传输进度
- 可设置文件保存路径

### 3. 即时通讯
- 文本消息的发送与接收
- 每个设备创建独立的聊天记录文件
- 支持历史聊天记录的查看

### 4. 配置管理
- 可配置广播端口和通讯端口
- 自定义文件保存路径
- 设置本机设备名称

## 通信协议
采用基于 JSON 格式的数据结构进行通信，包括以下字段：
1. **device**: 本机名称
2. **type**: 消息类型（如 message、fileack、fileask 等）
3. **content**: 消息内容

## 技术架构
- 前端：Dart + Flutter
- TCP 文件传输
- 数据存储：SharedPreferences (本地配置存储)

## 平台支持
- Windows
- macOS
- Linux
- Android
- iOS

## 安装与运行

### 环境依赖
- Flutter SDK
- Dart 环境

### 安装步骤
1. 克隆项目：
```bash
git clone https://github.com/yangxinglei/lantransmission.git
```

2. 安装依赖：
```bash
flutter pub get
```

3. 运行项目：
```bash
flutter run
```

## 使用说明
1. 启动应用
2. 在“设备”页选择目标设备
3. 发送文本消息或选择文件进行传输
4. 查看传输进度和日志信息
5. 在“设置”页可配置端口号、文件保存路径及本机名称

## 目录结构
```
lan_transfer_tool/
│
├── lib/            # 主程序文件
│   ├── screens/    # UI 界面
│   ├── services/   # 通信服务
│   
│
├── assets/         # 静态资源
├── test/           # 单元测试
└── README.md
```


## 贡献
欢迎提出 Issue 或提交 Pull Request，共同完善本项目。

## 开源协议
Apache-2.0 

