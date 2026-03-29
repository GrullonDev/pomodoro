import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:pomodoro/core/data/preset_profile.dart';
import 'package:pomodoro/core/data/session_repository.dart'; // retains other timer related settings
import 'package:pomodoro/core/di/service_locator.dart';
import 'package:pomodoro/core/theme/locale_controller.dart';
import 'package:pomodoro/core/theme/theme_controller.dart';
import 'package:pomodoro/core/timer/timer_screen.dart';
import 'package:pomodoro/l10n/app_localizations.dart';
import 'package:pomodoro/utils/audio_service.dart';
import 'package:pomodoro/utils/dnd.dart';
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
  String? _themeMode;
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
  bool? _focusBlock;
  bool _dndGranted = false;

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
    final tm = await ServiceLocator.I.settingsRepository.getThemeMode();
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
    final focusBlock = await _repo.isFocusBlockEnabled();
    final dndGranted = Platform.isAndroid ? await Dnd.isPolicyGranted() : false;
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
        _themeMode = tm;
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
        _focusBlock = focusBlock;
        _dndGranted = dndGranted;
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
      body: _persistent == null || _presetKey == null || _themeMode == null
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
                ListTile(
                  title: Text('Tema visual',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                  subtitle: ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeController.instance.themeMode,
                      builder: (_, themeMode, __) {
                        String name = 'Sistema';
                        if (themeMode == ThemeMode.light) name = 'Claro';
                        if (themeMode == ThemeMode.dark) name = 'Oscuro';
                        return Text(name,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.65)));
                      }),
                  onTap: () async {
                    final selected = await showModalBottomSheet<ThemeMode>(
                        context: context,
                        builder: (ctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: const Text('Sistema'),
                                    onTap: () => Navigator.pop(ctx, ThemeMode.system),
                                  ),
                                  ListTile(
                                    title: const Text('Claro'),
                                    onTap: () => Navigator.pop(ctx, ThemeMode.light),
                                  ),
                                  ListTile(
                                    title: const Text('Oscuro'),
                                    onTap: () => Navigator.pop(ctx, ThemeMode.dark),
                                  ),
                                ],
                              ),
                            ));
                    if (selected != null) {
                      await ThemeController.instance.setMode(selected);
                      if (mounted) setState(() => _themeMode = selected.name);
                    }
                  },
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
                        if (snap.data!.isEmpty) {
                          return const Text('No se encontraron calendarios');
                        }
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
                const Divider(),
                // ── Sección Concentración ──────────────────────────────────
                ListTile(
                  leading: Icon(Icons.do_not_disturb_on_rounded,
                      color: scheme.primary),
                  title: Text('Concentración',
                      style: TextStyle(color: scheme.primary)),
                  subtitle: Text(
                    Platform.isAndroid
                        ? 'Silencia todas las notificaciones del sistema durante las sesiones de trabajo'
                        : 'Activa el modo Focus de iOS para bloquear distracciones',
                    style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.55),
                        fontSize: 12),
                  ),
                ),
                if (_focusBlock != null)
                  SwitchListTile(
                    secondary: Icon(
                      Platform.isAndroid
                          ? Icons.notifications_off_rounded
                          : Icons.phone_iphone_rounded,
                      color: (_focusBlock ?? false)
                          ? scheme.primary
                          : scheme.onSurface.withValues(alpha: 0.4),
                    ),
                    title: Text(
                      'Bloquear notificaciones al enfocar',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    subtitle: Text(
                      Platform.isAndroid
                          ? 'Activa el modo No Interrumpir automáticamente'
                          : 'Configura el modo Focus de iOS vía Atajos',
                      style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.55)),
                    ),
                    value: _focusBlock!,
                    activeColor: scheme.primary,
                    onChanged: (v) async {
                      await _repo.setFocusBlockEnabled(v);
                      setState(() => _focusBlock = v);
                      if (v && Platform.isAndroid) {
                        // Si activó y no tiene permiso DND, ofrecer abrirlo
                        final granted = await Dnd.isPolicyGranted();
                        setState(() => _dndGranted = granted);
                        if (!granted && mounted) {
                          _showAndroidDndPermissionDialog();
                        }
                      } else if (v && Platform.isIOS) {
                        if (mounted) _showIosFocusGuide();
                      }
                    },
                  ),
                // Android: estado del permiso DND
                if (Platform.isAndroid && (_focusBlock ?? false))
                  ListTile(
                    leading: Icon(
                      _dndGranted
                          ? Icons.verified_rounded
                          : Icons.warning_amber_rounded,
                      color: _dndGranted ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      _dndGranted
                          ? 'Permiso No Interrumpir concedido'
                          : 'Permiso No Interrumpir requerido',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    subtitle: Text(
                      _dndGranted
                          ? 'Tu teléfono se silenciará automáticamente al iniciar el timer'
                          : 'Sin este permiso se usará el modo silencioso de la app',
                      style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.55)),
                    ),
                    trailing: _dndGranted
                        ? null
                        : TextButton(
                            onPressed: () async {
                              await Dnd.gotoPolicySettings();
                              // Re-check after returning
                              await Future.delayed(
                                  const Duration(milliseconds: 500));
                              final granted = await Dnd.isPolicyGranted();
                              if (mounted) {
                                setState(() => _dndGranted = granted);
                              }
                            },
                            child: const Text('Conceder'),
                          ),
                  ),
                // iOS: botón para ver la guía de configuración
                if (Platform.isIOS && (_focusBlock ?? false))
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded,
                        color: Colors.blue),
                    title: Text(
                      'Cómo configurar el modo Focus',
                      style: TextStyle(
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    subtitle: Text(
                      'iOS no permite activar Focus automáticamente, pero puedes configurarlo con la app Atajos',
                      style: TextStyle(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.55)),
                    ),
                    trailing: TextButton(
                      onPressed: _showIosFocusGuide,
                      child: const Text('Ver guía'),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showAndroidDndPermissionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso No Interrumpir'),
        content: const Text(
          'Para silenciar todas las notificaciones del teléfono durante tus sesiones de trabajo, necesitas conceder acceso al modo No Interrumpir.\n\nSin este permiso, solo se silenciarán las notificaciones de esta app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await Dnd.gotoPolicySettings();
              await Future.delayed(const Duration(milliseconds: 600));
              final granted = await Dnd.isPolicyGranted();
              if (mounted) setState(() => _dndGranted = granted);
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  void _showIosFocusGuide() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(Icons.do_not_disturb_on_rounded,
                    color: Colors.purple, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bloquear distracciones en iOS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'iOS no permite que las apps activen el modo Focus automáticamente por seguridad. Usa la app Atajos para hacerlo de forma automática.',
              style: TextStyle(
                color: Theme.of(ctx)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 24),
            _iosGuideStep(
              number: '1',
              icon: Icons.phone_iphone_rounded,
              title: 'Activa un modo Focus',
              description:
                  'Ve a Ajustes > Focus y crea o activa un modo llamado "Trabajo" o usa "No Molestar".',
            ),
            _iosGuideStep(
              number: '2',
              icon: Icons.cut_rounded,
              title: 'Abre la app Atajos',
              description:
                  'Busca "Atajos" en tu iPhone. Si no la tienes, descárgala gratis desde el App Store.',
            ),
            _iosGuideStep(
              number: '3',
              icon: Icons.add_circle_outline_rounded,
              title: 'Crea un Atajo de Automatización',
              description:
                  'Toca "Automatización" → "Nueva automatización" → "App" → selecciona Pomodoro → "Se abre".',
            ),
            _iosGuideStep(
              number: '4',
              icon: Icons.do_not_disturb_on_outlined,
              title: 'Añade la acción "Activar Focus"',
              description:
                  'Busca la acción "Activar/desactivar modo Focus", elige tu modo (ej: Trabajo) y ponlo en "Activar".',
            ),
            _iosGuideStep(
              number: '5',
              icon: Icons.close_rounded,
              title: 'Desactivar al cerrar',
              description:
                  'Repite el paso 3 pero elige "Se cierra" y añade la misma acción con "Desactivar".',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Con esto, cada vez que abras Pomodoro, iOS activará automáticamente tu modo Focus silenciando todas las apps.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iosGuideStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(number,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
