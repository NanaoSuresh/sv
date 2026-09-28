import 'package:flutter/material.dart';
import '../models/interpolation_settings.dart';
import '../models/player_state.dart';

class PlayerTopBar extends StatelessWidget {
  final String title;
  final PlayerState state;
  final VoidCallback onBack;
  final VoidCallback onMemcTap;
  final VoidCallback onAudioTap;
  final VoidCallback onSubtitleTap;
  final VoidCallback? onRotateTap;
  final VoidCallback? onStatsTap;
  final VoidCallback? onBoostFpsTap;

  const PlayerTopBar({
    super.key,
    required this.title,
    required this.state,
    required this.onBack,
    required this.onMemcTap,
    required this.onAudioTap,
    required this.onSubtitleTap,
    this.onRotateTap,
    this.onStatsTap,
    this.onBoostFpsTap,
  });

  @override
  Widget build(BuildContext context) {
    final memcOn =
        state.interpolationSettings.mode != InterpolationMode.off;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: onBack,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Subtitle track
              IconButton(
                icon: const Icon(Icons.subtitles_outlined,
                    color: Colors.white70, size: 22),
                tooltip: 'Subtitles',
                onPressed: onSubtitleTap,
              ),

              // Audio track
              IconButton(
                icon: const Icon(Icons.audiotrack_outlined,
                    color: Colors.white70, size: 22),
                tooltip: 'Audio Track',
                onPressed: onAudioTap,
              ),

              // Boost FPS
              if (onBoostFpsTap != null)
                IconButton(
                  icon: const Icon(Icons.rocket_launch_outlined,
                      color: Colors.white70, size: 22),
                  tooltip: 'Boost FPS',
                  onPressed: onBoostFpsTap,
                ),

              // Stats toggle
              if (onStatsTap != null)
                IconButton(
                  icon: const Icon(Icons.analytics_outlined,
                      color: Colors.white70, size: 22),
                  tooltip: 'Stats',
                  onPressed: onStatsTap,
                ),

              // Rotate screen
              if (onRotateTap != null)
                IconButton(
                  icon: const Icon(Icons.screen_rotation,
                      color: Colors.white70, size: 22),
                  tooltip: 'Rotate',
                  onPressed: onRotateTap,
                ),

              // MEMC badge
              GestureDetector(
                onTap: onMemcTap,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: memcOn
                        ? const Color(0xFF00D9FF).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: memcOn
                          ? const Color(0xFF00D9FF)
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    state.interpolationStatus,
                    style: TextStyle(
                      color: memcOn
                          ? const Color(0xFF00D9FF)
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
