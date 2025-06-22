import 'package:flutter/material.dart';
import 'package:pomodoro/utils/responsive/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Data extends StatefulWidget {
  const Data({super.key});

  @override
  State<Data> createState() => _DataState();
}

class _DataState extends State<Data> {
  SharedPreferences? _prefs;
  String _data = '';
  late Map<int, String> _sessions;
  final List<String> _dates = [];
  final List<String> _sesh = [];
  int _totalMin = 0;
  int _longestSesh = 0;
  int _seshNum = 0;
  double _avgSesh = 0;

  @override
  void initState() {
    super.initState();
    _getPrefs();
  }

  void _getPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_prefs == null) return;

      _data = _prefs?.getString('time') ?? '';
      final split = _data.split('/');

      _sessions = {for (int i = 0; i < split.length; i++) i: split[i]};
      for (int i = 1; i < _sessions.length; i++) {
        _dates.add(_sessions[i]!.split(' ')[2]);
      }
      for (int i = 1; i < _sessions.length; i++) {
        _sesh.add(_sessions[i]!.split(' ')[1]);
        _totalMin += int.parse(_sessions[i]!.split(' ')[1]);
        _seshNum++;
        if (int.parse(_sessions[i]!.split(' ')[1]) > _longestSesh) {
          _longestSesh = int.parse(_sessions[i]!.split(' ')[1]);
        }
      }
      _avgSesh = _totalMin / _seshNum;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    // Ajusta el número de columnas según el tamaño de pantalla
    final crossAxisCount = isMobile ? 1 : 2;
    final cardPadding =
        isMobile ? const EdgeInsets.all(12.0) : const EdgeInsets.all(26.0);
    final iconSize = isMobile ? 36.0 : 50.0;
    final fontSize = isMobile ? 18.0 : 24.0;
    final subtitleFontSize = isMobile ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: Colors.black,
        title: const Text.rich(
          TextSpan(
            text: 'Almacén',
            style: TextStyle(
              fontSize: 24,
              color: Colors.greenAccent,
              fontFamily: 'Arial',
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding:
              isMobile ? const EdgeInsets.all(8.0) : const EdgeInsets.all(25.0),
          child: GridView(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 2.5 : 1.2,
            ),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                clipBehavior: Clip.antiAlias,
                color: Colors.black,
                shadowColor: Colors.greenAccent,
                elevation: 15,
                child: Padding(
                  padding: cardPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_filled_outlined,
                        color: Colors.greenAccent,
                        size: iconSize,
                      ),
                      Text(_totalMin.toString(),
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Arial')),
                      Text('Total de tiempo',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: subtitleFontSize,
                              fontFamily: 'Arial',
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                clipBehavior: Clip.antiAlias,
                color: Colors.black,
                shadowColor: Colors.greenAccent,
                elevation: 15,
                child: Padding(
                  padding: cardPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.greenAccent,
                        size: iconSize,
                      ),
                      Text(_longestSesh.toString(),
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Arial')),
                      Text('sesión más larga',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: subtitleFontSize,
                              fontFamily: 'Arial',
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                clipBehavior: Clip.antiAlias,
                color: Colors.black,
                shadowColor: Colors.greenAccent,
                elevation: 15,
                child: Padding(
                  padding: cardPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: Colors.greenAccent,
                        size: iconSize - 5,
                      ),
                      Text(_seshNum.toString(),
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Arial')),
                      Text('numero de sesiones',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: subtitleFontSize,
                              fontFamily: 'Arial',
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                clipBehavior: Clip.antiAlias,
                color: Colors.black,
                shadowColor: Colors.greenAccent,
                elevation: 15,
                child: Padding(
                  padding: cardPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.greenAccent,
                        size: iconSize - 5,
                      ),
                      Text(
                          double.parse((_avgSesh).toStringAsFixed(2))
                              .toString(),
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Arial')),
                      Text('total de tiempo promedio',
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: subtitleFontSize,
                              fontFamily: 'Arial',
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
