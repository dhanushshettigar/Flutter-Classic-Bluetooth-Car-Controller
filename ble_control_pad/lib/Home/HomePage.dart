import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:ble_control_pad/Constants/Constants.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:ble_control_pad/ConnectionPage/Connect.dart';
import 'package:control_pad/control_pad.dart';
import 'package:ble_control_pad/ConnectionPage/infopage.dart';
import 'package:ble_control_pad/global.dart' as global;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';

enum TtsState { playing, stopped, paused, continued }

class MainPage extends StatefulWidget {
  final BluetoothDevice server;

  MainPage({@required this.server});
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  final _controller04 = AdvancedSwitchController();
  BluetoothConnection connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;
  bool isDisconnecting = false;
  double inputend = -0.9;
  double inputstart = 0;
  double outputend = 10;
  double outputstart = 0;
  String _messageBuffer = '';
  Timer stoptimer;
  bool timeron = false;
  FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  @override
  void initState() {
    super.initState();
    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
        Fluttertoast.showToast(
            msg: "Connected",
            gravity: ToastGravity.CENTER,
            toastLength: Toast.LENGTH_SHORT,
            timeInSecForIosWeb: 2);
      });
      _controller04.addListener(() {
        final currentValue = _controller04.value;
        currentValue == true ? _vehicleon() : _vehicleoff();
      });
      connection.input.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
    initTts();
  }

  initTts() {
    flutterTts = FlutterTts();

    if (isAndroid) {
      _getDefaultEngine();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });
  }

  void _vehicleon() {
    _sendMessage("O");
    _starttimer();
  }

  void _vehicleoff() {
    _sendMessage("N");
    _stoptimer();
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }
    flutterTts.stop();
    stoptimer.cancel();
    _controller04.dispose();
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isConnecting ? 'Connecting...' : 'Robo Controls',
          style: kTitleStyle,
        ),
        leading: null,
        actions: [
          IconButton(
            icon: Icon(
              Icons.bluetooth,
              color: isConnected == true ? Colors.green : Colors.red,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ConnectPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.info,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InfoPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.fullscreen,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                if (MediaQuery.of(context).orientation ==
                    Orientation.portrait) {
                  WidgetsFlutterBinding.ensureInitialized();
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ]);
                } else {
                  WidgetsFlutterBinding.ensureInitialized();
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitDown,
                    DeviceOrientation.portraitUp,
                  ]);
                }
              });
            },
          ),
        ],
      ),
      body: DoubleBackToCloseApp(
        snackBar: const SnackBar(
          content: Text('Tap back again to leave'),
        ),
        child: _getorientation(context),
      ),
    );
  }

// ignore: missing_return
  Widget _getorientation(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 50,
                    child: Center(
                        child: Text(global.inmessage,
                            style: TextStyle(fontSize: 15))),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildLabel("Vehicle"),
                    AdvancedSwitch(
                      activeChild: Text('ON'),
                      inactiveChild: Text('OFF'),
                      borderRadius: BorderRadius.circular(5),
                      width: 76,
                      controller: _controller04,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: PadButtonsView(
                  padButtonPressedCallback: (buttonIndex, gesture) {
                    setState(() {
                      buttonIndex == 0
                          ? _sendMessage(global.commands[0])
                          : buttonIndex == 1
                              ? _sendMessage(global.commands[1])
                              : buttonIndex == 2
                                  ? _sendMessage(global.commands[2])
                                  : buttonIndex == 3
                                      ? _sendMessage(global.commands[3])
                                      // ignore: unnecessary_statements
                                      : null;
                    });
                  },
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: JoystickView(
                    interval: Duration(milliseconds: 50),
                    onDirectionChanged:
                        (double degrees, double distanceFromCenter) {
                      double radians = degrees * pi / 180;
                      double x = cos(radians) * distanceFromCenter;
                      double y = sin(radians) * distanceFromCenter;
                      double inputrange = inputend - inputstart;
                      double outputrange = outputend - outputstart;
                      double outputx =
                          (x - inputstart) * outputrange / inputrange +
                              outputstart;
                      double outputy =
                          (y - inputstart) * outputrange / inputrange +
                              outputstart;
                      // print('X=${outputx.round()},Y=${outputy.round()}');
                      _processJoyPadv(outputx, outputy);
                    }),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: PadButtonsView(
                      padButtonPressedCallback: (buttonIndex, gesture) {
                        buttonIndex == 0
                            ? _sendMessage(global.commands[0])
                            : buttonIndex == 1
                                ? _sendMessage(global.commands[1])
                                : buttonIndex == 2
                                    ? _sendMessage(global.commands[2])
                                    : buttonIndex == 3
                                        ? _sendMessage(global.commands[3])
                                        // ignore: unnecessary_statements
                                        : null;
                      },
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: SizedBox(
                        width: 200,
                        height: 50,
                        child: Center(
                            child: Text(global.inmessage,
                                style: TextStyle(fontSize: 15))),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 80,
                  ),
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLabel("Vehicle"),
                        AdvancedSwitch(
                          activeChild: Text('ON'),
                          inactiveChild: Text('OFF'),
                          borderRadius: BorderRadius.circular(5),
                          width: 76,
                          controller: _controller04,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: JoystickView(
                    interval: Duration(milliseconds: 50),
                    onDirectionChanged:
                        (double degrees, double distanceFromCenter) async {
                      double radians = degrees * pi / 180;
                      double x = cos(radians) * distanceFromCenter;
                      double y = sin(radians) * distanceFromCenter;
                      double inputrange = inputend - inputstart;
                      double outputrange = outputend - outputstart;
                      double outputx =
                          (x - inputstart) * outputrange / inputrange +
                              outputstart;
                      double outputy =
                          (y - inputstart) * outputrange / inputrange +
                              outputstart;
                      //print('X=${outputx.round()},Y=${outputy.round()}');
                      _processJoyPadv(outputx, outputy);
                    }),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildLabel(String value) {
    return Container(
      margin: EdgeInsets.only(
        top: 5,
        bottom: 5,
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 10,
          color: Colors.black,
        ),
      ),
    );
  }

  _sendMessage(String text) async {
    text = text.trim();
    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text));
        await connection.output.allSent;
      } catch (e) {
        // Ignore error, but notify state
        setState(() {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => ConnectPage()));
        });
      }
    }
  }

  void _processJoyPadv(double x, double y) {
    if (x.round() > 5) {
      _stoptimer();
      _sendMessage(global.commands[4]);
    } else if (x.round() < -5) {
      _stoptimer();
      _sendMessage(global.commands[5]);
    } else if (y.round() > 5) {
      _stoptimer();
      _sendMessage(global.commands[6]);
    } else if (y.round() < -5) {
      _stoptimer();
      _sendMessage(global.commands[7]);
    } else {
      _starttimer();
    }
  }

  void _starttimer() {
    if (timeron == false) {
      timeron = true;
      stoptimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
        _sendMessage(global.commands[8]);
      });
    }
  }

  void _stoptimer() {
    if (timeron == true) {
      timeron = false;
      stoptimer.cancel();
    }
  }

  void _onDataReceived(Uint8List data) {
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }
    //end character
    int index = buffer.indexOf('@'.codeUnitAt(0));
    String dataString = String.fromCharCodes(buffer);
    if (index > 0) {
      _messageBuffer += dataString.substring(0, index);
      print(_messageBuffer);
      setState(() {
        global.inmessage = _messageBuffer;
      });
      _messageBuffer = '';
      _speak();
    } else {
      _messageBuffer = dataString;
    }
  }

  Future _speak() async {
    await flutterTts.setVolume(1);
    await flutterTts.setSpeechRate(1);
    await flutterTts.setPitch(0.5);

    if (global.inmessage != null) {
      if (global.inmessage.isNotEmpty) {
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(global.inmessage);
      }
    }
  }
}
