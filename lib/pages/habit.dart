import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importar para usar FilteringTextInputFormatter
import 'package:pomodoro/pages/timer.dart';

class Habit extends StatelessWidget {
  const Habit({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController workController = TextEditingController();
    final TextEditingController breakController = TextEditingController();
    final TextEditingController sessionController = TextEditingController();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: false,
            backgroundColor: Colors.black,
            title: const Text.rich(
              TextSpan(
                text: 'Start session', // text for title
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.greenAccent,
                  fontFamily: 'Arial',
                ),
              ),
            )),
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            color: Colors.black38,
            margin: const EdgeInsets.all(30),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Work duration",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                const SizedBox(
                    height:
                        10), // add a space between the text and the input field
                TextField(
                  controller: workController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]?$')),
                  ],
                  decoration: const InputDecoration(
                    // filled: true,
                    fillColor: Colors.black12,
                    labelText: '(in minutes)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "Break duration",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: breakController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]?$')),
                  ],
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.black12,
                    labelText: '(in minutes)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                  ),
                ),
                const SizedBox(
                    height:
                        25), // add a space between the text and the input field
                const Text(
                  "Sessions",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: sessionController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]?$')),
                  ],
                  decoration: const InputDecoration(
                    // filled: true,
                    fillColor: Colors.black12,
                    labelText: '(number of work sessions)',
                    labelStyle: TextStyle(
                      color: Colors.white70,
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                  ),
                ),
                const SizedBox(
                    height:
                        80), // add a space between the text and the input field
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(seconds: 1),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return FadeTransition(
                          opacity: animation,
                          child: MyTimer(
                              breakTime: breakController.text,
                              workTime: workController.text,
                              workSessions: sessionController.text),
                        );
                      },
                    ),
                  ),
                  style: TextButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(150, 50),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side:
                            const BorderSide(color: Colors.black12, width: 2.0),
                      )),
                  child: const Text(
                    "Start",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Arial',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
