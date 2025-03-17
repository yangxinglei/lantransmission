import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import 'device_state.dart';

class Services extends ChangeNotifier {
  // 继承 ChangeNotifier
  static final ValueNotifier<List<String>> deviceListNotifier = ValueNotifier(
    [],
  ); // 设备列表
  static const String broadcastAddress = "255.255.255.255";
  static late int communicationPort;
  static late int broadcastPort;
  static ServerSocket? _serverSocket;
  static RawDatagramSocket? _broadcastSocket;
  static RawDatagramSocket? _listenSocket;
  static final Logger logger = Logger(); // 创建一个 logger 实例
  static final Map<String, DateTime> activeDevices = {}; // 记录设备最后一次广播时间
  // 记录已建立的连接
  static final Map<String, Socket> activeConnections =
      {}; // key: 设备 IP, value: 连接的 Socket
  static final StreamController<void> _chatUpdateController =
      StreamController<void>.broadcast();

  static Stream<void> get chatUpdateStream => _chatUpdateController.stream;
  static String sendfileState = "ready";

  static void notifyChatUpdated() {
    _chatUpdateController.add(null); // 发送通知
  }

  Services() {
    initialize(); // 初始化时加载端口
    ChatLogger();
    updateSettings();

    SettingsManager().addListener(updateSettings); // 监听 SettingsManager 变化
  }
  static void updateSettings() {
    if (communicationPort != SettingsManager().communicationPort) {
      communicationPort = SettingsManager().communicationPort;
      restartTcpServer();
    }
    if (broadcastPort != SettingsManager().broadcastPort) {
      broadcastPort = SettingsManager().broadcastPort;
      restartBroadcastAndListen();
    }

    //notifyListeners();  // 通知 UI 更新
  }

  @override
  void dispose() {
    SettingsManager().removeListener(updateSettings); // 取消监听，防止内存泄漏
    super.dispose();
  }

  /// **初始化，加载端口号**
  static Future<void> initialize() async {
    broadcastPort = await SettingsScreen.getBroadcastPort();
    communicationPort = await SettingsScreen.getCommunicationPort();
  }

  static void startPeriodicBroadcast() {
    // 每 5 秒广播一次设备信息
    Timer.periodic(Duration(seconds: 5), (Timer timer) {
      broadcastDeviceInfo();
    });
  }

  /// 获取本机正确的局域网 IP
  static Future<String?> getLocalIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> ipList = [];

    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 &&
            (addr.address.startsWith('192.') ||
                addr.address.startsWith('10.') ||
                addr.address.startsWith('172.'))) {
          ipList.add(addr.address);
        }
      }
    }
    if (prefs.getString('localIP') != null) {
      return prefs.getString('localIP');
    } else {
      String? defaultIp;
      for (var ip in ipList) {
        if (ip.startsWith('192.168')) {
          defaultIp = ip;
          break; // 找到符合条件的第一个 IP，直接退出循环
        }
      }

      if (defaultIp == null) {
        for (var ip in ipList) {
          if (ip.startsWith('192.')) {
            defaultIp = ip;
            break;
          }
        }
      }

      if (defaultIp == null) {
        for (var ip in ipList) {
          if (ip.startsWith('10.')) {
            defaultIp = ip;
            break;
          }
        }
      }

      if (defaultIp == null) {
        for (var ip in ipList) {
          if (ip.startsWith('172.')) {
            defaultIp = ip;
            break;
          }
        }
      }
      return defaultIp;
    }
  }

  static void addLog(String log) {
    final deviceState = DeviceState(); // 获取单例实例
    deviceState.addLog(log); // 调用 addLog 方法
  }

  static void broadcastDeviceInfo() async {
    String? localIP = await getLocalIP();
    if (localIP == null) {
      addLog("❌ 无法获取本机局域网 IP");
      return;
    }
    if (_broadcastSocket == null) {
      try {
        _broadcastSocket = await RawDatagramSocket.bind(
          InternetAddress(localIP),
          broadcastPort,
        );
        _broadcastSocket!.broadcastEnabled = true;
        addLog("📡 广播初始化完成");
      } catch (e) {
        addLog("❌ 绑定广播端口失败: $e");
        return;
      }
    }

    String computerName = await SettingsScreen.getDeviceName();
    var jsonMessage = jsonEncode({
      "devicetype": "lantrans_device",
      "device": computerName,
      "IP": localIP,
    });

    _broadcastSocket!.send(
      utf8.encode(jsonMessage),
      InternetAddress(broadcastAddress),
      broadcastPort,
    );
  }

  static void listenForDeviceBroadcasts() async {
    if (_listenSocket == null) {
      try {
        _listenSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4,
          broadcastPort,
        );
      } catch (e) {
        addLog("❌ 绑定广播监听端口失败: $e");
        await Future.delayed(Duration(seconds: 5));
      }
    }

    _listenSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = _listenSocket!.receive();
        if (datagram != null) {
          String deviceIp = datagram.address.address;
          String deviceInfo = utf8.decode(datagram.data);

          try {
            var jsonData = jsonDecode(deviceInfo);
            if (jsonData["devicetype"] != "lantrans_device") return;

            String uniqueDevice = "${jsonData["device"]}：$deviceIp";
            if (!activeDevices.containsKey(uniqueDevice)) {
              addLog("📡 发现新设备：${jsonData["device"]}：${jsonData["IP"]}");
              activeDevices[uniqueDevice] = DateTime.now();
              // 更新设备列表
              deviceListNotifier.value = activeDevices.keys.toList();
            }
            activeDevices[uniqueDevice] = DateTime.now();
          } catch (e) {
            addLog("❌ 解析 JSON 失败: $e");
          }
        }
      }
    });

    //addLog("👂 设备监听已启动");

    // 清理离线设备
    Timer.periodic(Duration(seconds: 60), (timer) {
      _removeOfflineDevices();
    });
  }

  static Future<void> stopBroadcastAndListen() async {
    _broadcastSocket?.close();
    _broadcastSocket = null;

    _listenSocket?.close();
    _listenSocket = null;

    addLog("🔴 广播和监听服务已停止");
  }

  static Future<void> restartBroadcastAndListen() async {
    await stopBroadcastAndListen();
    listenForDeviceBroadcasts();
    addLog("广播和监听服务已重启");
  }

  /// **清理离线设备**
  static void _removeOfflineDevices() {
    DateTime now = DateTime.now();
    activeDevices.removeWhere((device, lastSeen) {
      return now.difference(lastSeen).inSeconds > 60;
    });

    // 更新设备列表
    deviceListNotifier.value = activeDevices.keys.toList();
  }

  /// 开启 TCP 服务器监听（让其他设备可以连接）
  static Future<void> startTcpServer() async {
    String? localIP = await getLocalIP(); // 自动获取正确的 LAN IP
    if (localIP == null) {
      addLog("❌ 无法获取本机局域网 IP，TCP 服务器启动失败");
      return;
    }
    final deviceState = DeviceState();
    _serverSocket = await ServerSocket.bind(
      InternetAddress(localIP), // 绑定到正确的 LAN IP
      communicationPort,
      shared: true,
    );
    logger.i("🌍 设备 TCP 服务器启动，等待连接...");
    addLog("🌍 设备 TCP 服务器启动，等待连接...");

    _serverSocket?.listen((Socket client) {
      String clientIp = client.remoteAddress.address;
      logger.i("✅ 设备已连接: $clientIp");
      addLog("✅ 设备已连接: $clientIp");
      activeConnections[clientIp] = client;
      int expectedFileSize = 0;
      String? fileName;
      File? file;
      IOSink? fileSink;
      int receivedBytes = 0;
      int logIndex = -1;
      //client.close();

      client.listen(
        (data) async {
          if (expectedFileSize == 0) {
            String message = utf8.decode(data);

            var jsonData = jsonDecode(message);
            if (jsonData["type"] == "message") {
              addLog("📩 收到消息: $message");
              // 记录聊天内容
              await ChatLogger.saveChatLog(
                jsonData["device"],
                await SettingsScreen.getDeviceName(),
                jsonData["device"],
                "[收到消息]${jsonData["content"]}",
              );
              notifyChatUpdated(); // 发送聊天更新通知
            } else if (jsonData["type"] == "fileask") {
              fileName = jsonData["content"];
              expectedFileSize = jsonData["fileSize"];
              addLog("📥 准备接收文件: $fileName ($expectedFileSize 字节)");
              String filePath = await ChatLogger.saveReceivedFilePath(
                jsonData["content"],
              );
              file = File(filePath);
              fileSink = file!.openWrite();
              // ✅ 发送确认消息
              var jsonMsg = jsonEncode({
                "device": await SettingsScreen.getDeviceName(),
                "type": "fileack",
                "content": "",
              });
              client.add(utf8.encode(jsonMsg));
              await client.flush();
              // 🎯 初始化进度日志并记录索引
              addLog("📥 文件接收中: $fileName - 0.00%");

              receivedBytes = 0;
            } else if (jsonData["type"] == "fileack") {
              sendfileState = "ack";
            }
          } else {
            if (fileSink == null) {
              addLog("❌ 错误：fileSink 为空，文件接收异常");
              return;
            }

            fileSink?.add(data);
            //await fileSink?.flush(); // 确保数据写入文件
            receivedBytes += data.length;
            // ✅ 计算进度和速度
            double progress = (receivedBytes / expectedFileSize) * 100;

            // ✅ 实时更新进度条
            logIndex = deviceState.logNotifier.value.length - 1;
            deviceState.logNotifier.value = List.from(
              deviceState.logNotifier.value,
            );
            deviceState.logNotifier.value[logIndex] =
                "📥 文件接收中: $fileName - ${progress.toStringAsFixed(2)}% ";
            if (receivedBytes >= expectedFileSize) {
              await fileSink?.close();
              addLog("✅ 文件接收完成: $fileName");
              await ChatLogger.saveChatLog(
                deviceState.talkermane,
                await SettingsScreen.getDeviceName(),
                deviceState.talkermane,
                "[收到文件]$fileName",
              );
              notifyChatUpdated(); // 发送聊天更新通知
              expectedFileSize = 0;
              fileName = null;
              fileSink = null;
              receivedBytes = 0;
              sendfileState = "ready";
            }
          }
        },
        onDone: () async {
          if (receivedBytes < expectedFileSize) {
            addLog("❌ 文件接收不完整: $fileName$receivedBytes");
          }

          logger.i("📴 连接关闭");
          addLog("📴 连接关闭");
          client.destroy();
          activeConnections.remove(clientIp); // 连接断开时移除
        },
        onError: (error) {
          addLog("❌ 连接错误: $error");
          client.destroy();
          activeConnections.remove(clientIp);
        },
      );
    });
  }

  static Future<void> stopTcpServer() async {
    await _serverSocket?.close();
    _serverSocket = null;
    activeConnections.forEach((ip, socket) {
      socket.destroy(); // 断开所有活动连接
    });
    activeConnections.clear(); // 清空连接列表
    addLog("❌ 服务器已停止，所有设备连接已断开");
  }

  static Future<void> restartTcpServer() async {
    await stopTcpServer();
    await startTcpServer();
    addLog("TCP服务已重启");
  }

  /// 连接到设备
  static Future<void> connectToDevice(String ip, int port) async {
    if (activeConnections.containsKey(ip)) {
      addLog("⚡ 已连接到 $ip，复用现有连接");
      return;
    }
    if (!deviceListNotifier.value.any((device) => device.contains(ip))) {
      addLog("未发现 $ip");
      return;
    }
    final deviceState = DeviceState();
    try {
      Socket socket = await Socket.connect(ip, port);
      activeConnections[ip] = socket; // 记录连接
      logger.i("🔗 连接成功: $ip:$port");
      addLog("🔗 连接成功: $ip:$port");

      int expectedFileSize = 0;
      String? socketfileName;
      File? socketfile;
      IOSink? socketfileSink;
      int socketreceivedBytes = 0;
      late String socketmessage;
      late Map<String, dynamic> jsonData;
      int logIndex = -1;
      socket.listen(
        (data) async {
          if (expectedFileSize == 0) {
            socketmessage = utf8.decode(data);
            jsonData = jsonDecode(socketmessage);
            if (jsonData["type"] == "fileack") {
              sendfileState = "ack";
            } else if (jsonData["type"] == "message") {
              addLog("📩 收到消息: $socketmessage");
              // 记录聊天内容
              await ChatLogger.saveChatLog(
                jsonData["device"],
                await SettingsScreen.getDeviceName(),
                jsonData["device"],
                "[收到消息]${jsonData["content"]}",
              );
              notifyChatUpdated(); // 发送聊天更新通知
            } else if (jsonData["type"] == "fileask") {
              socketfileName = jsonData["content"];
              expectedFileSize = jsonData["fileSize"];
              addLog("📥 准备接收文件: $socketfileName ($expectedFileSize 字节)");
              String filePath = await ChatLogger.saveReceivedFilePath(
                jsonData["content"],
              );
              socketfile = File(filePath);
              socketfileSink = socketfile!.openWrite();
              // ✅ 发送确认消息
              var jsonMsg = jsonEncode({
                "device": await SettingsScreen.getDeviceName(),
                "type": "fileack",
                "content": "",
              });
              socket.add(utf8.encode(jsonMsg));
              await socket.flush();
              // 🎯 初始化进度日志并记录索引
              addLog("📥 文件接收中: $socketfileName - 0.00%");

              socketreceivedBytes = 0;
            }
          } else {
            if (socketfileSink == null) {
              addLog("❌ 错误：fileSink 为空，文件接收异常");
              return;
            }

            socketfileSink?.add(data);
            //await socketfileSink?.flush(); // 确保数据写入文件
            socketreceivedBytes += data.length;
            // ✅ 计算进度和速度
            double progress = (socketreceivedBytes / expectedFileSize) * 100;

            // ✅ 实时更新进度条
            logIndex = deviceState.logNotifier.value.length - 1;
            deviceState.logNotifier.value = List.from(
              deviceState.logNotifier.value,
            );
            deviceState.logNotifier.value[logIndex] =
                "📥 文件接收中: $socketfileName - ${progress.toStringAsFixed(2)}% ";

            if (socketreceivedBytes >= expectedFileSize) {
              await socketfileSink?.close();
              addLog("✅ 文件接收完成: $socketfileName");
              await ChatLogger.saveChatLog(
                jsonData["device"],
                await SettingsScreen.getDeviceName(),
                jsonData["device"],
                "[收到文件]$socketfileName",
              );
              notifyChatUpdated(); // 发送聊天更新通知
              expectedFileSize = 0;
              socketfileName = null;
              socketfileSink = null;
              socketreceivedBytes = 0;
              sendfileState = "ready";
            }
          }
        },
        onDone: () {
          logger.i("📴 连接关闭");
          addLog("📴 连接关闭");
          socket.destroy();
          activeConnections.remove(ip); // 连接断开时移除
        },
        onError: (error) {
          logger.e("❌ 连接错误: $error");
          addLog("❌ 连接错误: $error");
          socket.destroy();
          activeConnections.remove(ip); // 连接断开时移除
        },
      );

      //socket.writeln("HELLO, I AM ${InternetAddress.anyIPv4.address}");
    } catch (e) {
      logger.e("❌ 连接失败: $e");
      addLog("❌ 连接失败: $e");
    }
  }

  /// **断开设备连接**
  static void disconnectDevice(String ip) {
    if (activeConnections.containsKey(ip)) {
      activeConnections[ip]?.destroy();
      activeConnections.remove(ip);
      addLog("🔌 已断开设备 $ip 的连接");
    }
  }

  static Future<void> sendMessageToDevice(
    String deviceIp,
    String message,
  ) async {
    if (deviceIp == "") {
      addLog("⚠️ 未选择有效的设备");
      return;
    }
    if (!activeConnections.containsKey(deviceIp)) {
      addLog("⚠️ 设备 $deviceIp 未连接，无法发送消息");
      return;
    }
    final deviceState = DeviceState();
    try {
      Socket? socket = activeConnections[deviceIp];
      if (socket != null) {
        //Socket socket = await Socket.connect(deviceIp, communicationPort);
        var jsonMessage = jsonEncode({
          "device": await SettingsScreen.getDeviceName(),
          "type": "message",
          "content": message,
        });
        socket.writeln(jsonMessage);
        await socket.flush();
        // 记录消息
        await ChatLogger.saveChatLog(
          await SettingsScreen.getDeviceName(),
          deviceState.talkermane,
          await SettingsScreen.getDeviceName(),
          "[发送消息] $message",
        );
        notifyChatUpdated(); // 发送聊天更新通知

        addLog("📤 发送消息到 $deviceIp: $message");
      } else {}
    } catch (e) {
      addLog("❌ 发送失败: $e");
    }
  }

  static Future<bool> waitForAck() async {
    // 假设我们等待确认的时间为 10 秒
    int timeoutDuration = 10;
    int elapsedTime = 0;

    // 等待 sendfileState 变为 "ack"
    while (sendfileState != "ack" && elapsedTime < timeoutDuration) {
      await Future.delayed(Duration(seconds: 1)); // 每秒检查一次
      elapsedTime++;
      if (elapsedTime >= 10) {
        sendfileState = "ready";
        throw Exception("❌ 超时：未收到接收端确认");
      }
    }

    // 返回是否成功收到确认
    return sendfileState == "ack"; // 如果状态为 "ack"，则返回 true
  }

  static Future<void> sendFileToDevice(
    String deviceIp,
    File file,
    String localDeviceName,
  ) async {
    if (deviceIp == "") {
      addLog("⚠️ 未选择有效的设备");
      return;
    }
    if (!activeConnections.containsKey(deviceIp)) {
      addLog("⚠️ 设备 $deviceIp 未连接，无法发送文件");
      return;
    }
    if (sendfileState != "ready") {
      addLog("服务正忙，无法发送当前文件");
      return;
    }
    final deviceState = DeviceState();
    int fileSize = await file.length();
    // 默认发送延时（自适应会根据 flush 时间调整）
    Duration sendDelay = Duration(milliseconds: 10);
    // 发送 JSON 头部，包含文件名和大小
    var jsonMessage = jsonEncode({
      "device": await SettingsScreen.getDeviceName(),
      "type": "fileask",
      "content": path.basename(file.path),
      "fileSize": fileSize,
    });
    try {
      Socket? socket = activeConnections[deviceIp];
      if (socket != null) {
        //Socket socket = await Socket.connect(deviceIp, communicationPort);
        socket.writeln(jsonMessage);
        await socket.flush();
        addLog("📤 正在发送文件: ${path.basename(file.path)} - 0.00% (0.00 MB/s)");
        // 向对方发送文件准备信息，并等待对方确认
        bool confirmationReceived = await waitForAck();
        if (confirmationReceived) {
          // **接收端确认后，开始发送文件**
          int logIndex = -1; // 记录日志索引

          logIndex = deviceState.logNotifier.value.length - 1;
          int sentBytes = 0;

          Stream<List<int>> fileStream = file.openRead();
          Stopwatch stopwatch1 = Stopwatch()..start(); // 计时器计算速度
          Stopwatch stopwatch2 = Stopwatch()..start(); // 计时器计算速度
          await for (List<int> chunk in fileStream) {
            stopwatch1.reset();
            socket.add(chunk);
            await socket.flush(); // 确保数据刷新
            sentBytes += chunk.length;
            int flushTime = stopwatch1.elapsedMilliseconds;
            // 根据 flush 所需时间调整发送延时
            if (flushTime > 50) {
              // 网络繁忙，延时加长
              sendDelay = Duration(milliseconds: sendDelay.inMilliseconds + 5);
            } else if (flushTime < 10 && sendDelay.inMilliseconds > 5) {
              // 网络空闲，适当减少延时
              sendDelay = Duration(milliseconds: sendDelay.inMilliseconds - 2);
            }
            // **计算进度**
            double progress = sentBytes / fileSize * 100;

            // **计算传输速度**
            double speedMBs =
                (sentBytes / (1024 * 1024)) /
                (stopwatch2.elapsedMilliseconds / 1000);
            // **更新 UI 或日志**
            deviceState.logNotifier.value = List.from(
              deviceState.logNotifier.value,
            ); // 重新赋值，更新UI
            deviceState.logNotifier.value[logIndex] =
                "📤 正在发送文件: ${path.basename(file.path)} - ${progress.toStringAsFixed(2)}% (${speedMBs.toStringAsFixed(2)} MB/s)";
            //deviceState.logNotifier.notifyListeners(); // **刷新 UI**
          }

          // **3️⃣ 传输完成**
          addLog(
            "✅ 文件发送完成: ${path.basename(file.path)} (${fileSize ~/ (1024 * 1024)} MBytes)",
          );

          /*
      // 发送文件内容（保证原格式）
      file.openRead().listen(
        (data) {
          socket.add(data); // 发送原始二进制数据
        },
        onDone: () async {
          await socket.flush();
          addLog("📤 发送文件到: ${file.path}→ $deviceIp");
          
        },
      );
    */ ///////
          // 记录聊天日志
          await ChatLogger.saveChatLog(
            localDeviceName,
            deviceState.talkermane,
            localDeviceName,
            "[发送文件] ${path.basename(file.path)}",
          );
          notifyChatUpdated(); // 发送聊天更新通知
        } else {
          addLog("等待超时或对方接收异常");
        }
        sendfileState = "ready";
      } else {}
    } catch (e) {
      addLog("❌ 文件发送失败: $e");
    }
  }
}
