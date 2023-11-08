import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
// import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:move_to_background/move_to_background.dart';
import 'package:workmanager/workmanager.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:audio_service/audio_service.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'setting.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';


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

class Alarm {
  String time;
  bool snooze;
  bool vibration;
  bool silent;
  String label;

  Alarm(this.time, {this.snooze = true, this.vibration = true, this.silent = false, required this.label});
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
  String _userInput = '';
  List<Alarm> taimList = [];
  String _time = '';
  String _selectedAlarmTime = '';
  final db = FirebaseFirestore.instance;
  final userID = FirebaseAuth.instance.currentUser?.uid ?? 'test';
  final audioPlayer = AudioPlayer();
  final _cache = AudioCache();
  static const MP3 = 'sounds/iphone-13-pro-alarm.mp3';
  static const MMP3 = 'sounds/mp.mp3';
  static const MP33 = 'sounds/m.mp3';
  bool snooze = true;
  bool vibration = true;
  bool isOn3 = false;
  bool Silent = false;
  int _currentIndex = 0;
  Timer? _alarmTimer;


  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(seconds: 1), _onTimer);
    _loadCheckBoxState();
    _fetchDataFromFirestore();
  }

  void _fetchDataFromFirestore() async {
    try {
      final snapshot =
      await db.collection('users').doc(userID).collection('alarms').get();
      final List<Alarm> alarms = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Alarm(data['time'], snooze: data['snooze'], vibration: data['vibration'], label: '');
      }).toList();

      setState(() {
        taimList = alarms;
      });
    } catch (e) {
      print('データの取得中にエラーが発生しました: $e');
    }
  }
  void _raberuAlertDialog() async {
    if (isOn3 == true) {
      TextEditingController textFieldController = TextEditingController();

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('ラベル'),
            content: TextField(
                controller: textFieldController,
                decoration: InputDecoration(hintText: 'アラームの名前'),
                keyboardType: TextInputType.text,
                maxLength:10
            ),

            actions: <Widget>[
              TextButton(
                child: Text('キャンセル'),
                onPressed: () {
                  isOn3 = false;
                  Navigator.of(context).pop();

                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  setState(() {
                    _userInput = textFieldController.text;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }



  void _onTimer(Timer timer) {
    var now = DateTime.now();
    var dateFormat = DateFormat('HH:mm:ss EEEE', 'ja');
    var timeString = dateFormat.format(now);
    setState(() {
      _time = timeString;
    });

    for (int i = 0; i < taimList.length; ++i) {
      var alarmTime = DateFormat("HH:mm EEEE", 'ja').parse(taimList[i].time);
      if (now.hour == alarmTime.hour && now.minute == alarmTime.minute) {
        if (!taimList[i].silent) {
          if (taimList[i].snooze) {
            audioPlayer.play(AssetSource(MP3));

            _setSnoozeAlarm(taimList[i]);
            _removeAlarmFromDatabase(taimList[i]);
            taimList.removeAt(i);
          }
          if (!taimList[i].snooze) {
            audioPlayer.play(AssetSource(MP3));

            _removeAlarmFromDatabase(taimList[i]);
            taimList.removeAt(i);
          }
        }
        if (taimList[i].silent) {
          if (taimList[i].snooze) {


            _setSnoozeAlarm(taimList[i]);
            _removeAlarmFromDatabase(taimList[i]);
            taimList.removeAt(i);
            print('沈黙中');
          }
          if (!taimList[i].snooze) {


            _removeAlarmFromDatabase(taimList[i]);
            taimList.removeAt(i);
            print('沈黙中');
          }
        }
        if (taimList[i].vibration) {
          Vibration.vibrate(duration: 1000);
          print('バイブレーション中');
        }

      }
    }
  }

  void _setSnoozeAlarm(Alarm alarm) {
    var now = DateTime.now();
    var nextAlarmTime = now.add(Duration(minutes: 5));
    taimList.add(Alarm(
      DateFormat("HH:mm EEEE", 'ja').format(nextAlarmTime),
      snooze: snooze,
      vibration: vibration,
      label: alarm.label,
        silent: alarm.silent,
    ));
    _saveAlarmToDatabase(taimList.last);
  }

  void vibration1() {
    _alarmTimer?.cancel();
    _alarmTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      Vibration.vibrate(duration: 1000);
    });
  }

  void stop() {
    _alarmTimer?.cancel();
  }

  void _setAlarm() {
    setState(() {
      audioPlayer.play(AssetSource(MMP3));
      String alarmTime = _selectedAlarmTime;
      String alarmLabel = _userInput; // ラベルをユーザーの入力から取得
      bool isSilent = Silent;
      Alarm newAlarm = Alarm(alarmTime, snooze: snooze, vibration: vibration, silent: isSilent, label: alarmLabel); // ラベルを設定
      taimList.add(newAlarm);
      _saveAlarmToDatabase(newAlarm);
      _selectedAlarmTime = '';
      _userInput = ''; // ユーザーの入力をリセット
    });
  }



  void _removeAlarm(int index) {
    setState(() {
      audioPlayer.play(AssetSource(MMP3));
      _removeAlarmFromDatabase(taimList[index]);
      taimList.removeAt(index);
    });
  }

  void _loadCheckBoxState() async {
    final documentReference = db.collection('users').doc(userID);
    final documentSnapshot = await documentReference.get();
    if (documentSnapshot.exists) {
      final data = documentSnapshot.data() as Map<String, dynamic>;
      setState(() {
        snooze = data['snooze'] ?? true;
        vibration = data['vibration'] ?? true;
      });
    }
  }

  void _saveAlarmToDatabase(Alarm alarm) async {
    try {
      await db.collection('users').doc(userID).collection('alarms').add({
        'time': alarm.time,
        'snooze': alarm.snooze,
        'vibration': alarm.vibration,
        'label': alarm.label,
      });
      print('アラームをデータベースに保存しました: ${alarm.time}');
    } catch (e) {
      print('アラームのデータベースへの保存中にエラーが発生しました: $e');
    }
  }

  void _removeAlarmFromDatabase(Alarm alarm) async {
    try {
      QuerySnapshot snapshot = await db
          .collection('users')
          .doc(userID)
          .collection('alarms')
          .where('time', isEqualTo: alarm.time)
          .get();
      snapshot.docs.forEach((doc) {
        doc.reference.delete();
      });
      print('アラームをデータベースから削除しました: ${alarm.time}');
    } catch (e) {
      print('アラームのデータベースからの削除中にエラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '',
          style: TextStyle(
            fontSize: 40.0,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: _currentIndex == 0
          ? SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 200.0,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        initialDateTime: DateTime.now(),
                        onDateTimeChanged: (DateTime dateTime) {
                          setState(() {
                            _selectedAlarmTime = DateFormat("HH:mm EEEE", 'ja').format(dateTime);
                          });
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: snooze,
                        onChanged: (value) {
                          setState(() {
                            Vibration.vibrate(duration: 1000);
                            snooze = value!;
                            // チェックボックスの状態を保存
                          });
                        },
                        activeColor: Colors.black,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(snooze ? "スヌーズ : ON　" : "スヌーズ : OFF　"),
                      Checkbox(
                        value: vibration,
                        onChanged: (value) {
                          setState(() {
                            vibration = value!;
                            // チェックボックスの状態を保存
                          });
                        },
                        activeColor: Colors.black,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(vibration ? "バイブレーション : ON" : "バイブレーション : OFF"),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: isOn3,
                        onChanged: (value) {
                          setState(() {
                            isOn3 = value!;
                            _raberuAlertDialog();

                          });
                        },
                        activeColor: Colors.black,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(isOn3 ? " $_userInput" : "ラベル "),
                      Checkbox(
                        value: Silent,
                        onChanged: (value) {
                          setState(() {
                            Silent = value!;
                          });
                        },
                        activeColor: Colors.black,
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(Silent ? "サイレント " : "サイレント "),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedAlarmTime.isNotEmpty) {
                        _setAlarm();
                        print('$_selectedAlarmTime にアラームを設定しました');
                        print('$taimList');
                        isOn3 = false!;
                        Silent = false!;
                      } else {
                        print('アラーム時刻を選択してください');
                      }
                    },
                    child: Text(
                      'アラームを設定する',
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.white,
                      onPrimary: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: taimList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final alarm = taimList[index];
                    return ListTile(
                      title: OutlinedButton(
                        onPressed: () {},
                        child: Text('${alarm.label}   ${_userInput}${alarm.time} (スヌーズ: ${alarm.snooze ? 'ON' : 'OFF'}) ${alarm.silent ? 'サイレント' : ''}'), // Include 'サイレント' in the text if it's a silent alarm
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          primary: Colors.black,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.black),
                        onPressed: () {
                          _removeAlarm(index);
                          print('$taimList');
                        },
                      ),
                    );
                  },
                )
            ),
          ],
        ),
      )
          : SettingPage(),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
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
            label: 'タイマー',
          ),
        ],
      ),
    );
  }
}