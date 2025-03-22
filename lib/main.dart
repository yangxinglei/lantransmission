import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:lantransmission/services/device_state.dart';
import 'package:lantransmission/services/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsManager().loadSettings(); // 预加载设置
  if (Platform.isAndroid || Platform.isIOS) {
  // 调用权限请求
    await  requestManageStoragePermission();
    await Permission.storage.request().isGranted;
}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsManager()),
        ChangeNotifierProvider(create: (_) => DeviceState()),
        ChangeNotifierProvider(create: (_) => Services()),
      ],
      child: MyApp(),
    ),
  );
}
Future<bool> requestStoragePermission() async {
  if (await Permission.storage.request().isGranted) {
    return true;
  }
  return false;
}
Future<void> requestManageStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.isGranted) {
      //print("全盘存储访问权限已获取");
    } else {
      // 申请权限
      var status = await Permission.manageExternalStorage.request();
      if (status.isDenied) {
        //print("用户拒绝了存储权限");
      } else if (status.isPermanentlyDenied) {
        //print("用户永久拒绝存储权限，打开设置页面");

        // 跳转到系统设置页面，让用户手动授权
        const intent = AndroidIntent(
          action: 'android.settings.MANAGE_ALL_FILES_ACCESS_PERMISSION',
        );
        await intent.launch();
      }
    }
  }
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}
class MyAppState extends State<MyApp> {

   @override
  void initState() {
    super.initState();
    _initializeDeviceDiscovery();
    
  }
  Future<void> _initializeDeviceDiscovery() async {
    await Services.initialize(); // 等待初始化完成
    // 启动局域网发现和 TCP 服务器
        Services.startPeriodicBroadcast(); // 定时广播本机信息
    Services.listenForDeviceBroadcasts(); // 监听局域网设备
    Services.startTcpServer(); // 启动设备连接监听
    
    Services().addListener(Services.updateSettings); // 监听 SettingsManager 变化
  }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '局域网传输',
      debugShowCheckedModeBanner: false,
      theme: lightTheme, // 浅色模式
      darkTheme: darkTheme, // 深色模式
      themeMode: ThemeMode.system, // 跟随系统主题
      home: const HomeScreen(),
    );
  }
}

// 🎨 浅色主题
ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // 主题色
  brightness: Brightness.light,
  textTheme: TextTheme(
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(fontSize: 16),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue, // AppBar 背景色
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue, // 按钮颜色
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);

// 🌙 深色主题
ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black, // AppBar 背景色
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent, // 按钮颜色
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);