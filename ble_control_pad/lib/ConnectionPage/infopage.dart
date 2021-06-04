import 'package:flutter/material.dart';
import 'package:ble_control_pad/Constants/Constants.dart';
import 'package:ble_control_pad/ConnectionPage/Commands.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ble_control_pad/global.dart' as global;

class InfoPage extends StatefulWidget {
  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  @override
  void initState() {
    super.initState();
    _loadprofiledata();
  }

  _loadprofiledata() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.getStringList('Commands') == null) {
        global.commands = ['A', 'B', 'C', 'D', '1', '2', '3', '4'];
      } else {
        global.commands = prefs.getStringList('Commands');
      }
    });
    print("Loaded");
  }

  _saveprofiledata() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('Commands', global.commands);
    print("saved");
  }

  @override
  void dispose() {
    _saveprofiledata();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget boardView = Container(
      color: Colors.white,
      child: ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: 8,
          itemBuilder: (BuildContext context, int index) {
            return CommondsTile(
              title: "Command : ${global.commands[index]}",
              titlecommand: global.commandstitle[index],
              onSubmit: (val) {
                setState(() {
                  global.commands.removeAt(index);
                  global.commands.insert(index, val);
                });
                _saveprofiledata();
              },
            );
          }),
    );
    return new WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Commands',
            style: kTitleStyle,
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: boardView,
      ),
    );
  }
}
