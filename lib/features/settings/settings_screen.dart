import 'package:flutter/material.dart';

import 'package:pomodoro/core/data/preset_profile.dart';
import 'package:pomodoro/core/data/session_repository.dart'; // retains other timer related settings
import 'package:pomodoro/core/di/service_locator.dart';
import 'package:pomodoro/core/theme/locale_controller.dart';
import 'package:pomodoro/core/theme/theme_controller.dart';
import 'package:pomodoro/core/timer/timer_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/utils/audio_service.dart';
import 'package:pomodoro/core/auth/biometric_service.dart'; // Add import

import 'package:pomodoro/features/integrations/calendar/calendar_service.dart';
import 'package:device_calendar/device_calendar.dart';

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
  String? _focusTrack;
  bool? _biometricEnabled;

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
    var preset = await ServiceLocator.I.settingsRepository.getSelectedPreset();
    // Si aún no hay un preset seleccionado, usar por defecto 'work'
    preset ??= PresetProfile.work.key;
    final dark = await ServiceLocator.I.settingsRepository.isThemeDarkEnabled();
    final vol = await _repo.getTickingVolume();
    final vib = await _repo.isVibrationEnabled();
    final hap = await _repo.isHapticEnabled();
    final alarm = await _repo.getAlarmSound();
    final ad = await _repo.getAlarmDurationSeconds();
    final widget = await _repo.isHomeWidgetEnabled();
    final notifActions = await _repo.isNotificationActionsEnabled();
    final kb = await _repo.isKeyboardShortcutsEnabled();
    final wear = await _repo.isWearableSupportEnabled();
    final bio = await _repo.isBiometricEnabled();
    // focus track
    try {
      _focusTrack = await AudioService.instance.getFocusTrack();
    } catch (_) {}
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
        _focusTrack = _focusTrack;
        _biometricEnabled = bio;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          title: Text(t.settings, style: TextStyle(color: scheme.primary))),
      body: _persistent == null || _presetKey == null || _dark == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                    title: Text('Preset Profiles',
                        style: TextStyle(color: scheme.primary))),
                ...PresetProfile.defaults().map((p) {
                  final isSelected = _presetKey == p.key;
                  final baseColor =
                      Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.black;
                  return RadioListTile<String>(
                    value: p.key,
                    groupValue: _presetKey,
                    activeColor: scheme.primary,
                    title: Text(p.name,
                        style: TextStyle(
                          color: baseColor.withValues(
                              alpha: isSelected ? 0.95 : 0.78),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        )),
                    subtitle: Text(
                        '${p.workMinutes}m / ${p.shortBreakMinutes}m',
                        style: TextStyle(
                            color: baseColor.withValues(alpha: 0.55))),
                    onChanged: (v) async {
                      if (v == null) return;
                      await ServiceLocator.I.settingsRepository
                          .setSelectedPreset(v);
                      PresetProfile selected = PresetProfile.custom;
                      if (v != PresetProfile.custom.key) {
                        selected = PresetProfile.defaults().firstWhere(
                          (e) => e.key == v,
                          orElse: () => PresetProfile.custom,
                        );
                        await _repo.setLongBreakDurationMinutes(
                            selected.longBreakMinutes);
                      }
                      setState(() => _presetKey = v);

                      // Navegar automáticamente al cronómetro iniciando la sesión.
                      // Suponemos 4 sesiones por defecto (ajusta si quieres hacerlo configurable).
                      if (mounted) {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration:
                                const Duration(milliseconds: 600),
                            pageBuilder: (context, animation, secondary) {
                              return FadeTransition(
                                opacity: animation,
                                child: TimerScreen(
                                  workMinutes: selected.workMinutes,
                                  breakMinutes: selected.shortBreakMinutes,
                                  sessions: 4,
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                  );
                }),
                const Divider(),
                // Preserve existing persistent notification toggle
                SwitchListTile(
                  value: _persistent ?? true,
                  onChanged: (v) async {
                    await _repo.setPersistentNotificationEnabled(v);
                    setState(() => _persistent = v);
                  },
                  title: Text(t.settingsPersistentNotif,
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  subtitle: Text(t.settingsPersistentNotifDesc,
                      style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.55))),
                  activeColor: scheme.primary,
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
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color)),
                    subtitle: Text(t.last5AlertDesc,
                        style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.55))),
                    activeColor: scheme.primary,
                  ),
                if (_last5Sound != null)
                  SwitchListTile(
                    value: _last5Sound!,
                    onChanged: (v) async {
                      await _repo.setLast5SoundEnabled(v);
                      setState(() => _last5Sound = v);
                    },
                    title: Text(t.last5SoundTitle,
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color)),
                    subtitle: Text(t.last5SoundDesc,
                        style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.55))),
                    activeColor: scheme.primary,
                  ),
                if (_last5Flash != null)
                  SwitchListTile(
                    value: _last5Flash!,
                    onChanged: (v) async {
                      await _repo.setLast5FlashEnabled(v);
                      setState(() => _last5Flash = v);
                    },
                    title: Text(t.last5FlashTitle,
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color)),
                    subtitle: Text(t.last5FlashDesc,
                        style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.55))),
                    activeColor: scheme.primary,
                  ),

                const Divider(),
                SwitchListTile(
                  title: Text('Modo oscuro',
                      style: TextStyle(color: scheme.primary)),
                  value: _dark!,
                  onChanged: (v) async {
                    await ThemeController.instance.setDark(v);
                    setState(() => _dark = v);
                  },
                  activeColor: scheme.primary,
                ),
                ListTile(
                  title: const Text('Primary Color'),
                  subtitle: const Text('Pick a primary color (soon)'),
                  onTap: () {},
                ),
                const Divider(),
                SwitchListTile(
                  title: Text('Ticking Sound',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  value: (_tickVol ?? 0) > 0,
                  onChanged: (v) async {
                    await _repo.setTickingSoundEnabled(v);
                    setState(() => _tickVol = v ? 0.5 : 0.0);
                  },
                ),
                ListTile(
                  title: Text('Tick volume',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
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
                ListTile(
                  title: Text('Focus track',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  subtitle: Text(
                      _focusTrack?.split('/').last ?? 'cronometro.mp3',
                      style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.65))),
                  onTap: () async {
                    final tracks =
                        await AudioService.instance.availableFocusTracks();
                    final selected = await showModalBottomSheet<String>(
                        context: context,
                        builder: (ctx) => SafeArea(
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  ...tracks.map((tPath) => ListTile(
                                        title: Text(tPath.split('/').last),
                                        trailing: tPath == _focusTrack
                                            ? const Icon(Icons.check,
                                                color: Colors.green)
                                            : null,
                                        onTap: () => Navigator.pop(ctx, tPath),
                                      )),
                                  const Divider(),
                                  ListTile(
                                    title: const Text('Cancelar'),
                                    onTap: () => Navigator.pop(ctx),
                                  )
                                ],
                              ),
                            ));
                    if (selected != null && selected.isNotEmpty) {
                      await AudioService.instance.setFocusTrack(selected);
                      setState(() => _focusTrack = selected);
                    }
                  },
                ),
                SwitchListTile(
                  title: Text('Vibration',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  value: _vibration!,
                  onChanged: (v) async {
                    await _repo.setVibrationEnabled(v);
                    setState(() => _vibration = v);
                  },
                ),
                SwitchListTile(
                  title: Text('Haptic Feedback',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  value: _haptic!,
                  onChanged: (v) async {
                    await _repo.setHapticEnabled(v);
                    setState(() => _haptic = v);
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text('Language',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  subtitle: ValueListenableBuilder<Locale?>(
                      valueListenable: LocaleController.instance.locale,
                      builder: (_, loc, __) => Text(
                          loc?.languageCode == null
                              ? 'System'
                              : (loc!.languageCode == 'es'
                                  ? 'Español'
                                  : 'English'),
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.65)))),
                  onTap: () async {
                    final selected = await showModalBottomSheet<String>(
                        context: context,
                        builder: (ctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text('System'),
                                    onTap: () => Navigator.pop(ctx, 'system'),
                                  ),
                                  ListTile(
                                    title: const Text('English'),
                                    onTap: () => Navigator.pop(ctx, 'en'),
                                  ),
                                  ListTile(
                                    title: const Text('Español'),
                                    onTap: () => Navigator.pop(ctx, 'es'),
                                  ),
                                ],
                              ),
                            ));
                    if (selected == null) return;
                    if (selected == 'system') {
                      await LocaleController.instance.setLocale(null);
                    } else {
                      await LocaleController.instance
                          .setLocale(Locale(selected));
                    }
                    if (mounted) setState(() {});
                  },
                ),
                const Divider(),
                ListTile(
                  title: Text('Alarm Sound',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  subtitle: Text(_alarm ?? 'default',
                      style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.65))),
                  onTap: () {},
                ),
                ListTile(
                  title: Text('Alarm Duration (s)',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  subtitle: Text('${_alarmDur ?? 5} s',
                      style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.65))),
                  onTap: () async {
                    final next = ((_alarmDur ?? 5) % 10) + 1;
                    await _repo.setAlarmDurationSeconds(next);
                    setState(() => _alarmDur = next);
                  },
                ),
                const Divider(),
                ListTile(
                    title: Text('Seguridad',
                        style: TextStyle(color: scheme.primary))),
                SwitchListTile(
                  title: Text('Habilitar Biometría',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  subtitle: Text(
                      'Usar huella digital o FaceID para iniciar sesión',
                      style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.55))),
                  value: _biometricEnabled ?? false,
                  onChanged: (v) async {
                    if (v) {
                      // Try to authenticate first to confirm ownership
                      final success = await BiometricService().authenticate();
                      if (success) {
                        await _repo.setBiometricEnabled(true);
                        setState(() => _biometricEnabled = true);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Autenticación fallida no se pudo activar biometría.')),
                          );
                        }
                        setState(() => _biometricEnabled = false);
                      }
                    } else {
                      await _repo.setBiometricEnabled(false);
                      setState(() => _biometricEnabled = false);
                    }
                  },
                ),
                const Divider(),
                // Calendar Integration Settings
                ListTile(
                    title: Text('Integraciones',
                        style: TextStyle(color: scheme.primary))),
                SwitchListTile(
                  title: Text('Sincronizar con Calendario',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  value: CalendarService.instance.isEnabled.value,
                  onChanged: (v) async {
                    await CalendarService.instance.setEnabled(v);
                    setState(() {});
                    // If enabled, try to fetch calendars immediately to verify permissions
                    if (v) {
                      await CalendarService.instance.retrieveCalendars();
                    }
                  },
                ),
                if (CalendarService.instance.isEnabled.value)
                  ListTile(
                    title: Text('Seleccionar Calendario',
                        style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color)),
                    subtitle: FutureBuilder<List<Calendar>>(
                      future: CalendarService.instance.retrieveCalendars(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const Text('Cargando...');
                        if (snap.data!.isEmpty)
                          return const Text('No se encontraron calendarios');
                        // Find selected name? We store ID but UI might want name.
                        // For now just "Tap to select"
                        return const Text('Toca para seleccionar');
                      },
                    ),
                    onTap: () async {
                      final calendars =
                          await CalendarService.instance.retrieveCalendars();
                      if (!mounted) return;

                      final selectedId = await showModalBottomSheet<String>(
                          context: context,
                          builder: (ctx) => SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: calendars
                                      .map((c) => ListTile(
                                            title: Text(c.name ?? 'Sin nombre'),
                                            onTap: () =>
                                                Navigator.pop(ctx, c.id),
                                          ))
                                      .toList(),
                                ),
                              ));

                      if (selectedId != null) {
                        await CalendarService.instance.setCalendar(selectedId);
                      }
                    },
                  ),
                const Divider(),
                SwitchListTile(
                  title: Text('Home Widget Enabled',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  value: _widgetEnabled ?? true,
                  onChanged: (v) async {
                    await _repo.setHomeWidgetEnabled(v);
                    setState(() => _widgetEnabled = v);
                  },
                ),
                SwitchListTile(
                  title: Text('Notification Actions',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  value: _notifActions ?? true,
                  onChanged: (v) async {
                    await _repo.setNotificationActionsEnabled(v);
                    setState(() => _notifActions = v);
                  },
                ),
                SwitchListTile(
                  title: Text('Keyboard Shortcuts',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  value: _kbShortcuts ?? false,
                  onChanged: (v) async {
                    await _repo.setKeyboardShortcutsEnabled(v);
                    setState(() => _kbShortcuts = v);
                  },
                ),
                SwitchListTile(
                  title: Text('Wearable Support',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
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
