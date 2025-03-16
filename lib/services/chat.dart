import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../screens/settings_screen.dart';


class ChatLogger extends ChangeNotifier{
  static final String logDirectory = "chat_logs"; // 聊天记录存储路径
  static String receivedFilesDirectory = ""; // 接收文件存储路径
  ChatLogger(){

    initparameters();
    SettingsManager().addListener(initparameters);  // 监听 SettingsManager 变化
  }
  
  Future<void> initparameters() async {
    receivedFilesDirectory = await SettingsScreen.getSavePath();
    notifyListeners();  // 触发 UI 更新
  }
  // 确保目录存在
  static Future<String> _ensureDirectoryExists(String directory) async {
    final appDir = await getApplicationDirectory();
    Directory dir = Directory('$appDir/$directory');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }

  static Future<String> getApplicationDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path; // 例如 Android 上会返回类似 '/data/data/com.yourapp/files'
  }

  static Future<void> _ensureFileExists(String filePath) async {
    File file = File(filePath);
    if (await file.exists()) {
      //print("✅ 文件已存在: $filePath");
    } else {
      // print("⚠️ 文件不存在，正在创建...");
      await file.create(recursive: true); // 递归创建文件（如果文件夹不存在）
      //print("✅ 文件创建成功: $filePath");
    }
  }

  // 获取当前时间戳
  static String _timestamp() {
    return DateTime.now().toLocal().toString().substring(
      0,
      19,
    ); // 只保留 yyyy-MM-dd HH:mm:ss
  }

  // 生成聊天记录文件路径
  static Future<String> getChatLogPath(String deviceA, String deviceB) async {
    String directoryPath = await _ensureDirectoryExists(logDirectory);
    List<String> devices = [deviceA, deviceB]..sort(); // 确保文件名顺序固定
    String chatlogfile = "$directoryPath/${devices[0]}_${devices[1]}.txt";
    await _ensureFileExists(chatlogfile);
    return chatlogfile;
  }

  // 记录聊天消息
  static Future<void> saveChatLog(
    String deviceA,
    String deviceB,
    String sender,
    String message,
  ) async {
    String filePath = await getChatLogPath(deviceA, deviceB);
    String logEntry = "[${_timestamp()}] $sender: $message\n";
    File(
      filePath,
    ).writeAsStringSync(logEntry, mode: FileMode.append, encoding: utf8);
    //print(filePath);
  }

  // 生成文件路径
  static Future<String> saveReceivedFilePath(String fileName) async {
    String filePath = "$receivedFilesDirectory/$fileName";
    return filePath;
  }
}
