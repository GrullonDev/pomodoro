import 'package:flutter/material.dart';
import 'package:pomodoro/core/data/session_repository.dart';
import 'package:pomodoro/core/data/preset_profile.dart';
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
  String? _presetKey;
  bool? _dark;
  double? _tickVol;
  bool? _vibration;
  bool? _haptic;
  String? _alarm;
  int? _alarmDur;
  bool? _widgetEnabled;
  bool? _notifActions;
  bool? _kbShortcuts;
  bool? _wearable;

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
  final preset = await _repo.getSelectedPreset();
  final dark = await _repo.isThemeDarkEnabled();
  final vol = await _repo.getTickingVolume();
  final vib = await _repo.isVibrationEnabled();
  final hap = await _repo.isHapticEnabled();
  final alarm = await _repo.getAlarmSound();
  final ad = await _repo.getAlarmDurationSeconds();
  final widget = await _repo.isHomeWidgetEnabled();
  final notifActions = await _repo.isNotificationActionsEnabled();
  final kb = await _repo.isKeyboardShortcutsEnabled();
  final wear = await _repo.isWearableSupportEnabled();
    if (mounted) {
      setState(() {
        _persistent = v;
        _last5 = l5;
        _last5Sound = l5s;
        _last5Flash = l5f;
    _presetKey = preset;
    _dark = dark;
    _tickVol = vol;
    _vibration = vib;
    _haptic = hap;
    _alarm = alarm;
    _alarmDur = ad;
    _widgetEnabled = widget;
    _notifActions = notifActions;
    _kbShortcuts = kb;
    _wearable = wear;
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
      body: _persistent == null || _presetKey == null || _dark == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(title: const Text('Preset Profiles')),
                ...PresetProfile.defaults().map((p) {
                  return RadioListTile<String>(
                    value: p.key,
                    groupValue: _presetKey,
                    title: Text(p.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text('${p.workMinutes}m / ${p.shortBreakMinutes}m',
                        style: const TextStyle(color: Colors.white54)),
                    onChanged: (v) async {
                      if (v == null) return;
                      await _repo.setSelectedPreset(v);
                      // If not custom, apply preset long break duration as preference
                      if (v != PresetProfile.custom.key) {
                        final p = PresetProfile.defaults().firstWhere(
                            (e) => e.key == v,
                            orElse: () => PresetProfile.custom);
                        await _repo.setLongBreakDurationMinutes(p.longBreakMinutes);
                      }
                      setState(() => _presetKey = v);
                    },
                  );
                }).toList(),
                const Divider(),
                // Preserve existing persistent notification toggle
                SwitchListTile(
                  value: _persistent ?? true,
                  onChanged: (v) async {
                    await _repo.setPersistentNotificationEnabled(v);
                    setState(() => _persistent = v);
                  },
                  title: Text(t.settingsPersistentNotif,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(t.settingsPersistentNotifDesc,
                      style: const TextStyle(color: Colors.white54)),
                  activeColor: Colors.greenAccent,
                ),
                const Divider(),
                if (_last5 != null)
                  SwitchListTile(
                    value: _last5!,
                    onChanged: (v) async {
                      await _repo.setLast5AlertEnabled(v);
                      setState(() => _last5 = v);
                    },
                    title: Text(t.last5AlertTitle,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(t.last5AlertDesc,
                        style: const TextStyle(color: Colors.white54)),
                    activeColor: Colors.greenAccent,
                  ),
                if (_last5Sound != null)
                  SwitchListTile(
                    value: _last5Sound!,
                    onChanged: (v) async {
                      await _repo.setLast5SoundEnabled(v);
                      setState(() => _last5Sound = v);
                    },
                    title: Text(t.last5SoundTitle,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(t.last5SoundDesc,
                        style: const TextStyle(color: Colors.white54)),
                    activeColor: Colors.greenAccent,
                  ),
                if (_last5Flash != null)
                  SwitchListTile(
                    value: _last5Flash!,
                    onChanged: (v) async {
                      await _repo.setLast5FlashEnabled(v);
                      setState(() => _last5Flash = v);
                    },
                    title: Text(t.last5FlashTitle,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(t.last5FlashDesc,
                        style: const TextStyle(color: Colors.white54)),
                    activeColor: Colors.greenAccent,
                  ),

                const Divider(),
                SwitchListTile(
                  title: const Text('Dark Theme'),
                  value: _dark!,
                  onChanged: (v) async {
                    await _repo.setThemeDarkEnabled(v);
                    setState(() => _dark = v);
                  },
                ),
                ListTile(
                  title: const Text('Primary Color'),
                  subtitle: const Text('Pick a primary color (soon)'),
                  onTap: () {},
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Ticking Sound'),
                  value: (_tickVol ?? 0) > 0,
                  onChanged: (v) async {
                    await _repo.setTickingSoundEnabled(v);
                    setState(() => _tickVol = v ? 0.5 : 0.0);
                  },
                ),
                ListTile(
                  title: const Text('Tick volume'),
                  subtitle: Slider(
                    value: _tickVol ?? 0.5,
                    min: 0,
                    max: 1,
                    onChanged: (val) async {
                      await _repo.setTickingVolume(val);
                      setState(() => _tickVol = val);
                    },
                  ),
                ),
                SwitchListTile(
                  title: const Text('Vibration'),
                  value: _vibration!,
                  onChanged: (v) async {
                    await _repo.setVibrationEnabled(v);
                    setState(() => _vibration = v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Haptic Feedback'),
                  value: _haptic!,
                  onChanged: (v) async {
                    await _repo.setHapticEnabled(v);
                    setState(() => _haptic = v);
                  },
                ),
                const Divider(),
                ListTile(
                  title: const Text('Alarm Sound'),
                  subtitle: Text(_alarm ?? 'default'),
                  onTap: () {},
                ),
                ListTile(
                  title: const Text('Alarm Duration (s)'),
                  subtitle: Text('${_alarmDur ?? 5} s'),
                  onTap: () async {
                    final next = ((_alarmDur ?? 5) % 10) + 1;
                    await _repo.setAlarmDurationSeconds(next);
                    setState(() => _alarmDur = next);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Home Widget Enabled'),
                  value: _widgetEnabled ?? true,
                  onChanged: (v) async {
                    await _repo.setHomeWidgetEnabled(v);
                    setState(() => _widgetEnabled = v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Notification Actions'),
                  value: _notifActions ?? true,
                  onChanged: (v) async {
                    await _repo.setNotificationActionsEnabled(v);
                    setState(() => _notifActions = v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Keyboard Shortcuts'),
                  value: _kbShortcuts ?? false,
                  onChanged: (v) async {
                    await _repo.setKeyboardShortcutsEnabled(v);
                    setState(() => _kbShortcuts = v);
                  },
                ),
                SwitchListTile(
                  title: const Text('Wearable Support'),
                  value: _wearable ?? false,
                  onChanged: (v) async {
                    await _repo.setWearableSupportEnabled(v);
                    setState(() => _wearable = v);
                  },
                ),
              ],
            ),
    );
  }
}
