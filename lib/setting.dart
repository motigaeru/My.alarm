// ignore_for_file: avoid_print, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  _SettingPageState createState() => _SettingPageState();
  static _SettingPageState? of(BuildContext context) =>
      context.findAncestorStateOfType<_SettingPageState>();
}

class _SettingPageState extends State<SettingPage> {
  final db = FirebaseFirestore.instance;
  final userID = FirebaseAuth.instance.currentUser?.uid ?? 'test';
  String inputText = '';
  double alarmVolume = 0.5; // デフォルトの音量

  @override
  void initState() {
    super.initState();
  }

  Future<void> saveDataToFirestore(String text) async {
    try {
      await db.collection('users').doc(userID).set({'lockedText': text});
      print('データを Firestore に保存しました: $text');
    } catch (e) {
      print('Firestore へのデータ保存中にエラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // 画面外タップを検知するために必要
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
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
                        activeColor: Colors.yellow, // スライダーの色を黄色に設定
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
