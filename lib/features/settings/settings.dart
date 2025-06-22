import 'package:flutter/material.dart';
import 'package:pomodoro/utils/responsive/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late Future<List<MapEntry<int, String>>> _sessionDataFuture;

  @override
  void initState() {
    super.initState();
    _sessionDataFuture = _loadSessionData();
  }

  Future<List<MapEntry<int, String>>> _loadSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('time') ?? '';
    final sessions = data.split('/').asMap();
    final List<MapEntry<int, String>> sessionEntries =
        sessions.entries.toList();

    // Excluye el primer elemento si está vacío
    if (sessionEntries.isNotEmpty && sessionEntries.first.value.isEmpty) {
      sessionEntries.removeAt(0);
    }

    return sessionEntries;
  }

  Future<void> _resetTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('time', '');
    setState(() {
      _sessionDataFuture = _loadSessionData();
    });
  }

  Future<void> _showDeleteConfirmation() async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          titleTextStyle:
              const TextStyle(color: Colors.greenAccent, fontSize: 24),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.greenAccent, width: 2),
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text(
            'Delete History',
            style: TextStyle(
                color: Colors.greenAccent, fontSize: 20, fontFamily: 'Arial'),
          ),
          content: const Text(
            'Are you sure you want to delete your ENTIRE session history?',
            style: TextStyle(
                color: Colors.greenAccent, fontSize: 16, fontFamily: 'Arial'),
          ),
          actions: [
            TextButton(
              child: const Text('Yes',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Arial')),
              onPressed: () => Navigator.of(context).pop(true),
            ),
            TextButton(
              child: const Text('No',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Arial')),
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        );
      },
    );

    if (delete == true) {
      await _resetTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    // Define responsive paddings, font sizes, and card heights
    final double horizontalMargin = isMobile ? 10.0 : 40.0;
    final double cardHeight = isMobile ? 65.0 : 90.0;
    final double titleFontSize = isMobile ? 24 : 32;
    final double contentFontSize = isMobile ? 20 : 28;
    final double iconSize = isMobile ? 30 : 40;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        backgroundColor: Colors.black,
        title: Text.rich(
          TextSpan(
            text: 'Historial',
            style: TextStyle(
                fontSize: titleFontSize,
                color: Colors.greenAccent,
                fontFamily: 'Arial'),
          ),
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.only(right: isMobile ? 10.0 : 30.0),
            icon: Icon(Icons.delete_outline,
                color: Colors.greenAccent, size: iconSize),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: FutureBuilder<List<MapEntry<int, String>>>(
        future: _sessionDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No hay datos',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: titleFontSize,
                ),
              ),
            );
          } else {
            final sessionEntries = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(isMobile ? 5.0 : 20.0),
              itemCount: sessionEntries.length,
              itemBuilder: (BuildContext context, int index) {
                final session =
                    sessionEntries[sessionEntries.length - 1 - index];
                final split = session.value.split(' ');
                final date = split.length > 2 ? split[2] : 'No date';
                final sessionInfo =
                    split.length > 1 ? split[1] : 'No session info';

                return Container(
                  margin: EdgeInsets.fromLTRB(
                      horizontalMargin, 0, horizontalMargin, isMobile ? 5 : 15),
                  height: cardHeight,
                  child: Card(
                    elevation: 15,
                    shadowColor: Colors.greenAccent,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      side:
                          const BorderSide(color: Colors.greenAccent, width: 1),
                      borderRadius:
                          BorderRadius.circular(isMobile ? 25.0 : 35.0),
                    ),
                    color: Colors.black,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Center(
                            child: Text(
                              date,
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: contentFontSize,
                                  fontFamily: 'Arial'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              sessionInfo,
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: contentFontSize,
                                  fontFamily: 'Arial'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
