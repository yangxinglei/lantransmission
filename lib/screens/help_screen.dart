import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  final String githubUrl =
      "https://github.com/yangxinglei/lantransmission/discussions/categories/general";
  // 打开网页的方法
  Future<void> _launchURL() async {
    final Uri url = Uri.parse(githubUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("无法打开 $githubUrl");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      // ✅ **去掉 Scaffold，改用 Material**
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ **自适应高度**
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '帮助',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '1. 设备会自动发现同一局域网中安装了此软件的其他设备。\n'
              '2. 您可以发送消息和文件。\n'
              '3. 点击 "设置" 可修改本机名称、端口和文件存储位置。\n'
              '4. 通讯端口号：用于文件传输和消息。\n'
              '5. 广播端口号：用于设备发现。\n',

              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _launchURL,
              child: const Text(
                "🔗 遇到问题？'访问 GitHub / 联系开发者",
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
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
}
