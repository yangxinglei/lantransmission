import 'dart:async';
import 'settings_screen.dart';
import 'package:flutter/material.dart';
import '../services/device_discovey.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceDiscoveryScreen extends StatefulWidget {
  const DeviceDiscoveryScreen({super.key});

  @override
  DeviceDiscoveryScreenState createState() => DeviceDiscoveryScreenState();
}

class DeviceDiscoveryScreenState extends State<DeviceDiscoveryScreen> {
  static final List<String> _favoriteDevices = [];
  static final StreamController<List<String>> _devicecontroller =
      StreamController.broadcast();

  //static Stream<List<String>> get deviceStream => _devicecontroller.stream;

  bool showFavorites = false;
  static String softwareVerion="V1.0.0";
  /// 加载收藏设备（持久化存储）
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteDevices.clear();
      _favoriteDevices.addAll(prefs.getStringList('favoriteDevices') ?? []);
    });
    _devicecontroller.add(_favoriteDevices);
  }

  /// 保存收藏设备（持久化存储）
  static Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteDevices', _favoriteDevices);
  }

  static bool isFavorite(String deviceInfo) {
    return _favoriteDevices.contains(deviceInfo);
  }

  static Future<void> toggleFavorite(
    String deviceInfo,
    StateSetter setStateCallback,
  ) async {
    if (isFavorite(deviceInfo)) {
      _favoriteDevices.remove(deviceInfo);
    } else {
      _favoriteDevices.add(deviceInfo);
    }
    _devicecontroller.add(_favoriteDevices);
    await saveFavorites(); // 保存到本地存储
    // 立即刷新 UI
    setStateCallback(() {});
  }

  List<String> allDevices = []; // 发现的设备列表
  String? selectedDevice;

  // 示例方法：添加日志（你需要在 logger 输出时调用此方法）
  void addLog(String log) {
    logNotifier.value = [...logNotifier.value, log];
  }

  @override
  void initState() {
    super.initState();

    loadFavorites(); // 加载收藏设备
    _initializeDeviceDiscovery(); // 确保初始化完成再进行后续操作
  }

  Future<void> _initializeDeviceDiscovery() async {
    await DeviceDiscovery.initialize(); // 等待初始化完成
    DeviceDiscovery.startPeriodicBroadcast(); // 定时广播本机信息
    DeviceDiscovery.listenForDeviceBroadcasts(); // 监听局域网设备
    DeviceDiscovery.startTcpServer(); // 启动设备连接监听
    SettingsManager().addListener(
      DeviceDiscovery.updateSettings,
    ); // 监听 SettingsManager 变化
    // DeviceDiscovery.notifyListeners();
    // 监听设备流更新
    DeviceDiscovery.deviceStream.listen((devices) {
      setState(() {
        allDevices = devices; // 更新当前设备列表
      });
    });
  }

  void onDeviceSelected(String ip) {
    List<String> parts = ip.split("：");
    ip = parts[1];
    talkermane = parts[0];
    DeviceDiscovery.connectToDevice(ip, DeviceDiscovery.communicationPort, (
      ip,
      port,
      message,
    ) {
      setState(() {
        selectedDevice = ip;
      });
    });
    //addLog("选中了设备: $ip, 开始建立连接...");
  }
  void openReceivedFilesFolder() async{
 String savedPath = await SettingsScreen.getSavePath();

  if (Platform.isWindows) {
    Process.run('explorer', [savedPath]);
  } else if (Platform.isMacOS) {
    Process.run('open', [savedPath]);
  } else if (Platform.isLinux) {
    Process.run('xdg-open', [savedPath]);
  }
}
void showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('帮助'),
      content: const Text('这是一个局域网文件传输和聊天工具。\n\n'
          '1. 设备会自动发现同一局域网中安装了此软件的其他设备。\n'
          '2. 您可以发送消息和文件。\n'
          '3. 点击"设置"可修改端口和文件存储位置。\n'
          '4. 通讯端口号：文件传输和消息使用。\n'
          '5. 广播端口号：广播设备信息用于设备发现。\n'
          '6. 您可以发送消息和文件。\n\n'
          '遇到问题？请访问 GitHub 或联系开发者。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

void showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('关于'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('软件名称: 局域网传输'),
          const SizedBox(height: 5),
          Text('版本号: $softwareVerion'),
          const SizedBox(height: 10),
          const Text('作者:YangXinglei'),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              // 在这里跳转到捐赠页面，比如 PayPal、支付宝等
            },
            icon: const Icon(Icons.favorite, color: Colors.red),
            label: const Text('捐赠开发者'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('局域网通信')),
      body: Column(
        children: [
          // 上方菜单栏
          Container(
            height: 50,
            color: const Color.fromARGB(255, 235, 196, 56),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => Dialog(
                            child: SizedBox(
                              width: 400, // 设置宽度
                              height: 400, // 设置高度
                              child: SettingsScreen(), // 直接显示设置界面
                            ),
                          ),
                    );
                  },
                  icon: const Icon(Icons.settings), // 设置图标
                  label: const Text('设置'),
                ),
                TextButton.icon(
                  onPressed:  openReceivedFilesFolder,
                  icon: const Icon(Icons.folder_sharp), // 文件图标
                  label: const Text('浏览接收文件'),
                ),
                TextButton.icon(
                  onPressed: ()  => showHelpDialog(context),

                  icon: const Icon(Icons.help_outline), // 帮助图标
                  label: const Text('帮助'),
                ),
                TextButton.icon(
                  onPressed: () => showAboutDialog(context),
                  icon: const Icon(Icons.info_outline), // 关于图标
                  label: const Text('关于'),
                ),

                // 你可以添加更多菜单项
              ],
            ),
          ),
          // 中间主要内容：左侧设备列表和右侧聊天界面
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：设备列表
                Container(
                  color: const Color.fromARGB(255, 127, 55, 215),
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Padding(
                      //padding: const EdgeInsets.all(8.0),
                      //child: ElevatedButton(
                      //onPressed: discoverDevices, // 用户点击时开始设备发现
                      //child: const Text('手动广播'),
                      // ),
                      // ),
                      // 设备列表菜单
                      Container(
                        color: Colors.grey[300],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              onPressed:
                                  () => setState(() => showFavorites = false),
                              child: Text(
                                '当前设备',
                                style: TextStyle(
                                  fontWeight:
                                      showFavorites
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                  color:
                                      showFavorites
                                          ? Colors.black
                                          : Colors.blue,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => setState(() => showFavorites = true),
                              child: Text(
                                '收藏设备',
                                style: TextStyle(
                                  fontWeight:
                                      showFavorites
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      showFavorites
                                          ? Colors.blue
                                          : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: const Color.fromARGB(220, 173, 214, 246),
                          child: StreamBuilder<List<String>>(
                            //stream: DeviceDiscovery.deviceStream, // 订阅设备列表流
                            stream:
                                showFavorites
                                    ? _devicecontroller.stream
                                    : DeviceDiscovery.deviceStream, // 选择设备流
                            builder: (context, snapshot) {
                              List<String> devices =
                                  showFavorites
                                      ? (_favoriteDevices.isEmpty
                                          ? []
                                          : _favoriteDevices)
                                      : allDevices;
                              if (devices.isEmpty) {
                                return Center(
                                  child: Text(
                                    showFavorites ? "没有收藏设备" : "未发现设备",
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: devices.length,
                                itemBuilder: (context, index) {
                                  String deviceInfo =
                                      devices[index]; // 设备信息（格式："设备名称：IP"）
                                  List<String> parts = deviceInfo.split("：");
                                  String deviceName = parts[0];
                                  String deviceIp =
                                      parts.length > 1 ? parts[1] : "";
                                  return StatefulBuilder(
                                    builder: (context, setStateListTile) {
                                      bool isFav =
                                          DeviceDiscoveryScreenState.isFavorite(
                                            deviceInfo,
                                          );
                                      return ListTile(
                                        title: Text(
                                          deviceName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          deviceIp,
                                          style: TextStyle(
                                            color: Colors.black87,
                                          ),
                                        ),
                                        selected:
                                            selectedDevice ==
                                            deviceIp, // 选中设备高亮
                                        selectedTileColor: const Color.fromARGB(
                                          255,
                                          12,
                                          241,
                                          210,
                                        ), // 选中设备颜色
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // 收藏按钮
                                            Tooltip(
                                              message: isFav ? "取消收藏" : "添加收藏",
                                              child: IconButton(
                                                icon: Icon(
                                                  isFav
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                ),
                                                onPressed:
                                                    () =>
                                                        DeviceDiscoveryScreenState.toggleFavorite(
                                                          deviceInfo,
                                                          setStateListTile,
                                                        ),
                                              ),
                                            ),
                                            // 连接按钮
                                            Tooltip(
                                              message: "连接到设备",
                                              child: IconButton(
                                                icon: Icon(Icons.link),
                                                onPressed:
                                                    () => onDeviceSelected(
                                                      devices[index],
                                                    ),
                                              ),
                                            ),
                                            // 断开连接按钮
                                            Tooltip(
                                              message: "断开连接",
                                              child: IconButton(
                                                icon: Icon(Icons.link_off),
                                                onPressed:
                                                    () =>
                                                        DeviceDiscovery.disconnectDevice(
                                                          devices[index],
                                                        ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        //onTap: () {
                                        //onDeviceSelected(
                                        // devices[index],
                                        // ); // 点击设备时调用
                                        //},
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 右侧：聊天界面
                Expanded(
                  child:
                      selectedDevice == null
                          ? const Center(child: Text('请选择设备'))
                          : ChatUI(
                            device: selectedDevice!,
                            sendMessage: (message) {
                              // 这里实现你的消息发送逻辑
                              DeviceDiscovery.sendMessageToDevice(
                                selectedDevice!,
                                message,
                              );
                            },
                            sendFile: (file) async {
                              // 这里实现你的文件发送逻辑
                              DeviceDiscovery.sendFileToDevice(
                                selectedDevice!,
                                file,
                                await SettingsScreen.getDeviceName(),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
          // 下方日志显示窗口
          LogWindow(logNotifier: logNotifier),
        ],
      ),
    );
  }
}

class LogWindow extends StatefulWidget {
  final ValueNotifier<List<String>> logNotifier;

  const LogWindow({super.key, required this.logNotifier});

  @override
  State<LogWindow> createState() => _LogWindowState();
}

class _LogWindowState extends State<LogWindow> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.logNotifier.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.logNotifier.removeListener(_scrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      color: Colors.black,
      child: ValueListenableBuilder<List<String>>(
        valueListenable: logNotifier,
        builder: (context, logs, _) {
          return ListView.builder(
            controller: _scrollController, // 绑定滚动控制器
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                child: SelectableText(
                  logs[index],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatUI extends StatefulWidget {
  final String device;
  final Function(String message) sendMessage;
  final Function(File file) sendFile;
  const ChatUI({
    required this.device,
    required this.sendMessage,
    required this.sendFile,
    super.key,
  });
  @override
  ChatUIState createState() => ChatUIState();
}

class ChatUIState extends State<ChatUI> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<void>? _chatUpdateSubscription;

  List<String> messages = []; // 存储聊天消息
  late File logFile;

  @override
  void initState() {
    super.initState();
    _initializeChatLogFile(); // 异步初始化聊天记录文件
    // 监听聊天记录更新
    _chatUpdateSubscription = DeviceDiscovery.chatUpdateStream.listen((_) {
      _loadChatLog(); // 设备有新消息或文件时，自动加载聊天记录
    });
  }

  /// **异步初始化聊天记录文件**
  void _initializeChatLogFile() async {
    String logPath = await ChatLogger.getChatLogPath(
      await SettingsScreen.getDeviceName(),
      talkermane,
    );
    setState(() {
      logFile = File(logPath);
    });
    // 监听文件变化
    logFile.watch().listen((event) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _loadChatLog();
        setState(() {}); // 强制刷新 UI
      });
    });

    _loadChatLog(); // 加载历史聊天记录
  }

  @override
  void dispose() {
    _chatUpdateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatUI oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device != widget.device) {
      _updateChatLogFile(); // 设备切换后重新加载聊天记录
    }
  }

  /// **异步更新聊天记录文件**
  void _updateChatLogFile() async {
    String logPath = await ChatLogger.getChatLogPath(
      await SettingsScreen.getDeviceName(),
      talkermane,
    );
    setState(() {
      logFile = File(logPath);
    });
    _loadChatLog(); // 重新加载聊天记录
  }

  void _loadChatLog() {
    if (logFile.existsSync()) {
      setState(() {
        messages = logFile.readAsLinesSync();
      });
      _scrollToBottom();
    }
  }

  void _sendTextMessage() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      widget.sendMessage(text);
      setState(() {
        //messages.add("你: $text");
      });
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _pickAndSendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      widget.sendFile(file);
      setState(() {
        //messages.add("📂 你发送了文件: ${file.path.split('/').last}");
      });

      _loadChatLog(); // 确保发送后立即更新

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 消息区域
        Expanded(
          child: ListView.builder(
            //children: messages.map((msg) => Text(msg)).toList(),
            controller: _scrollController,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                child: SelectableText(
                  messages[index],
                  style: const TextStyle(fontSize: 14),
                ),
              );
            },
          ),
        ),

        // 输入框和发送按钮
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(hintText: '输入消息'),
                  onSubmitted: (value) => _sendTextMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendTextMessage,
              ),
            ],
          ),
        ),

        // 发送文件按钮，放入一个 Row 左对齐
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _pickAndSendFile,
            ),
          ],
        ),
      ],
    );
  }
}
