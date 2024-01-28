// ignore_for_file: library_private_types_in_public_api, constant_identifier_names, non_constant_identifier_names, unused_element, avoid_print, prefer_const_constructors, avoid_function_literals_in_foreach_calls, unnecessary_null_comparison
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'week.dart';
import 'package:flutter/cupertino.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:audio_service/audio_service.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// import 'package:flutter/services.dart';
// import 'package:move_to_background/move_to_background.dart';
// import 'package:workmanager/workmanager.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class ClockTimer extends StatefulWidget {
  const ClockTimer({Key? key, required this.title}) : super(key: key);
  final String title;

  void onWeekdaysSelected(List<bool> selectedWeekdays) {
    print('選択された曜日: $selectedWeekdays');
  }

  @override
  _ClockTimerState createState() => _ClockTimerState();
}

class Alarm {
  String time;
  bool snooze;
  bool vibration;
  bool silent;
  String label;
  List<bool> selectedWeekdays;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alarm &&
          runtimeType == other.runtimeType &&
          time == other.time &&
          snooze == other.snooze &&
          vibration == other.vibration &&
          silent == other.silent &&
          label == other.label &&
          ListEquality().equals(selectedWeekdays, other.selectedWeekdays);

  @override
  int get hashCode =>
      time.hashCode ^
      snooze.hashCode ^
      vibration.hashCode ^
      silent.hashCode ^
      label.hashCode ^
      ListEquality().hash(selectedWeekdays);

  Alarm(
    this.time, {
    this.snooze = true,
    this.vibration = true,
    this.silent = false,
    required this.label,
    required this.selectedWeekdays,
  });
}

class _ClockTimerState extends State<ClockTimer> {
  double alarmVolume = 0.5;
  List<bool> weekdays = [false, false, false, false, false, false, false];
  String _userInput = '';
  List<Alarm> taimList = [];
  String _selectedAlarmTime = '';
  final db = FirebaseFirestore.instance;
  final userID = FirebaseAuth.instance.currentUser?.uid ?? 'test';
  final audioPlayer = AudioPlayer();
  static const MP3 = 'sounds/iphone-13-pro-alarm.mp3';
  static const MMP3 = 'sounds/mp.mp3';
  // static const MP33 = 'sounds/m.mp3';
  bool snooze = true;
  bool vibration = true;
  bool raberu = false;
  bool Silent = false;
  bool week = false;
  // bool _showDatePicker = false;
  Timer? _alarmTimer;
  DateTime today = DateTime.now();
  DateTime _selectedDate = DateTime.now();

  String _formatSelectedWeekdays(List<bool> selectedWeekdays) {
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    List<String> selectedDays = [];
    for (int i = 0; i < selectedWeekdays.length; i++) {
      if (selectedWeekdays[i]) {
        selectedDays.add(weekdays[i]);
      }
    }
    return '(${selectedDays.join(',')})';
  }

  void _startTimer() {
    _alarmTimer = Timer.periodic(const Duration(seconds: 1), _onTimer);
  }

  @override
  void dispose() {
    _alarmTimer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> saveDataToFirestore(String text) async {
    final db = FirebaseFirestore.instance;
    final userID = FirebaseAuth.instance.currentUser?.uid ?? 'test';

    try {
      await db.collection('users').doc(userID).set({'lockedText': text});
      print('データを Firestore に保存しました: $text');
    } catch (e) {
      print('Firestore へのデータ保存中にエラーが発生しました: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;

        _selectedAlarmTime = DateFormat('MM/dd EEEE', 'ja').format(picked);
      });
    }
  }

  Future<void> setNotification(title, text) async {
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        // sound: 'example.mp3',
        presentAlert: true,
        presentBadge: true,
        presentSound: true);
    NotificationDetails platformChannelSpecifics = const NotificationDetails(
      iOS: iosDetails,
      android: null,
    );
    await flutterLocalNotificationsPlugin.show(
        0, title, text, platformChannelSpecifics);
  }

  @override
  void initState() {
    super.initState();
    _alarmTimer = Timer.periodic(const Duration(seconds: 1), _onTimer);
    _loadCheckBoxState();
    _fetchDataFromFirestore();
  }

  void _setWeekdays(List<bool> selectedWeekdays) {
    setState(() {
      week = selectedWeekdays.contains(true);
      weekdays = List.from(selectedWeekdays);
    });
  }

  void _selectWeekdays() async {
    List<bool>? selectedWeekdays = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeekdaySelectionPage(
          onWeekdaysSelected: (weekdays) {
            if (weekdays != null) {
              _setWeekdays(weekdays);
              print('Selected weekdays: $weekdays');
            }
          },
        ),
      ),
    );

    if (selectedWeekdays != null) {
      print('Selected weekdays: $selectedWeekdays');
    }
  }

  void _fetchDataFromFirestore() async {
    try {
      final snapshot =
          await db.collection('users').doc(userID).collection('alarms').get();
      final List<Alarm> alarms = snapshot.docs.map((doc) {
        final data = doc.data();
        return Alarm(
          data['time'] ?? '',
          snooze: data['snooze'] ?? true,
          vibration: data['vibration'] ?? true,
          label: data['label'] ?? '',
          selectedWeekdays: data['selectedWeekdays'] ?? [], // 曜日情報を取得
        );
      }).toList();

      setState(() {
        taimList = alarms;
      });
    } catch (e) {
      print('データの取得中にエラーが発生しました: $e');
    }
  }

  void _raberuAlertDialog() async {
    if (raberu == true) {
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
              maxLength: 10,
            ),
            actions: <Widget>[
              TextButton(
                child: Text('キャンセル'),
                onPressed: () {
                  setState(() {
                    raberu = false;
                  });
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  setState(() {
                    _userInput = textFieldController.text;
                    raberu = true;
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
    if (mounted) {
      var now = DateTime.now();
      var dateFormat = DateFormat('HH:mm:ss EEEE', 'ja');
      var timeString = dateFormat.format(now);
      print('現在の時刻: $timeString');

      List<Alarm> alarmsToRemove = [];

      for (int i = 0; i < taimList.length; ++i) {
        var alarmTime = DateFormat("HH:mm EEEE", 'ja').parse(taimList[i].time);

        // 曜日の一致も確認する
        if (now.hour == alarmTime.hour &&
            now.minute == alarmTime.minute &&
            taimList[i].selectedWeekdays[now.weekday - 1]) {
          print('アラームの時刻と曜日が一致: ${taimList[i].time}');
          print('アラームがトリガーされました！');

          if (!taimList[i].silent) {
            if (taimList[i].snooze) {
              audioPlayer.play(AssetSource(MP3));
              print(taimList[i].label);
              print('月火水木金土日'[(today.weekday - 1) % 7]);
              setNotification(
                  taimList[i].label.isNotEmpty ? taimList[i].label : 'アラーム',
                  ' ${now.hour}:${now.minute}');
              _setSnoozeAlarm(taimList[i]);
              alarmsToRemove.add(taimList[i]);
            }

            if (!taimList[i].snooze) {
              audioPlayer.play(AssetSource(MP3));
              setNotification(
                  taimList[i].label.isNotEmpty ? taimList[i].label : 'アラーム',
                  ' ${now.hour}:${now.minute}');
              alarmsToRemove.add(taimList[i]);
            }
          }

          if (taimList[i].silent) {
            if (taimList[i].snooze) {
              setNotification(
                  taimList[i].label.isNotEmpty ? taimList[i].label : 'アラーム',
                  ' ${now.hour}:${now.minute}');
              _setSnoozeAlarm(taimList[i]);
              alarmsToRemove.add(taimList[i]);
              print('沈黙中');
              print('月火水木金土日'[(today.weekday - 1) % 7]);
            }

            if (!taimList[i].snooze) {
              setNotification(
                  taimList[i].label.isNotEmpty ? taimList[i].label : 'アラーム',
                  ' ${now.hour}:${now.minute}');
              alarmsToRemove.add(taimList[i]);
              print('沈黙中');
              print('月火水木金土日'[(today.weekday - 1) % 7]);
            }
          }

          if (taimList[i].vibration) {
            Vibration.vibrate(duration: 1000);
            print('バイブレーション中');
          }
          print('アラームがトリガーされました！');
        }
      }

      for (var alarm in alarmsToRemove) {
        if (mounted) {
          setState(() {
            taimList.remove(alarm);
          });
        }
        _removeAlarmFromDatabase(alarm);
      }
    }
  }

  void _setSnoozeAlarm(Alarm alarm) {
    var now = DateTime.now();
    var nextAlarmTime = now.add(Duration(minutes: 5));
    var formattedNextAlarmTime =
        DateFormat("HH:mm EEEE", 'ja').format(nextAlarmTime);

    List<bool> selectedWeekdays = alarm.selectedWeekdays; // オリジナルのアラームの曜日情報を取得

    taimList.add(Alarm(
      formattedNextAlarmTime,
      snooze: snooze,
      vibration: vibration,
      label: alarm.label,
      silent: alarm.silent,
      selectedWeekdays: selectedWeekdays, // スヌーズアラームにも同じ曜日情報を渡す
    ));

    // 新しいアラームのデータベースへの保存
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
      String alarmLabel = _userInput;
      bool isSilent = Silent;

      List<bool> selectedWeekdays = week
          ? List.from(weekdays)
          : [false, false, false, false, false, false, false];

      for (var existingAlarm in taimList) {
        if (existingAlarm.time == _selectedAlarmTime &&
            ListEquality()
                .equals(existingAlarm.selectedWeekdays, selectedWeekdays)) {
          print('同じ時刻と曜日のアラームはすでに存在します');
          return;
        }
      }

      if (selectedWeekdays.every((day) => !day)) {
        selectedWeekdays[today.weekday - 1] = true;
      }

      widget.onWeekdaysSelected(selectedWeekdays);

      Alarm newAlarm = Alarm(
        alarmTime,
        snooze: snooze,
        vibration: vibration,
        silent: isSilent,
        label: alarmLabel,
        selectedWeekdays: selectedWeekdays,
      );

      taimList.add(newAlarm);
      _saveAlarmToDatabase(newAlarm);

      print('選択された曜日: ${_formatSelectedWeekdays(selectedWeekdays)}');

      _selectedAlarmTime = '';
      _userInput = '';
      weekdays = [false, false, false, false, false, false, false];
      raberu = false;
      Silent = false;
      week = false;
    });
  }

  void _removeAlarm(int index) {
    setState(() {
      if (index >= 0 && index < taimList.length) {
        audioPlayer.play(AssetSource(MMP3));
        _removeAlarmFromDatabase(taimList[index]);
        taimList.removeAt(index);
        print('$taimList');
      } else {
        print('無効なインデックスが指定されました');
      }
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
        'selectedWeekdays': alarm.selectedWeekdays, // 曜日情報を保存
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
        title: Text(''),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 200.0,
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: DateTime.now(),
                      use24hFormat: true,
                      onDateTimeChanged: (DateTime dateTime) {
                        setState(() {
                          _selectedAlarmTime =
                              DateFormat("HH:mm EEEE", 'ja').format(dateTime);
                        });
                      },
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: snooze,
                      onChanged: (value) {
                        setState(() {
                          Vibration.vibrate(duration: 1000);
                          snooze = value!;
                        });
                      },
                      activeColor: Colors.yellow,
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
                        });
                      },
                      activeColor: Colors.yellow,
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
                      value: raberu,
                      onChanged: (value) {
                        setState(() {
                          raberu = value!;
                          _raberuAlertDialog();
                        });
                      },
                      activeColor: Colors.yellow,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(raberu ? " $_userInput" : "ラベル "),
                    Checkbox(
                      value: Silent,
                      onChanged: (value) {
                        setState(() {
                          Silent = value!;
                        });
                      },
                      activeColor: Colors.yellow,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(Silent ? "サイレント " : "サイレント "),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Checkbox(
                    //   value: _showDatePicker,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       _showDatePicker = value!;
                    //     });

                    //     if (_showDatePicker) {
                    //       _selectDate(context);
                    //     }
                    //   },
                    //   activeColor: Colors.black,
                    // ),
                    // SizedBox(
                    //   height: 10,
                    // ),
                    // Text(_showDatePicker ? "$_selectedAlarmTime" : "日付 : OFF　"),
                    Checkbox(
                      value: week,
                      onChanged: (value) {
                        setState(() {
                          week = value!;
                          if (week) {
                            _selectWeekdays();
                          }
                        });
                      },
                      activeColor: Colors.yellow,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(week
                        ? "曜日 : ${_formatSelectedWeekdays(weekdays)}"
                        : "曜日 : OFF　"),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedAlarmTime.isNotEmpty) {
                      _setAlarm();
                      print('$_selectedAlarmTime にアラームを設定しました');
                      print('$taimList');
                      weekdays = [
                        false,
                        false,
                        false,
                        false,
                        false,
                        false,
                        false
                      ];
                      raberu = false;
                      Silent = false;
                      week = false;
                    } else {
                      print("アラーム時刻を選択してください");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                  ),
                  child: Text(
                    'アラームを設定する',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: taimList.map((alarm) {
                  return ListTile(
                    title: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.yellow,
                      ),
                      child: Text(
                        '${alarm.label}   $_userInput${DateFormat("HH:mm", 'ja').format(DateFormat("HH:mm EEEE", 'ja').parse(alarm.time))} (スヌーズ: ${alarm.snooze ? 'ON' : 'OFF'}) ${alarm.silent ? 'サイレント' : ''} ${_formatSelectedWeekdays(alarm.selectedWeekdays)}',
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.yellow),
                      onPressed: () {
                        int index = taimList.indexOf(alarm);
                        if (index != -1) {
                          _removeAlarm(index);
                          print('$taimList');
                        } else {
                          print('要素が見つかりませんでした');
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
