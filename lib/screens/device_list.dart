import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/device_state.dart';
import '../services/services.dart'; // 设备发现模块

class DeviceList extends StatefulWidget {
  final Function(String device, bool isNeedConnected) onDeviceSelected; // 选中设备回调
  final ValueChanged<String> onDisconnect; // 断开连接回调

  const DeviceList({
    super.key,
    required this.onDeviceSelected,
    required this.onDisconnect,
  });

  @override
  DeviceListState createState() => DeviceListState();
}

class DeviceListState extends State<DeviceList> {
  bool showFavorites = false; // 是否显示收藏设备
  static final List<String> _favoriteDevices = [];
  static final StreamController<List<String>> _deviceController =
      StreamController.broadcast();
  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteDevices.clear();
      _favoriteDevices.addAll(prefs.getStringList('favoriteDevices') ?? []);
    });
    _deviceController.add(_favoriteDevices);
  }

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
    _deviceController.add(_favoriteDevices);
    await saveFavorites();
    setStateCallback(() {});
  }

  void selectDevice(String deviceName, String deviceIp,bool isneedconnect) {
    final deviceState = DeviceState();
    deviceState.setTalkerName(deviceName);
    deviceState.selectDevice(deviceIp);
    setState(() {
      
    });
    widget.onDeviceSelected(deviceIp,isneedconnect);
  }

  void disconnectDevice(String deviceIp) {
    setState(() {
      
    });
    widget.onDisconnect(deviceIp);
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = context.watch<DeviceState>();
    return Container(
      width: double.infinity,
      color: Colors.grey[200],
      child: Column(
        children: [
          // 顶部菜单栏
          Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => setState(() => showFavorites = false),
                  child: Text(
                    '当前设备',
                    style: TextStyle(
                      fontWeight:
                          showFavorites ? FontWeight.normal : FontWeight.bold,
                      color: showFavorites ? Colors.black : Colors.blue,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => showFavorites = true),
                  child: Text(
                    '收藏设备',
                    style: TextStyle(
                      fontWeight:
                          showFavorites ? FontWeight.bold : FontWeight.normal,
                      color: showFavorites ? Colors.blue : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 设备列表
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              // 监听设备列表变化
              valueListenable: Services.deviceListNotifier,
              builder: (context, allDevices, child) {
                List<String> devices =
                    showFavorites
                        ? _favoriteDevices
                        : allDevices;

                return devices.isEmpty
                    ? Center(child: Text(showFavorites ? "没有收藏设备" : "未发现设备"))
                    : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        String deviceInfo = devices[index];
                        List<String> parts = deviceInfo.split("：");
                        String deviceName = parts[0];
                        String deviceIp = parts.length > 1 ? parts[1] : "";

                        return StatefulBuilder(
                          builder: (context, setStateListTile) {
                            bool isFav = isFavorite(deviceInfo);
                            bool isSelected = deviceState.selectedDevice == deviceIp;
                            bool isConnected  = Services.activeConnections.containsKey(deviceIp) ;
                            return Container(
                              color:
                                  isSelected
                                      ? const Color.fromARGB(255, 89, 169, 235).withValues(
                                        alpha: (0.9 * 255).toDouble(),
                                      )
                                      : null, // 选中设备高亮
                              child: ListTile(
                                title: Text(
                                  deviceName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  deviceIp,
                                  style: const TextStyle(color: Colors.black87),
                                ),
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
                                        () => toggleFavorite(
                                          deviceInfo,
                                          setStateListTile,
                                        ),
                                      ),
                                    ),
                                    // 连接/断开 按钮
                                    Tooltip(
                                      message: isConnected ? "断开连接" : "连接到设备",
                                      child: IconButton(
                                        icon: Icon(
                                          isConnected
                                              ? Icons.link
                                              : Icons.link_off,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (isConnected) {
                                              disconnectDevice(deviceIp);
                                              deviceState.selectDevice(null);
                                            } else {
                                              selectDevice(
                                                deviceName,
                                                deviceIp,
                                                true
                                              );
                                              
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                 // 设备项点击事件
                                onTap: () {

                                    selectDevice(
                                                deviceName,
                                                deviceIp,
                                                false
                                              );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}


