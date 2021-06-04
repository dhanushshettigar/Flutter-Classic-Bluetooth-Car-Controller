import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ble_control_pad/Constants/Constants.dart';
import 'package:ble_control_pad/Home/HomePage.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:ble_control_pad/SelectBondedDevicePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ble_control_pad/global.dart' as global;

class ConnectPage extends StatefulWidget {
  @override
  _ConnectPage createState() => new _ConnectPage();
}

class _ConnectPage extends State<ConnectPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  @override
  void initState() {
    super.initState();
    _loadprofiledata();
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
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
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _saveprofiledata();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

//BLE Settings
    Widget tagList = Container(
      color: Colors.white,
      height: 210,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          ListTile(title: const Text('General')),
          SwitchListTile(
            title: const Text('Enable Bluetooth'),
            value: _bluetoothState.isEnabled,
            onChanged: (bool value) {
              // Do the request and update with the true value then
              future() async {
                // async lambda seems to not working
                if (value)
                  await FlutterBluetoothSerial.instance.requestEnable();
                else
                  await FlutterBluetoothSerial.instance.requestDisable();
              }

              future().then((_) {
                setState(() {});
              });
            },
          ),
          ListTile(
            title: ElevatedButton(
              child: const Text('Connect to paired device'),
              onPressed: () async {
                final BluetoothDevice selectedDevice =
                    await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return SelectBondedDevicePage(checkAvailability: false);
                    },
                  ),
                );

                if (selectedDevice != null) {
                  print('Connect -> selected ' + selectedDevice.address);
                  _startChat(context, selectedDevice);
                } else {
                  print('Connect -> no device selected');
                }
              },
            ),
          ),
        ],
      ),
    );
//Commands Tiles

    return new WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Connect To Device',
            style: kTitleStyle,
          ),
        ),
        body: Container(
          color: Colors.white,
          child: new Column(
            children: <Widget>[
              tagList,
            ],
          ),
          margin: EdgeInsets.all(0),
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(
          server: server,
        ),
      ),
    );
  }
}
