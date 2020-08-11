import 'dart:async';

import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:simple_pomodoro/timer_view_model_impl.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  runApp(new MyApp());
}

const iconCancel = Icons.cancel;
const iconStart = Icons.alarm;
const alarmAudioPath = "sound_alarm.mp3";

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Pomodoro',
      debugShowCheckedModeBanner: false,
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Pomodoro timer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  Icon iconTimerStart = new Icon(iconStart);
  Icon iconTimerPause = new Icon(iconCancel);
  Icon iconTimer;
  String timeInWidget = DateFormat.ms().format(TimerViewModelImpl.pomodoroTime);
  static AudioCache player = new AudioCache();
  TimerViewModelImpl viewModel;

  _MyHomePageState() {
    viewModel = new TimerViewModelImpl();
  }

  @override
  initState() {
    iconTimer = iconTimerStart;
    super.initState();
    viewModel.timerIsActive.listen(_setIconForButton);
    viewModel.timeIsOver.listen(informTimerFinished);
    viewModel.timeTillEndReadable.listen(secondChanger);
    WidgetsBinding.instance.addObserver(this);
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
      new AndroidInitializationSettings('alarm');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        selectNotification: onSelectNotification);
  }

  Future onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
  }

  void informTimerFinished(bool finished) {
    if (finished != null) {
      if (finished) {
        if (_notification == null) {
          makeNoise();
        } else {
          switch (_notification.index) {
            case 0: // resumed
              makeNoise();
              break;
            default:
              _showNotification();
              break;
          }
        }
      }
    }
  }

  void secondChanger(String timeString) {
    if (timeString != null) {
      setState(() {
        timeInWidget = timeString;
      });
    }
  }

  Future _showNotification() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        '120', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        110, 'Pomodoro', 'Time is over! Let\'s have a rest!' , platformChannelSpecifics,
        payload: 'item x');
  }

  void _setIconForButton(bool started) {
    if (started != null) {
      setState(() {
        if (started) {
          iconTimer = iconTimerPause;
        } else {
          iconTimer = iconTimerStart;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              '$timeInWidget',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        child: iconTimer,
        onPressed: _actionTimer,
        tooltip: 'Start/Stop timer',
      ),
    );
  }

  void _actionTimer() {
    viewModel.changeTimerState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  AppLifecycleState _notification;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      debugPrint("state changed to " + state.index.toString());
      _notification = state;
    });
  }

  void makeNoise() {
    debugPrint("zzzzz");
    player.play(alarmAudioPath);
  }
}
