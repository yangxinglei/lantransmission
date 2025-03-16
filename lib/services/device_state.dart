import 'package:flutter/material.dart';

class DeviceState extends ChangeNotifier {
  // 单例实例
  static final DeviceState _instance = DeviceState._internal();

  // 工厂构造函数
  factory DeviceState() {
    return _instance;
  }

  // 私有构造函数
  DeviceState._internal();

  String? _selectedDevice;
  String talkermane = "";
  ValueNotifier<List<String>> logNotifier = ValueNotifier<List<String>>([]);

  void addLog(String log) {
    final logs = logNotifier.value;
    if (logs.length >= 100) {
      logs.removeAt(0); // 移除最早的日志
    }
    logNotifier.value = [...logs, log];
    notifyListeners(); // 通知监听者状态已更新
  }

  String? get selectedDevice => _selectedDevice;

  void selectDevice(String? device) {
    _selectedDevice = device;
    notifyListeners(); // 通知监听者状态已更新
  }

  void setTalkerName(String name) {
    talkermane = name;
    notifyListeners(); // 通知监听者状态已更新
  }

}