class PresetProfile {
  final String key;
  final String name;
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  const PresetProfile({
    required this.key,
    required this.name,
    required this.workMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
  });

  static const study = PresetProfile(
    key: 'study',
    name: 'Study',
    workMinutes: 50,
    shortBreakMinutes: 10,
    longBreakMinutes: 30,
  );

  static const work = PresetProfile(
    key: 'work',
    name: 'Work',
    workMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
  );

  static const deep = PresetProfile(
    key: 'deep',
    name: 'Deep Work',
    workMinutes: 90,
    shortBreakMinutes: 15,
    longBreakMinutes: 30,
  );

  static const custom = PresetProfile(
    key: 'custom',
    name: 'Custom',
    workMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
  );

  static List<PresetProfile> defaults() => [study, work, deep, custom];
}
