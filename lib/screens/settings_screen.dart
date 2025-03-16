import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  /// 获取设置的广播端口、通讯端口和保存路径
  static Future<int> getBroadcastPort() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('broadcastPort') ?? 8800;
  }

  static Future<int> getCommunicationPort() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('communicationPort') ?? 9900;
  }

  static Future<String> getSavePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('savePath') ??
        await SettingsScreenState()._getDefaultDownloadPath();
  }
  static Future<String> getDeviceName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('deviceName') ??  Platform.localHostname;
  }
  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController portController = TextEditingController();
  final TextEditingController broadcastPortController = TextEditingController();
  final TextEditingController deviceNameController = TextEditingController();
  String selectedDirectory = "";
  int broadport = 8800;
  int communicationPort = 9900;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// **获取系统默认下载路径**
  Future<String> _getDefaultDownloadPath() async {
    if (Platform.isAndroid) {
    final directory = await getExternalStorageDirectory(); // 获取外部存储目录
      selectedDirectory='${directory!.parent.parent.parent.parent.path}/Download/LANTransmission';
      Directory dir = Directory(selectedDirectory);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    
      return selectedDirectory;
    } else if (Platform.isIOS) {
      return (await getApplicationDocumentsDirectory()).path; // iOS 仍然使用沙盒目录
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return (await getDownloadsDirectory())?.path ?? "";
    }
    return "";
  }

  /// **读取存储的端口号和文件路径**
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('savePath');
    communicationPort = prefs.getInt('communicationPort') ?? 9900;
    broadport = prefs.getInt('broadcastPort') ?? 8800;
    String deviceName = prefs.getString('deviceName') ?? Platform.localHostname;
    if (savedPath == null || savedPath.isEmpty) {
      // 如果用户没有设置路径，使用默认下载路径
      String defaultPath = await _getDefaultDownloadPath();
      await prefs.setString('savePath', defaultPath);
      savedPath = defaultPath;
    }

    setState(() {
      portController.text =
          prefs.getInt('communicationPort')?.toString() ?? '9900';
      broadcastPortController.text = broadport.toString();
      deviceNameController.text = deviceName;
      selectedDirectory = savedPath!;
    });
  }

  /// 保存端口号
  Future<void> _savePort() async {
    final int? port = int.tryParse(portController.text);
    if (port == null || port <= 0 || port > 65535) {
      _showSnackBar("请输入有效的端口号（1-65535）");
      return;
    }
    await Provider.of<SettingsManager>(
      context,
      listen: false,
    ).setCommunicationPort(port);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('communicationPort', port);

    if (mounted) {
      _showSnackBar("端口号已保存");
    }
  }

  /// 保存广播端口号
  Future<void> _saveBroadcastPort() async {
    final int? port = int.tryParse(broadcastPortController.text);
    if (port == null || port <= 0 || port > 65535) {
      _showSnackBar("请输入有效的广播端口号（1-65535）");
      return;
    }
    await Provider.of<SettingsManager>(
      context,
      listen: false,
    ).setBroadcastPort(port);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('broadcastPort', port);

    if (mounted) {
      _showSnackBar("广播端口号已保存");
    }
  }
  Future<void> _saveDeviceName() async {
    String deviceName = deviceNameController.text;
    if (deviceName.isEmpty) {
      _showSnackBar("设备名称不能为空");
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('deviceName', deviceName);

    _showSnackBar("设备名称已保存");
  }
  /// 选择文件保存路径
  Future<void> _selectDirectory() async {
    String? directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null) {
      if (mounted) {
        // 🔹 确保 context 仍然有效
        final settingsManager = Provider.of<SettingsManager>(
          context,
          listen: false,
        );
        await settingsManager.setSavePath(directory); // ✅ 使用实例方法
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString('savePath', directory);

      if (mounted) {
        setState(() {
          selectedDirectory = directory;
        });
        _showSnackBar("文件保存路径已更新");
      }
    }
  }

  /// 显示 SnackBar
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16), // 圆角窗口
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 适应内容高度
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '设置',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildSettingsSection("通讯端口号", portController, _savePort),
            const SizedBox(height: 20),
            _buildSettingsSection(
              "广播端口号",
              broadcastPortController,
              _saveBroadcastPort,
            ),
            const SizedBox(height: 20),
            _buildSettingsSection("本机名称", deviceNameController, _saveDeviceName),
            const SizedBox(height: 20),
            _buildFilePathSection(),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("关闭"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    String label,
    TextEditingController controller,
    VoidCallback onSave,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "请输入端口号"),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(onPressed: onSave, child: const Text("保存")),
          ],
        ),
      ],
    );
  }

  Widget _buildFilePathSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "文件保存路径",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text("当前路径: $selectedDirectory"),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _selectDirectory, child: const Text("选择文件夹")),
      ],
    );
  }
}

class SettingsManager extends ChangeNotifier {
  // 继承 ChangeNotifier{
  //static const String _downloadPathKey = 'download_path';
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();
  int _communicationPort = 9900;
  int _broadcastPort = 8800;
  String _savePath = "";
  int get communicationPort => _communicationPort;
  int get broadcastPort => _broadcastPort;
  String get savePath => _savePath;

  /// 获取默认下载路径（根据不同平台选择合适的路径）
  static Future<String> getDefaultDownloadPath() async {
    if (Platform.isAndroid) {
    final directory = await getExternalStorageDirectory(); // 获取外部存储目录
      String savePath='${directory!.parent.parent.parent.parent.path}/Download/LANTransmission';
      Directory dir = Directory(savePath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    
      return savePath;
    } else if (Platform.isIOS) {
      return (await getApplicationDocumentsDirectory()).path; // iOS 仍然使用沙盒目录
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return (await getDownloadsDirectory())?.path ?? "";
    }
    return "";
  }

  /// **获取当前设置的下载路径（如果未设置则返回默认路径）**
  static Future<String> getDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('savePath') ?? await getDefaultDownloadPath();
  }

  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _communicationPort = prefs.getInt('communicationPort') ?? 9900;
    _broadcastPort = prefs.getInt('broadcastPort') ?? 8800;
    _savePath = prefs.getString('savePath') ?? "";
    notifyListeners(); // 通知所有监听者
  }

  Future<void> setCommunicationPort(int port) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('communicationPort', port);
    _communicationPort = port;
    notifyListeners(); // 通知所有监听者
  }

  Future<void> setBroadcastPort(int port) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('broadcastPort', port);
    _broadcastPort = port;
    notifyListeners(); // 通知所有监听者
  }

  Future<void> setSavePath(String path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('savePath', path);
    _savePath = path;
    notifyListeners(); // 通知所有监听者
  }
}
