import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(
    const MaterialApp(
      home: SettingPage(),
    ),
  );
}

class AudioService {
  static final AudioPlayer audioPlayer = AudioPlayer();
}

class SettingPage extends StatefulWidget {
  @override
  const SettingPage({Key? key}) : super(key: key);

  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final db = FirebaseFirestore.instance;
  final userID = FirebaseAuth.instance.currentUser?.uid ?? 'test';

  double alarmVolume = 0.5; // デフォルトの音量

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // アラーム音量を調整するスライダーを追加
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text('アラームの音量: ${(alarmVolume * 100).round()}%'),
                  Expanded(
                    child: Slider(
                      value: alarmVolume,
                      onChanged: (value) {
                        setState(() {
                          alarmVolume = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
