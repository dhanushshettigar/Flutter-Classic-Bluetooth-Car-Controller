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

enum TtsState { playing, stopped, paused, continued }

class MainPage extends StatefulWidget {
  final BluetoothDevice server;

  MainPage({@required this.server});
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothConnection connection;
  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;
  double inputend = -0.9;
  double inputstart = 0;
  double outputend = 10;
  double outputstart = 0;

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
              Padding(
                padding: EdgeInsets.all(10),
                child: Card(
                  elevation: 10,
                  color: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SizedBox(
                    width: 100,
                    height: 50,
                    child: Center(
                        child: Text(global.inmessage,
                            style: TextStyle(fontSize: 10))),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: JoystickView(onDirectionChanged:
                    (double degrees, double distanceFromCenter) {
                  double radians = degrees * pi / 180;
                  double x = cos(radians) * distanceFromCenter;
                  double y = sin(radians) * distanceFromCenter;
                  double inputrange = inputend - inputstart;
                  double outputrange = outputend - outputstart;
                  double outputx =
                      (x - inputstart) * outputrange / inputrange + outputstart;
                  double outputy =
                      (y - inputstart) * outputrange / inputrange + outputstart;
                  // print('X=${outputx.round()},Y=${outputy.round()}');
                  if (outputx.round() < -5) {
                    _sendMessage(global.commands[4]);
                  }
                  if (outputx.round() > 5) {
                    _sendMessage(global.commands[5]);
                  }
                  if (outputy.round() < -5) {
                    _sendMessage(global.commands[6]);
                  }
                  if (outputy.round() > 5) {
                    _sendMessage(global.commands[7]);
                  }
                  if (outputx.round() == 0 && outputy.round() == 0) {
                    _sendMessage(global.commands[4]);
                    //Future.delayed(Duration(milliseconds: 100), () {});
                  }
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
              Padding(
                padding: EdgeInsets.all(10),
                child: Card(
                  elevation: 10,
                  color: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SizedBox(
                    width: 100,
                    height: 50,
                    child: Center(
                        child: Text(global.inmessage,
                            style: TextStyle(fontSize: 10))),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: JoystickView(onDirectionChanged:
                    (double degrees, double distanceFromCenter) {
                  double radians = degrees * pi / 180;
                  double x = cos(radians) * distanceFromCenter;
                  double y = sin(radians) * distanceFromCenter;
                  double inputrange = inputend - inputstart;
                  double outputrange = outputend - outputstart;
                  double outputx =
                      (x - inputstart) * outputrange / inputrange + outputstart;
                  double outputy =
                      (y - inputstart) * outputrange / inputrange + outputstart;
                  // print('X=${outputx.round()},Y=${outputy.round()}');
                  if (outputx.round() < -5) {
                    _sendMessage(global.commands[4]);
                  }
                  if (outputx.round() > 5) {
                    _sendMessage(global.commands[5]);
                  }
                  if (outputy.round() < -5) {
                    _sendMessage(global.commands[6]);
                  }
                  if (outputy.round() > 5) {
                    _sendMessage(global.commands[7]);
                  }
                  if (outputx.round() == 0 && outputy.round() == 0) {
                    _sendMessage(global.commands[4]);
                    //Future.delayed(Duration(milliseconds: 100), () {});
                  }
                }),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text));
        await connection.output.allSent;
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
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
    String dataString = String.fromCharCodes(buffer);
    //print(dataString);
    setState(() {
      global.inmessage = dataString;
    });
    _speak();
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
