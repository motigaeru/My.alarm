import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:workmanager/workmanager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audio_service/audio_service.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'setting.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    // バックグラウンドで定期的に実行したい処理をここに記述します
    print("バックグラウンドでタスクを実行中...");
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  initializeDateFormatting();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ClockTimer(title: ''),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ClockTimer extends StatefulWidget {
  const ClockTimer({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _ClockTimerState createState() => _ClockTimerState();
}

class _ClockTimerState extends State<ClockTimer> {
  List<String> taimList = [];
  String _time = '';
  final db = FirebaseFirestore.instance;
  final userID = FirebaseAuth.instance.currentUser?.uid ?? 'test';
  final audioPlayer = AudioPlayer();
  final _cache = AudioCache();
  static const MP3 = 'sounds/iphone-13-pro-alarm.mp3';
  static const MMP3 = 'sounds/mp.mp3';
  static const MP33 = 'sounds/m.mp3';

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 1), _onTimer);
    _fetchDataFromFirestore();
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
        taimList = alarms;
      });
    } catch (e) {
      print('データの取得中にエラーが発生しました: $e');
    }
  }

  void _onTimer(Timer timer) {
    var now = DateTime.now();
    var dateFormat = DateFormat('HH:mm:ss EEEE', 'ja');
    var timeString = dateFormat.format(now);
    setState(() {
      _time = timeString;
    });

    for (int i = 0; i < taimList.length; i++) {
      var alarmTime = DateFormat("yyyy-MM-dd-HH:mm EEEE", 'ja').parse(taimList[i]);
      if (alarmTime.isBefore(now)) {
        setState(() {
          audioPlayer.play(AssetSource(MP3));
          _removeAlarmFromDatabase(taimList[i]);
          taimList.removeAt(i);
        });
      }
    }
  }

  void _setAlarm(DateTime selectedTime) {
    setState(() {
      audioPlayer.play(AssetSource(MMP3));

      taimList.add(DateFormat("yyyy-MM-dd-HH:mm EEEE", 'ja').format(selectedTime));
      _saveAlarmToDatabase(DateFormat("yyyy-MM-dd-HH:mm EEEE", 'ja').format(selectedTime));
    });
  }

  void _removeAlarm(int index) {
    setState(() {
      audioPlayer.play(AssetSource(MMP3));
      _removeAlarmFromDatabase(taimList[index]);
      taimList.removeAt(index);
    });
  }

  void _saveAlarmToDatabase(String alarmTime) async {
    try {
      await db.collection('users').doc(userID).collection('alarms').add({
        'time': alarmTime,
      });
      print('アラームをデータベースに保存しました: $alarmTime');
    } catch (e) {
      print('アラームのデータベースへの保存中にエラーが発生しました: $e');
    }
  }

  void _removeAlarmFromDatabase(String alarmTime) async {
    try {
      QuerySnapshot snapshot = await db.collection('users').doc(userID).collection('alarms').where('time', isEqualTo: alarmTime).get();
      snapshot.docs.forEach((doc) {
        doc.reference.delete();
      });
      print('アラームをデータベースから削除しました: $alarmTime');
    } catch (e) {
      print('アラームのデータベースからの削除中にエラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_time,style: TextStyle(
          fontSize: 40.0,
        ),
        ),

      ),
      backgroundColor: Colors.white,
      body: _currentIndex == 0
          ? SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: TextButton(
                onPressed: () {
                  DatePicker.showDateTimePicker(
                    context,
                    showTitleActions: true,
                    minTime: DateTime(1950, 1, 1),
                    maxTime: DateTime(3000, 12, 30),
                    onChanged: (date) {},
                    onConfirm: (date) {
                      _setAlarm(date);
                      print('${DateFormat("yyyy-MM-dd-HH:mm EEEE", 'ja').format(date)}にアラームを設定しました');
                      print('$taimList');
                    },
                    currentTime: DateTime.now(),
                    locale: LocaleType.jp,
                  );
                },
                child: const Text(
                  'アラームを設定する',
                  style: TextStyle(fontSize: 25, color: Colors.blue),
                ),
              ),
            ),
            SingleChildScrollView(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: taimList.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: OutlinedButton(
                      onPressed: () {},
                      child: Text('${taimList[index]}'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.blue),
                      onPressed: () {
                        _removeAlarm(index);
                        print('$taimList');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      )
          : SettingPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_alarm),
            label: 'アラーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
