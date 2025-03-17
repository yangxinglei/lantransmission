import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lantransmission/services/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IPSelector extends StatefulWidget {
  const IPSelector({super.key});

  @override
  IPSelectorState createState() => IPSelectorState();
}

class IPSelectorState extends State<IPSelector> {
  List<String> ipList = [];
  String? selectedIP;

  @override
  void initState() {
    super.initState();
    _loadIPs();
  }

  Future<List<String>> getLocalIPs() async {
    List<String> ipList = [];

    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 &&
            (addr.address.startsWith('192.') ||
                addr.address.startsWith('10.') ||
                addr.address.startsWith('172.'))) {
          ipList.add(addr.address);
        }
      }
    }
    return ipList;
  }

  Future<void> _loadIPs() async {
    List<String> ips = await getLocalIPs();
    setState(() {
      ipList = ips;
    });

    // 加载上次选择的IP
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedIP =
          prefs.getString('localIP') ?? (ipList.isNotEmpty ? ipList[0] : null);
    });
  }

  Future<void> _saveSelectedIP(String? ip) async {
    if (ip != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('localIP', ip);
      await Services.restartTcpServer();
      await Services.restartBroadcastAndListen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedIP,
      hint: const Text("选择局域网 IP"),
      items:
          ipList.map((ip) {
            return DropdownMenuItem<String>(value: ip, child: Text(ip));
          }).toList(),
      onChanged: (value) {
        setState(() {
          selectedIP = value;
        });
        _saveSelectedIP(value);
      },
    );
  }
}
