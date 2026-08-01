import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/player_controller.dart';

class AudioInterruptionSettingsPage extends StatelessWidget {
  const AudioInterruptionSettingsPage({super.key, required this.player});

  final PlayerController player;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: colorScheme.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: colorScheme.brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('后台打断与恢复')),
        body: AnimatedBuilder(
          animation: player,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '当你在听歌时，系统可能会遇到两类打断：'
                          '短提示音/duck，以及来电、Siri 这类强中断。'
                          '你可以在下方分别查看恢复行为的说明。',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Settings card
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: !player.audioInterruptionEnabled,
                        onChanged: (value) =>
                            player.setAudioInterruptionEnabled(!value),
                        secondary: Icon(
                          Icons.block_rounded,
                          color: colorScheme.primary,
                        ),
                        title: const Text('短提示音不打断'),
                        subtitle: const Text(
                          '短提示音来时自动降音量，结束后恢复',
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                      Divider(
                        height: 1,
                        indent: 58,
                        color: colorScheme.outlineVariant.withValues(alpha: .4),
                      ),
                      SwitchListTile.adaptive(
                        value: player.autoResumeAfterInterruption,
                        onChanged: player.setAutoResumeAfterInterruption,
                        secondary: Icon(
                          Icons.play_circle_outline_rounded,
                          color: colorScheme.primary,
                        ),
                        title: const Text('强中断后自动恢复'),
                        subtitle: const Text('来电、Siri 等结束后按之前状态恢复播放'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Compatibility notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.phonelink_setup_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '兼容性提示：vivo / iQOO 等 OriginOS 系统对安卓音频框架做了深度定制。'
                          '如果短提示音仍会打断播放，优先检查系统音频优化与省电限制。',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
