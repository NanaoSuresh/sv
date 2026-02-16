import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interpolation_settings.dart';
import '../models/player_state.dart';

class PlaybackControls extends StatelessWidget {
  final VoidCallback? onLockTap;

  const PlaybackControls({super.key, this.onLockTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(
      builder: (context, state, _) {
        final position = state.position;
        final duration = state.duration;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;
        final ps = state.playbackSettings;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seek bar
              Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF00D9FF),
                        inactiveTrackColor:
                            Colors.white.withValues(alpha: 0.15),
                        thumbColor: const Color(0xFF00D9FF),
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                        trackHeight: 3,
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14),
                      ),
                      child: Slider(
                        value: progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          final newPos = Duration(
                            milliseconds:
                                (value * duration.inMilliseconds).round(),
                          );
                          state.seek(newPos);
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),

              // Control buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Lock
                  _ControlButton(
                    icon: Icons.lock_open,
                    size: 20,
                    onTap: onLockTap,
                    tooltip: 'Lock',
                  ),

                  // Speed
                  _ControlButton(
                    icon: Icons.speed,
                    label: ps.speedLabel,
                    size: 20,
                    onTap: () => _showSpeedSheet(context, state),
                    tooltip: 'Speed',
                  ),

                  // Rewind 10s
                  _ControlButton(
                    icon: Icons.replay_10,
                    size: 28,
                    onTap: () {
                      final newPos =
                          position - const Duration(seconds: 10);
                      state.seek(
                          newPos < Duration.zero ? Duration.zero : newPos);
                    },
                  ),

                  // Play/Pause (larger)
                  GestureDetector(
                    onTap: state.togglePlayPause,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            const Color(0xFF00D9FF).withValues(alpha: 0.15),
                        border: Border.all(
                          color: const Color(0xFF00D9FF)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        state.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  // Forward 10s
                  _ControlButton(
                    icon: Icons.forward_10,
                    size: 28,
                    onTap: () {
                      final newPos =
                          position + const Duration(seconds: 10);
                      state
                          .seek(newPos > duration ? duration : newPos);
                    },
                  ),

                  // Aspect ratio
                  _ControlButton(
                    icon: Icons.aspect_ratio,
                    label: ps.aspectRatioLabel,
                    size: 20,
                    onTap: state.cycleAspectRatio,
                    tooltip: 'Aspect Ratio',
                  ),

                  // Loop
                  _ControlButton(
                    icon: _loopIcon(ps.loopMode),
                    size: 20,
                    onTap: state.cycleLoopMode,
                    tooltip: 'Loop: ${ps.loopLabel}',
                    highlighted: ps.loopMode != LoopMode.off,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _loopIcon(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        return Icons.repeat;
      case LoopMode.single:
        return Icons.repeat_one;
      case LoopMode.all:
        return Icons.repeat_on;
    }
  }

  void _showSpeedSheet(BuildContext context, PlayerState state) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Playback Speed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: speeds.map((s) {
                final isSelected = state.playbackSettings.speed == s;
                return ChoiceChip(
                  label: Text('${s}x'),
                  selected: isSelected,
                  selectedColor:
                      const Color(0xFF00D9FF).withValues(alpha: 0.2),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFF00D9FF)
                        : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF00D9FF)
                        : Colors.white12,
                  ),
                  onSelected: (_) {
                    state.setSpeed(s);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final double size;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool highlighted;

  const _ControlButton({
    required this.icon,
    this.label,
    required this.size,
    this.onTap,
    this.tooltip,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: highlighted ? const Color(0xFF00D9FF) : Colors.white,
            size: size,
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                label!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}


