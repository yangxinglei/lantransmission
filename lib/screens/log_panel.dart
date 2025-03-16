import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/device_state.dart';


class LogPanel extends StatefulWidget {


  const LogPanel({super.key});

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  final ScrollController _scrollController = ScrollController();
  late ValueNotifier<List<String>> logNotifier;
  @override
  void initState() {
    super.initState();
    logNotifier = context.read<DeviceState>().logNotifier;
    logNotifier.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    logNotifier.removeListener(_scrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      color: Colors.black,
      child: ValueListenableBuilder<List<String>>(
        valueListenable: logNotifier,
        builder: (context, logs, _) {
          return ListView.builder(
            controller: _scrollController, // 绑定滚动控制器
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                child: SelectableText(
                  logs[index],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}