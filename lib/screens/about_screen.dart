import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  static String softwareVersion = "V1.0.1";
  final String donateUrl = "https://yangxinglei.github.io/donate";
  const AboutScreen({super.key});
  // 打开网页的方法
  Future<void> _launchURL(String urlname) async {
    final Uri url = Uri.parse(urlname);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("无法打开 $urlname");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16), // ✅ **圆角窗口**
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ **让窗口高度适应内容**
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关于',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '软件名称: 局域网传输',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text('版本号: $softwareVersion', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            const Text('作者: YangXinglei', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _launchURL(donateUrl);
              },
              icon: const Icon(Icons.favorite, color: Colors.red),
              label: const Text('捐赠开发者'),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context), // ✅ 关闭弹窗
                child: const Text("关闭"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
