import 'package:flutter/material.dart';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'package:pomodoro/features/data/data.dart';
import 'package:pomodoro/features/habit/habit.dart';
import 'package:pomodoro/features/settings/settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: SafeArea(
        child: CurvedNavigationBar(
          height: 50,
          animationCurve: Curves.easeInOut,
          backgroundColor: Colors.black,
          buttonBackgroundColor: Colors.greenAccent,
          color: Colors.greenAccent,
          animationDuration: const Duration(milliseconds: 350),
          onTap: (selectedIndex) {
            setState(() {
              index = selectedIndex;
            });
          },
          index: 1,
          items: const [
            Icon(Icons.timelapse_rounded, size: 20, color: Colors.black),
            Icon(Icons.fitbit_rounded, size: 20, color: Colors.black),
            Icon(Icons.history_rounded, size: 20, color: Colors.black),
          ],
        ),
      ),
      body: Container(
        child: getSelectedWidget(index: index),
      ),
    );
  }

  Widget getSelectedWidget({required int index}) {
    switch (index) {
      case 0:
        return const Data();
      case 2:
        return const Settings();
      default:
        return const Habit();
    }
  }
}
