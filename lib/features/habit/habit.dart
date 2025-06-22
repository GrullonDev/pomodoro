import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importar para usar FilteringTextInputFormatter
import 'package:pomodoro/utils/responsive/responsive.dart';
import 'package:pomodoro/utils/timer.dart';

class Habit extends StatelessWidget {
  const Habit({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    final TextEditingController workController = TextEditingController();
    final TextEditingController breakController = TextEditingController();
    final TextEditingController sessionController = TextEditingController();

    // Definir tamaños y paddings responsivos
    final double horizontalMargin = isMobile ? 10 : 30;
    final double containerPadding = isMobile ? 10 : 20;
    final double titleFontSize = isMobile ? 18 : 24;
    final double labelFontSize = isMobile ? 14 : 18;
    final double inputFontSize = isMobile ? 12 : 13;
    final double buttonFontSize = isMobile ? 16 : 20;
    final double buttonHeight = isMobile ? 40 : 50;
    final double buttonWidth = isMobile ? 120 : 150;
    final double fieldSpacing = isMobile ? 15 : 25;
    final double sectionSpacing = isMobile ? 10 : 20;
    final double bottomSpacing = isMobile ? 40 : 80;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: false,
            backgroundColor: Colors.black,
            title: Text.rich(
              TextSpan(
                text: 'Iniciar Pomodoro',
                style: TextStyle(
                  fontSize: titleFontSize,
                  color: Colors.greenAccent,
                  fontFamily: 'Arial',
                ),
              ),
            )),
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            color: Colors.black38,
            margin: EdgeInsets.all(horizontalMargin),
            padding: EdgeInsets.all(containerPadding),
            child: Column(
              children: [
                Text(
                  "Duración de trabajo",
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                SizedBox(height: sectionSpacing),
                TextField(
                  controller: workController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: inputFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]?$')),
                  ],
                  decoration: const InputDecoration(
                    fillColor: Colors.black12,
                    labelText: '(En minutos)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                  ),
                ),
                SizedBox(height: fieldSpacing),
                Text(
                  "Duración de descanso",
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                SizedBox(height: sectionSpacing),
                TextField(
                  controller: breakController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: inputFontSize,
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
                    labelText: '(En minutos)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(4.0)),
                        borderSide: BorderSide(color: Colors.white10)),
                  ),
                ),
                SizedBox(height: fieldSpacing),
                Text(
                  "Sesiones",
                  style: TextStyle(
                    fontSize: labelFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                ),
                SizedBox(height: sectionSpacing),
                TextField(
                  controller: sessionController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: inputFontSize,
                    color: Colors.white70,
                    fontFamily: 'Arial',
                  ),
                  keyboardType: TextInputType.number,
                  keyboardAppearance: Brightness.dark,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]?$')),
                  ],
                  decoration: const InputDecoration(
                    fillColor: Colors.black12,
                    labelText: '(Número de sesiones)',
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
                SizedBox(height: bottomSpacing),
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
                      minimumSize: Size(buttonWidth, buttonHeight),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side:
                            const BorderSide(color: Colors.black12, width: 2.0),
                      )),
                  child: Text(
                    "Iniciar",
                    style: TextStyle(
                      fontSize: buttonFontSize,
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
