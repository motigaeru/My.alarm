import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  // ignore: library_private_types_in_public_api
  @override
  // ignore: library_private_types_in_public_api
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final db = FirebaseFirestore.instance;
  final userID = FirebaseAuth.instance.currentUser?.uid ?? 'test';
  @override
  void initState() {
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

        ),
      ),
    );
  }
}
