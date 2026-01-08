import 'package:flutter/material.dart';
import 'package:pomodoro/features/audio/application/soundscape_service.dart';
import 'package:pomodoro/features/audio/data/audio_repository.dart';
import 'package:pomodoro/features/audio/domain/ambient_sound.dart';
import 'package:pomodoro/utils/glass_container.dart';

class AudioMixerSheet extends StatefulWidget {
  const AudioMixerSheet({super.key});

  @override
  State<AudioMixerSheet> createState() => _AudioMixerSheetState();
}

class _AudioMixerSheetState extends State<AudioMixerSheet> {
  final _service = SoundscapeService.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sonidos Ambientales',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal list or Grid? Grid is better for toggles.
          SizedBox(
            height: 300,
            child: ValueListenableBuilder<List<String>>(
              valueListenable: _service.activeSoundIds,
              builder: (ctx, activeIds, _) {
                return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.1,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12),
                    itemCount: AudioRepository.allSounds.length,
                    itemBuilder: (ctx, i) {
                      final sound = AudioRepository.allSounds[i];
                      final isActive = activeIds.contains(sound.id);
                      return _SoundControlCard(
                        sound: sound,
                        isActive: isActive,
                        onToggle: () => _service.toggleSound(sound),
                        onVolumeChanged: (v) => _service.setVolume(sound.id, v),
                        currentVolume: _service.getVolume(sound.id),
                      );
                    });
              },
            ),
          ),
          const SizedBox(height: 16),
          GlassContainer(
            borderRadius: 16,
            color: Colors.redAccent.withValues(alpha: 0.1),
            child: TextButton.icon(
              icon: const Icon(Icons.volume_off, color: Colors.redAccent),
              label: const Text('Detener Todo',
                  style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                _service.stopAll();
              },
            ),
          )
        ],
      ),
    );
  }
}

class _SoundControlCard extends StatelessWidget {
  final AmbientSound sound;
  final bool isActive;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChanged;
  final double currentVolume;

  const _SoundControlCard({
    required this.sound,
    required this.isActive,
    required this.onToggle,
    required this.onVolumeChanged,
    required this.currentVolume,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeColor = sound.baseColor;

    return GlassContainer(
      borderRadius: 16,
      color: isActive
          ? activeColor.withValues(alpha: 0.15)
          : scheme.surfaceVariant.withValues(alpha: 0.3),
      border: isActive
          ? Border.all(color: activeColor.withValues(alpha: 0.6))
          : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: CircleAvatar(
              backgroundColor: isActive ? activeColor : scheme.surfaceVariant,
              child: Icon(sound.icon,
                  color: isActive ? Colors.white : scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 8),
          Text(sound.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (isActive)
            SizedBox(
              height: 30,
              child: SliderTheme(
                data: SliderThemeData(
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: SliderComponentShape.noOverlay,
                  trackHeight: 2,
                ),
                child: Slider(
                  value: currentVolume,
                  activeColor: activeColor,
                  onChanged: onVolumeChanged,
                ),
              ),
            )
          else
            const SizedBox(
                height: 30,
                child: Center(
                    child: Text('Off',
                        style: TextStyle(fontSize: 10, color: Colors.grey)))),
        ],
      ),
    );
  }
}
