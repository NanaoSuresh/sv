import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interpolation_settings.dart';
import '../models/player_state.dart';

class MemcControls extends StatelessWidget {
  final VoidCallback onClose;

  const MemcControls({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(
      builder: (context, state, _) {
        final settings = state.interpolationSettings;

        return Container(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
          child: SafeArea(
            left: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Color(0xFF00D9FF), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'MEMC Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                const Divider(color: Colors.white12),

                // Mode selection
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interpolation Mode',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildModeButton(
                        context,
                        state,
                        InterpolationMode.off,
                        'Off',
                        'Original framerate',
                        Icons.block,
                        settings,
                      ),
                      const SizedBox(height: 8),
                      _buildModeButton(
                        context,
                        state,
                        InterpolationMode.performance,
                        'Performance',
                        'Oversample interpolation',
                        Icons.speed,
                        settings,
                      ),
                      const SizedBox(height: 8),
                      _buildModeButton(
                        context,
                        state,
                        InterpolationMode.quality,
                        'Quality',
                        'Mitchell temporal scaling',
                        Icons.hd,
                        settings,
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white12),

                // Target FPS
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Target FPS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFpsButton(
                              context,
                              state,
                              TargetFps.fps60,
                              '60 FPS',
                              settings,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFpsButton(
                              context,
                              state,
                              TargetFps.fps120,
                              '120 FPS',
                              settings,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white12),

                // Motion Sensitivity
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Motion Sensitivity',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(settings.motionSensitivity * 100).round()}%',
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SliderTheme(
                        data: const SliderThemeData(
                          activeTrackColor: Color(0xFF00D9FF),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Color(0xFF00D9FF),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: settings.motionSensitivity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: (v) => state.updateInterpolation(
                              settings.copyWith(motionSensitivity: v)),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Low',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            'High',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white12),

                // Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
                      border: Border.all(
                        color:
                            const Color(0xFF00D9FF).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF00D9FF), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'MEMC generates intermediate frames using motion estimation to boost playback smoothness.',
                            style: TextStyle(
                              color:
                                  Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    PlayerState state,
    InterpolationMode mode,
    String label,
    String description,
    IconData icon,
    InterpolationSettings current,
  ) {
    final isSelected = current.mode == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => state.updateInterpolation(current.copyWith(mode: mode)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00D9FF)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            color: isSelected
                ? const Color(0xFF00D9FF).withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isSelected
                      ? const Color(0xFF00D9FF)
                      : Colors.white54,
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle,
                    color: Color(0xFF00D9FF), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFpsButton(
    BuildContext context,
    PlayerState state,
    TargetFps fps,
    String label,
    InterpolationSettings current,
  ) {
    final isSelected = current.targetFps == fps;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            state.updateInterpolation(current.copyWith(targetFps: fps)),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00D9FF)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            color: isSelected
                ? const Color(0xFF00D9FF).withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00D9FF) : Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
