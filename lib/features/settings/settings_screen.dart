import 'package:flutter/material.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _persistent;
  bool? _last5;
  bool? _last5Sound;
  bool? _last5Flash;
  final _repo = SessionRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await _repo.isPersistentNotificationEnabled();
    final l5 = await _repo.isLast5AlertEnabled();
    final l5s = await _repo.isLast5SoundEnabled();
    final l5f = await _repo.isLast5FlashEnabled();
    if (mounted) {
      setState(() {
        _persistent = v;
        _last5 = l5;
        _last5Sound = l5s;
        _last5Flash = l5f;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.black,
          title: Text(t.settings,
              style: const TextStyle(color: Colors.greenAccent))),
      body: _persistent == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  value: _persistent!,
                  onChanged: (v) async {
                    setState(() => _persistent = v);
                    await _repo.setPersistentNotificationEnabled(v);
                  },
                  title: Text(t.settingsPersistentNotif,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(t.settingsPersistentNotifDesc,
                      style: const TextStyle(color: Colors.white54)),
                  activeColor: Colors.greenAccent,
                ),
                const Divider(height: 1, color: Colors.white12),
                if (_last5 != null)
                  SwitchListTile(
                    value: _last5!,
                    onChanged: (v) async {
                      setState(() => _last5 = v);
                      await _repo.setLast5AlertEnabled(v);
                    },
                    title: Text(t.last5AlertTitle,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(t.last5AlertDesc,
                        style: const TextStyle(color: Colors.white54)),
                    activeColor: Colors.greenAccent,
                  ),
                const Divider(height: 1, color: Colors.white12),
                if (_last5Sound != null)
                  SwitchListTile(
                    value: _last5Sound!,
                    onChanged: (v) async {
                      setState(() => _last5Sound = v);
                      await _repo.setLast5SoundEnabled(v);
                    },
                    title: Text(t.last5SoundTitle,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(t.last5SoundDesc,
                        style: const TextStyle(color: Colors.white54)),
                    activeColor: Colors.greenAccent,
                  ),
                const Divider(height: 1, color: Colors.white12),
                if (_last5Flash != null)
                  SwitchListTile(
                    value: _last5Flash!,
                    onChanged: (v) async {
                      setState(() => _last5Flash = v);
                      await _repo.setLast5FlashEnabled(v);
                    },
                    title: Text(t.last5FlashTitle,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(t.last5FlashDesc,
                        style: const TextStyle(color: Colors.white54)),
                    activeColor: Colors.greenAccent,
                  ),
              ],
            ),
    );
  }
}
