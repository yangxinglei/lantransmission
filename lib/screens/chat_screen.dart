import 'dart:async';
//import 'settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:lantransmission/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import '../services/device_state.dart';
import '../services/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/chat.dart';
//import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String device;
  final Function(String message) sendMessage;
  final Function(File file) sendFile;
  const ChatScreen({
    required this.device,
    required this.sendMessage,
    required this.sendFile,
    super.key,
  });
  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<void>? _chatUpdateSubscription;
  StreamSubscription<FileSystemEvent>? _fileWatchSubscription; // 新增
  List<String> messages = []; // 存储聊天消息
  late File logFile;

  @override
  void initState() {
    super.initState();

    _initializeChatLogFile(); // 异步初始化聊天记录文件
    // 监听聊天记录更新
    _chatUpdateSubscription = Services.chatUpdateStream.listen((_) {
      _loadChatLog(); // 设备有新消息或文件时，自动加载聊天记录
    });
  }

  /// **异步初始化聊天记录文件**
  void _initializeChatLogFile() async {
    final deviceState = context.read<DeviceState>();
    String logPath = await ChatLogger.getChatLogPath(
      await SettingsScreen.getDeviceName(),
      deviceState.talkermane,
    );
    setState(() {
      logFile = File(logPath);
    });
    // 监听文件变化
    _fileWatchSubscription = logFile.watch().listen((event) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _loadChatLog();
          setState(() {}); // 强制刷新 UI
        }
      });
    });

    _loadChatLog(); // 加载历史聊天记录
  }

  @override
  void dispose() {
    _chatUpdateSubscription?.cancel();
    _fileWatchSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device != widget.device) {
      _updateChatLogFile(); // 设备切换后重新加载聊天记录
    }
  }

  /// **异步更新聊天记录文件**
  void _updateChatLogFile() async {
    final deviceState = context.read<DeviceState>();
    String logPath = await ChatLogger.getChatLogPath(
      await SettingsScreen.getDeviceName(),
      deviceState.talkermane,
    );
    setState(() {
      logFile = File(logPath);
    });
    _loadChatLog(); // 重新加载聊天记录
  }

  void _loadChatLog() {
    if (logFile.existsSync()) {
      if (mounted) {
        setState(() {
          messages = logFile.readAsLinesSync();
        });
        _scrollToBottom();
      }
    }
  }

  void _sendTextMessage() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      widget.sendMessage(text);
      //setState(() {});
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
      if (mounted && _scrollController.hasClients) {
        // 添加检查
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
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
