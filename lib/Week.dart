// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'package:flutter/material.dart';

class WeekdaySelectionPage extends StatefulWidget {
  final Function(List<bool>) onWeekdaysSelected;

  const WeekdaySelectionPage({Key? key, required this.onWeekdaysSelected})
      : super(key: key);

  @override
  _WeekdaySelectionPageState createState() => _WeekdaySelectionPageState();
}

class _WeekdaySelectionPageState extends State<WeekdaySelectionPage> {
  List<bool> selectedWeekdays = [
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('曜日を選択'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          CheckboxListTile(
            title: Text('月曜日'),
            value: selectedWeekdays[0],
            onChanged: (value) {
              setState(() {
                selectedWeekdays[0] = value ?? false;
              });
            },
            activeColor: Colors.yellow,
          ),
          CheckboxListTile(
            title: Text('火曜日'),
            value: selectedWeekdays[1],
            onChanged: (value) {
              setState(() {
                selectedWeekdays[1] = value ?? false;
              });
            },
            activeColor: Colors.yellow,
          ),
          CheckboxListTile(
            title: Text('水曜日'),
            value: selectedWeekdays[2],
            onChanged: (value) {
              setState(() {
                selectedWeekdays[2] = value ?? false;
              });
            },
            activeColor: Colors.yellow,
          ),
          CheckboxListTile(
            title: Text('木曜日'),
            value: selectedWeekdays[3],
            onChanged: (value) {
              setState(() {
                selectedWeekdays[3] = value ?? false;
              });
            },
            activeColor: Colors.yellow,
          ),
          CheckboxListTile(
            title: Text('金曜日'),
            value: selectedWeekdays[4],
            onChanged: (value) {
              setState(() {
                selectedWeekdays[4] = value ?? false;
              });
            },
            activeColor: Colors.yellow,
          ),
          CheckboxListTile(
            title: Text('土曜日'),
            value: selectedWeekdays[5],
            onChanged: (value) {
              setState(() {
                selectedWeekdays[5] = value ?? false;
              });
            },
            activeColor: Colors.yellow,
          ),
          CheckboxListTile(
            title: Text('日曜日'),
            value: selectedWeekdays.length >= 7 ? selectedWeekdays[6] : false,
            onChanged: (value) {
              setState(() {
                if (selectedWeekdays.length >= 7) {
                  selectedWeekdays[6] = value ?? false;
                }
              });
            },
            activeColor: Colors.yellow,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              widget.onWeekdaysSelected(selectedWeekdays);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
            ),
            child: Text('選択完了'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          widget.onWeekdaysSelected(selectedWeekdays);
          Navigator.pop(context);
        }, // アイコンの色を黒に設定
        backgroundColor: Colors.yellow,
        child: Icon(Icons.arrow_back, color: Colors.black),
      ),
      // FloatingActionButtonを画面右下に配置
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
