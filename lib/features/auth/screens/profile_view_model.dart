import 'package:flutter/material.dart';
import 'package:pomodoro/core/auth/auth_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final name = TextEditingController();
  final currentPwd = TextEditingController();
  final newPwd = TextEditingController();
  final confirmPwd = TextEditingController();

  bool loadingProfile = true;
  bool saving = false;
  String? uid;
  String? email;
  String? error;
  String? pwdMessage;

  Future<void> load() async {
    loadingProfile = true;
    notifyListeners();
    final p = await AuthService.instance.currentProfile();
    uid = p['uid'];
    email = p['email'];
    name.text = p['name'] ?? '';
    loadingProfile = false;
    notifyListeners();
  }

  Future<void> saveProfile(void Function(String msg) showMessage, String msgSuccess) async {
    saving = true;
    error = null;
    notifyListeners();
    try {
      await AuthService.instance.updateDisplayName(name.text.trim());
      showMessage(msgSuccess);
    } catch (e) {
      error = e.toString();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(String mismatchMsg, String successMsg) async {
    pwdMessage = null;
    if (newPwd.text != confirmPwd.text) {
      pwdMessage = mismatchMsg;
      notifyListeners();
      return;
    }
    saving = true;
    notifyListeners();
    final err = await AuthService.instance.updatePassword(
      newPwd.text,
      currentPassword: currentPwd.text.isEmpty ? null : currentPwd.text,
    );
    saving = false;
    if (err == null) {
      pwdMessage = successMsg;
      currentPwd.clear();
      newPwd.clear();
      confirmPwd.clear();
    } else {
      pwdMessage = err;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    name.dispose();
    currentPwd.dispose();
    newPwd.dispose();
    confirmPwd.dispose();
    super.dispose();
  }
}
