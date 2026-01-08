class LevelCalculator {
  // Simple RPG curve: Level = 0.1 * sqrt(XP)
  // Or simpler: XP required for level L = 100 * L^2?
  // Let's use a standard linear-ish + exponential curve for mobile games.
  // Level 1: 0 XP
  // Level 2: 100 XP
  // Level 3: 300 XP
  // Level 4: 600 XP ...

  static int getLevel(int xp) {
    if (xp <= 0) return 1;
    // Inverse formula approx or simple loop for small levels
    int level = 1;
    while (xpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    // Formula: 100 * (level-1) * level / 2 -> Arithmetic series * 100?
    // Let's iterate:
    // L2 needs 100 totals.
    // L3 needs 100 + 200 = 300 total.
    // L4 needs 300 + 300 = 600 total.
    // L5 needs 600 + 400 = 1000 total.
    return 100 * (level - 1) * level ~/ 2;
    // e.g. level 2: 100 * 1 * 2 / 2 = 100.
    // level 3: 100 * 2 * 3 / 2 = 300.
    // level 5: 100 * 4 * 5 / 2 = 1000.
  }

  static double progressToNextLevel(int xp) {
    final currentLevel = getLevel(xp);
    final currentLevelBaseXp = xpForLevel(currentLevel);
    final nextLevelXp = xpForLevel(currentLevel + 1);
    final needed = nextLevelXp - currentLevelBaseXp;
    final gained = xp - currentLevelBaseXp;
    if (needed == 0) return 1.0;
    return (gained / needed).clamp(0.0, 1.0);
  }
}
