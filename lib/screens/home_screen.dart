import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/device_state.dart';
import '../services/services.dart';
import 'device_list.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'log_panel.dart';
import 'appmenubar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // 📱 **移动端**
      return const MobileLayout();
    } else {
      // 🖥️ **PC端**
      return const DesktopLayout();
    }
  }
}

/// **PC端布局**
class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceState = context.watch<DeviceState>(); // 监听状态变化
    return Scaffold(
      body: Column(
        children: [
          // 顶部菜单栏
          const AppMenuBar(),
          // 中间部分：设备列表和聊天界面
          Expanded(
            child: Row(
              children: [
                // 左侧设备列表
                Expanded(
                  flex: 2,
                  child: DeviceList(
                    onDeviceSelected: (deviceIp,isneedconnect) async {
                      if(isneedconnect){
                            Services.connectToDevice(
                        deviceIp,
                        await SettingsScreen.getCommunicationPort(),
                      );

                      }
                      
                    },
                    onDisconnect: (deviceIp) {
                      deviceState.selectDevice(null);
                      Services.disconnectDevice(deviceIp);
                    },
                  ),
                ),
                // 右侧聊天界面
                Expanded(
                  flex: 5,
                  child:
                      deviceState.selectedDevice == null
                          ? const Center(child: Text('请选择设备'))
                          : ChatScreen(
                            device: deviceState.talkermane,
                            sendMessage: (String message) {
                              Services.sendMessageToDevice(
                                deviceState.selectedDevice ?? "",
                                message,
                              );
                            },
                            sendFile: (File file) async {
                              Services.sendFileToDevice(
                                deviceState.selectedDevice ?? "",
                                file,
                                await SettingsScreen.getDeviceName(),
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
          // 底部日志窗口
          LogPanel(),
        ],
      ),
    );
  }
}

/// **移动端布局**
class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  MobileLayoutState createState() => MobileLayoutState();
}

class MobileLayoutState extends State<MobileLayout> {
  int _selectedIndex = 0;
  bool _isDeviceSelected = false; // 是否选中了设备

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      DeviceList(
        onDeviceSelected: (device,isneedconnect) async {
          setState(() {
            _isDeviceSelected = true;
          });
          if(isneedconnect){
              Services.connectToDevice(
            device,
            await SettingsScreen.getCommunicationPort(),
          );
          }
          
        },
        onDisconnect: (device) {
          setState(() {
            _isDeviceSelected = false;
          });
          Services.disconnectDevice(device);
        },
      ),
      const AppMenuBar(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = context.watch<DeviceState>();
    return Scaffold(
      appBar: AppBar(
        leading:
            _isDeviceSelected
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _isDeviceSelected = false; // 返回设备列表
                    });
                  },
                )
                : null,
        title:
            _isDeviceSelected
                ? Text('与 ${deviceState.talkermane} 聊天') // 显示聊天的标题
                : const Text('局域网传输'), // 显示设备列表标题
      ),
      body: Column(
        children: [
          // 如果选中了设备，显示设备的聊天界面；否则显示设备列表
          Expanded(
            child:
                _isDeviceSelected
                    ? ChatScreen(
                      device: deviceState.talkermane,
                      sendMessage: (String message) {
                        Services.sendMessageToDevice(
                          deviceState.selectedDevice ?? "",
                          message,
                        );
                      },
                      sendFile: (File file) async {
                        Services.sendFileToDevice(
                          deviceState.selectedDevice ?? "",
                          file,
                          await SettingsScreen.getDeviceName(),
                        );
                      },
                    )
                    : _pages[_selectedIndex],
          ),
          const LogPanel(), // 📜 日志窗口
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap:
            (index) => setState(() {
              _selectedIndex = index;
              _isDeviceSelected = false; // 点击设备列表或设置时重置设备选择状态
            }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: "设备"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "设置"),
        ],
      ),
    );
  }
}
