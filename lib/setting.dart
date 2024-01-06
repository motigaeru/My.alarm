import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
void main() {
  runApp(
    MaterialApp(
      home: SettingPage(),
    ),
  );
}

class AudioService {
  static final AudioPlayer audioPlayer = AudioPlayer();
}

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final db = FirebaseFirestore.instance;
  final userID = FirebaseAuth.instance.currentUser?.uid ?? 'test';
  @override
  void initState() {
    super.initState();

  }
  void _fetchDataFromFirestore() async {
    try {
      final snapshot = await db
          .collection('users')
          .doc(userID)
          .collection('alarms')
          .get();
      final List<String> alarms = snapshot.docs
          .map((doc) => doc.get('time') as String)
          .toList();

      setState(() {
      });
    } catch (e) {
      print('データの取得中にエラーが発生しました: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

        ),
      ),
    );
  }
}
