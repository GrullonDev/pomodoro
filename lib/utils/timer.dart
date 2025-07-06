import 'dart:async';

import 'package:flutter/material.dart';

import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro/utils/notifications/notifications.dart';
import 'package:pomodoro/utils/responsive/responsive.dart';

class MyTimer extends StatefulWidget {
  const MyTimer({
    super.key,
    required this.breakTime,
    required this.workTime,
    required this.workSessions,
  });

  final String breakTime;
  final String workTime;
  final String workSessions;

  @override
  TimerState createState() => TimerState();
}

class TimerState extends State<MyTimer> {
  bool _isRunning = false;
  Duration _time = const Duration(minutes: 60);
  Duration _break = const Duration(minutes: 10);
  int _timeInt = 60;
  int _counter = 1;
  int _sessionCount = 4;
  int _timerCount = 0;
  int _currMax = 60;
  Timer? _timer;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (int.parse(widget.breakTime) <= 0 ||
            int.parse(widget.workTime) <= 0 ||
            int.parse(widget.workSessions) <= 0) {
          throw Exception('Values must be greater than 0');
        }
        _timeInt = int.parse(widget.workTime);
        _time = Duration(minutes: _timeInt);
        _break = Duration(minutes: int.parse(widget.breakTime));
        _sessionCount = int.parse(widget.workSessions);
        _currMax = _timeInt;
      } catch (e) {
        _timeInt = 60;
        _time = Duration(minutes: _timeInt);
        _break = const Duration(minutes: 10);
        _sessionCount = 4;
        final isMobile = context.isMobile;

        AnimatedSnackBar(
          builder: ((context) {
            return Container(
              padding: EdgeInsets.all(isMobile ? 6 : 16),
              color: Colors.redAccent,
              height: isMobile ? 60 : 80,
              child: Flex(
                direction: Axis.vertical,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.close,
                        size: 30,
                      ),
                      SizedBox(width: isMobile ? 10 : 20),
                      Text(
                        'Entrada no valida',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 16 : 20,
                          fontFamily: 'Arial',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: isMobile ? 20 : 50),
                      Flexible(
                        child: Text(
                          "Por favor, introduzca números válidos mayores que 0 para empezar.",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: isMobile ? 12 : 14,
                            fontFamily: 'Arial',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ).show(context);
        Navigator.pop(context);
      }
      _getPrefs();
    });
  }

  void _getPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _storeTime() async {
    String? curr = '';
    curr = _prefs?.getString('time');
    var now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);
    String formattedDate = "${date.day}-${date.month}-${date.year}";
    await _prefs!.setString(
        'time', '$curr / ${_sessionCount * _timeInt} $formattedDate');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() async {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _time = _time - const Duration(seconds: 1);
        if (_time.inSeconds <= 0) {
          if (_timerCount % 2 == 1) {
            _time = Duration(minutes: _timeInt);
            _currMax = _timeInt;
            _timerCount++;
            NotificationService.showTimerNotification(
              id: 1,
              title: 'Pomodoro',
              body: 'Comienza una nueva sesión de trabajo',
            );
          } else {
            _time = _break;
            _currMax = _break.inMinutes;
            _counter++;
            _timerCount++;
            NotificationService.showTimerNotification(
              id: 2,
              title: 'Pomodoro',
              body: 'Hora de descansar',
            );
          }
          if (_counter > _sessionCount) {
            final isMobile = context.isMobile;

            AnimatedSnackBar(
              builder: ((context) {
                return Container(
                  padding: EdgeInsets.all(isMobile ? 6 : 16),
                  color: Colors.greenAccent,
                  height: isMobile ? 60 : 80,
                  child: Flex(
                    direction: Axis.vertical,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 30,
                          ),
                          SizedBox(width: isMobile ? 10 : 20),
                          Text(
                            'Sesión Completada',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 16 : 20,
                              fontFamily: 'Arial',
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(width: isMobile ? 20 : 50),
                          Flexible(
                            child: Text(
                              'Te registraste ${_sessionCount * _timeInt} minutos.',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: isMobile ? 12 : 14,
                                fontFamily: 'Arial',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ).show(context);
            FocusManager.instance.primaryFocus?.unfocus();
            _storeTime();
            NotificationService.showTimerNotification(
              id: 3,
              title: 'Pomodoro',
              body: 'Todas las sesiones completadas',
            );
            Navigator.pop(context);
          }

          _stopTimer();
          _isRunning = false;
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      if (_isRunning) {
        _stopTimer();
      }
      _time = const Duration(minutes: 60);
      if (_timerCount % 2 == 1) {
        _time = Duration(minutes: _break.inMinutes);
      } else {
        _time = Duration(minutes: _timeInt);
      }
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int minutes = _time.inMinutes;
    final int seconds = _time.inSeconds % 60;
    String timerState = "Break";
    if (_timerCount % 2 == 0) {
      timerState = '$_counter / $_sessionCount';
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.black,
        title: const Text.rich(
          TextSpan(
            text: 'Sesión',
            style: TextStyle(
              fontSize: 24,
              color: Colors.greenAccent,
              fontFamily: 'Arial',
            ),
          ),
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 20.0),
            icon: const Icon(Icons.restart_alt,
                color: Colors.greenAccent, size: 30),
            onPressed: () {
              setState(() {
                _resetTimer();
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double size = constraints.maxWidth * 0.6;
          if (constraints.maxWidth < 600) {
            size = constraints.maxWidth * 0.8;
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      width: size,
                      height: size,
                      child: CircularProgressIndicator(
                        color: Colors.greenAccent,
                        backgroundColor: Colors.black,
                        value: _time.inSeconds / (_currMax * 60),
                        strokeWidth: 2,
                      ),
                    ),
                    Positioned(
                      top: size * 0.33,
                      left: size * 0.23,
                      child: Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: size * 0.2,
                          color: Colors.greenAccent,
                          fontFamily: 'Arial',
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: size * 0.33,
                      left: size * 0.43,
                      child: Text(
                        timerState,
                        style: TextStyle(
                          fontSize: size * 0.07,
                          color: Colors.greenAccent,
                          fontFamily: 'Arial',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_isRunning) {
              _stopTimer();
            } else {
              _startTimer();
            }
            _isRunning = !_isRunning;
          });
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.black,
        mini: false,
        child: _isRunning
            ? const Icon(
                Icons.pause,
                color: Colors.greenAccent,
                size: 35,
              )
            : const Icon(
                Icons.play_arrow,
                color: Colors.greenAccent,
                size: 35,
              ),
      ),
    );
  }
}
