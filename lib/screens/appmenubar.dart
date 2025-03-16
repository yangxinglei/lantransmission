/* import 'dart:io';

import 'package:flutter/material.dart';
import 'help_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';


class AppMenuBar extends StatelessWidget {
  const AppMenuBar({super.key});
  void openReceivedFilesFolder() async {
    String savedPath = await SettingsScreen.getSavePath();

    if (Platform.isWindows) {
      Process.run('explorer', [savedPath]);
    } else if (Platform.isMacOS) {
      Process.run('open', [savedPath]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [savedPath]);
    }
  }
void _showDialog(BuildContext context, Widget page, Alignment alignment) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(alignment: alignment, child: page),
    );
  }
   @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: const Color.fromARGB(255, 235, 196, 56),
      child: Row(
        children: [
          // **设置按钮**
          TextButton.icon(
            onPressed: () => _showDialog(context, const SettingsScreen(), Alignment.topLeft),
            icon: const Icon(Icons.settings),
            label: const Text('设置'),
          ),
           // **浏览接收文件夹**
          TextButton.icon(
            onPressed: openReceivedFilesFolder,
            icon: const Icon(Icons.folder_sharp),
            label: const Text('浏览接收文件'),
          ),
          // **帮助按钮**
          TextButton.icon(
            onPressed: () => _showDialog(context, const HelpScreen(), Alignment.topCenter),
            icon: const Icon(Icons.help_outline),
            label: const Text('帮助'),
          ),

          // **关于按钮**
          TextButton.icon(
            onPressed: () => _showDialog(context, AboutScreen(), Alignment.topRight),
            icon: const Icon(Icons.info_outline),
            label: const Text('关于'),
          ),
        ],
      ),
    );
  }
}
/// **可滑动弹出的自定义对话框**
class CustomDialog extends StatefulWidget {
  final Widget child;
  final Alignment alignment; // 控制弹窗从哪里出现

  const CustomDialog({super.key, required this.child, this.alignment = Alignment.center});

  @override
  CustomDialogState createState() => CustomDialogState();
}

class CustomDialogState extends State<CustomDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // 初始位置（从上往下滑）
      end: Offset.zero, // 目标位置
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward(); // 启动动画
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment, // 让弹窗出现在指定位置
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      ),
    );
  }
} */

import 'package:flutter/material.dart';

import 'dart:io';
import 'help_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';


class AppMenuBar extends StatelessWidget {
  const AppMenuBar({super.key});

  void openReceivedFilesFolder() async {
    try {
      String savedPath = await SettingsScreen.getSavePath();

      if (Platform.isWindows) {
        Process.run('explorer', [savedPath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [savedPath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [savedPath]);
      } 
    } catch (e) {
      Fluttertoast.showToast(msg: "无法打开文件夹，请手动前往目录");
    }
  }

  /// **获取按钮位置并弹出窗口**
  void _showDialog(BuildContext context, Widget page, GlobalKey key) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero); // 获取全局坐标
    final Size size = renderBox.size; // 获取按钮大小

    showDialog(
      context: context,
      builder:
          (context) => CustomDialog(
            alignment: _calculateAlignment(context, offset, size),
            child: page,
          ),
    );
  }

  /// **计算窗口滑出的对齐方式**
  Alignment _calculateAlignment(
    BuildContext context,
    Offset offset,
    Size size,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    double x =
        (offset.dx + size.width / 2) / screenWidth * 2 - 1; // X 位置 [-1, 1]
    double y = (offset.dy + size.height) / screenHeight * 2 - 1; // Y 位置 [-1, 1]

    return Alignment(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey settingsKey = GlobalKey();
    GlobalKey helpKey = GlobalKey();
    GlobalKey aboutKey = GlobalKey();

    return LayoutBuilder(
      builder: (context, constraints) {
        // 判断是否为移动端 (宽度小于某个值，比如600px)
        bool isMobile = constraints.maxWidth < 600;

        return Container(
          height: 50,
          color: const Color.fromARGB(255, 218, 233, 87),
          child:
              isMobile
                  ? Column(
                    // 移动端纵向排列
                    children: [
                      Align(
                        alignment: Alignment.centerLeft, // 按钮居左对齐
                        child: TextButton.icon(
                          key: settingsKey,
                          onPressed:
                              () => _showDialog(
                                context,
                                const SettingsScreen(),
                                settingsKey,
                              ),
                          icon: const Icon(Icons.settings),
                          label: const Text('设置'),
                        ),
                      ),
                      /* Align(
                        alignment: Alignment.centerLeft,

                        child: TextButton.icon(
                          onPressed: openReceivedFilesFolder,

                          icon: const Icon(Icons.folder_sharp),
                          label: const Text('浏览接收文件'),
                        ),
                      ), */
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: helpKey,
                          onPressed:
                              () => _showDialog(
                                context,
                                const HelpScreen(),
                                helpKey,
                              ),
                          icon: const Icon(Icons.help_outline),
                          label: const Text('帮助'),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: aboutKey,
                          onPressed:
                              () =>
                                  _showDialog(context, AboutScreen(), aboutKey),
                          icon: const Icon(Icons.info_outline),
                          label: const Text('关于'),
                        ),
                      ),
                    ],
                  )
                  : Row(
                    // 电脑端横向排列
                    children: [
                      TextButton.icon(
                        key: settingsKey,
                        onPressed:
                            () => _showDialog(
                              context,
                              const SettingsScreen(),
                              settingsKey,
                            ),
                        icon: const Icon(Icons.settings),
                        label: const Text('设置'),
                      ),
                      TextButton.icon(
                        onPressed: openReceivedFilesFolder,
                        icon: const Icon(Icons.folder_sharp),
                        label: const Text('浏览接收文件'),
                      ),
                      TextButton.icon(
                        key: helpKey,
                        onPressed:
                            () => _showDialog(
                              context,
                              const HelpScreen(),
                              helpKey,
                            ),
                        icon: const Icon(Icons.help_outline),
                        label: const Text('帮助'),
                      ),
                      TextButton.icon(
                        key: aboutKey,
                        onPressed:
                            () => _showDialog(context, AboutScreen(), aboutKey),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('关于'),
                      ),
                    ],
                  ),
        );
      },
    );
  }
}

class CustomDialog extends StatefulWidget {
  final Widget child;
  final Alignment alignment;

  const CustomDialog({
    super.key,
    required this.child,
    this.alignment = Alignment.center,
  });

  @override
  CustomDialogState createState() => CustomDialogState();
}

class CustomDialogState extends State<CustomDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3), // **从按钮上方滑入**
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.alignment,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Wrap(
            // ✅ **使用 Wrap 让弹窗高度自适应**
            children: [
              Container(
                width: 400, // 固定宽度
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                padding: const EdgeInsets.all(16),
                child: widget.child, // ✅ **高度根据内容自适应**
              ),
            ],
          ),
        ),
      ),
    );
  }
}
