import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interpolation_settings.dart';
import '../models/player_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<PlayerState>(
        builder: (context, state, _) {
          final ps = state.playbackSettings;
          final interp = state.interpolationSettings;

          return ListView(
            children: [
              _buildSectionHeader('MEMC Frame Interpolation'),
              _buildListTile(
                icon: Icons.auto_awesome,
                title: 'Interpolation Mode',
                subtitle: interp.modeLabel,
                onTap: () => _showInterpolationModeDialog(context, state),
              ),
              _buildListTile(
                icon: Icons.speed,
                title: 'Target FPS',
                subtitle: '${interp.targetFpsValue} FPS',
                onTap: () => _showTargetFpsDialog(context, state),
              ),
              _buildSliderTile(
                icon: Icons.tune,
                title: 'Motion Sensitivity',
                value: interp.motionSensitivity,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(interp.motionSensitivity * 100).round()}%',
                onChanged: (v) => state.updateInterpolation(
                    interp.copyWith(motionSensitivity: v)),
              ),

              _buildSectionHeader('Playback'),
              _buildListTile(
                icon: Icons.speed,
                title: 'Default Speed',
                subtitle: ps.speedLabel,
                onTap: () => _showSpeedDialog(context, state),
              ),
              _buildListTile(
                icon: Icons.aspect_ratio,
                title: 'Aspect Ratio',
                subtitle: ps.aspectRatioLabel,
                onTap: () => _showAspectRatioDialog(context, state),
              ),
              _buildListTile(
                icon: Icons.repeat,
                title: 'Loop Mode',
                subtitle: ps.loopLabel,
                onTap: () => _showLoopDialog(context, state),
              ),

              _buildSectionHeader('Video Equalizer'),
              _buildSliderTile(
                icon: Icons.brightness_6,
                title: 'Brightness',
                value: ps.brightness,
                min: -100,
                max: 100,
                divisions: 200,
                label: ps.brightness.round().toString(),
                onChanged: (v) => state.setVideoEq(brightness: v),
              ),
              _buildSliderTile(
                icon: Icons.contrast,
                title: 'Contrast',
                value: ps.contrast,
                min: -100,
                max: 100,
                divisions: 200,
                label: ps.contrast.round().toString(),
                onChanged: (v) => state.setVideoEq(contrast: v),
              ),
              _buildSliderTile(
                icon: Icons.color_lens,
                title: 'Saturation',
                value: ps.saturation,
                min: -100,
                max: 100,
                divisions: 200,
                label: ps.saturation.round().toString(),
                onChanged: (v) => state.setVideoEq(saturation: v),
              ),
              _buildSliderTile(
                icon: Icons.palette,
                title: 'Hue',
                value: ps.hue,
                min: -100,
                max: 100,
                divisions: 200,
                label: ps.hue.round().toString(),
                onChanged: (v) => state.setVideoEq(hue: v),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextButton(
                  onPressed: state.resetVideoEq,
                  child: const Text('Reset Equalizer',
                      style: TextStyle(color: Color(0xFF00D9FF))),
                ),
              ),

              _buildSectionHeader('Subtitle'),
              _buildSliderTile(
                icon: Icons.text_fields,
                title: 'Subtitle Size',
                value: ps.subtitleSize,
                min: 20,
                max: 100,
                divisions: 16,
                label: ps.subtitleSize.round().toString(),
                onChanged: (v) => state.setSubtitleSize(v),
              ),
              _buildListTile(
                icon: Icons.format_color_text,
                title: 'Subtitle Color',
                subtitle: _colorName(ps.subtitleColor),
                onTap: () => _showSubtitleColorDialog(context, state),
              ),
              _buildSliderTile(
                icon: Icons.timer,
                title: 'Subtitle Delay',
                value: ps.subtitleDelay,
                min: -5.0,
                max: 5.0,
                divisions: 100,
                label: '${ps.subtitleDelay.toStringAsFixed(1)}s',
                onChanged: (v) => state.setSubtitleDelay(v),
              ),

              _buildSectionHeader('Audio'),
              _buildSliderTile(
                icon: Icons.timer,
                title: 'Audio Delay',
                value: ps.audioDelay,
                min: -5.0,
                max: 5.0,
                divisions: 100,
                label: '${ps.audioDelay.toStringAsFixed(1)}s',
                onChanged: (v) => state.setAudioDelay(v),
              ),

              _buildSectionHeader('General'),
              _buildSwitchTile(
                icon: Icons.memory,
                title: 'Hardware Acceleration',
                subtitle: 'Use GPU for decoding',
                value: ps.hwAcceleration,
                onChanged: (v) => state.updatePlaybackSettings(
                    ps.copyWith(hwAcceleration: v)),
              ),
              _buildSwitchTile(
                icon: Icons.music_note,
                title: 'Background Audio',
                subtitle: 'Continue audio when minimized',
                value: ps.backgroundAudio,
                onChanged: (v) => state.updatePlaybackSettings(
                    ps.copyWith(backgroundAudio: v)),
              ),
              _buildSwitchTile(
                icon: Icons.play_circle_outline,
                title: 'Resume Playback',
                subtitle: 'Remember last position',
                value: ps.resumePlayback,
                onChanged: (v) => state.updatePlaybackSettings(
                    ps.copyWith(resumePlayback: v)),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF00D9FF),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle:
          Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing:
          const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.white54, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle:
          Text(subtitle, style: const TextStyle(color: Colors.white54)),
      value: value,
      activeTrackColor: const Color(0xFF00D9FF),
      onChanged: onChanged,
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 22),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Expanded(
            child: SliderTheme(
              data: const SliderThemeData(
                activeTrackColor: Color(0xFF00D9FF),
                inactiveTrackColor: Colors.white12,
                thumbColor: Color(0xFF00D9FF),
                trackHeight: 2,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: label,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showInterpolationModeDialog(
      BuildContext context, PlayerState state) {
    _showOptionsDialog(
      context,
      'Interpolation Mode',
      InterpolationMode.values.map((m) {
        final s = state.interpolationSettings;
        return _DialogOption(
          label: s.copyWith(mode: m).modeLabel,
          selected: s.mode == m,
          onTap: () {
            state.updateInterpolation(s.copyWith(mode: m));
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showTargetFpsDialog(BuildContext context, PlayerState state) {
    _showOptionsDialog(
      context,
      'Target FPS',
      TargetFps.values.map((f) {
        final s = state.interpolationSettings;
        return _DialogOption(
          label: f == TargetFps.fps60 ? '60 FPS' : '120 FPS',
          selected: s.targetFps == f,
          onTap: () {
            state.updateInterpolation(s.copyWith(targetFps: f));
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showSpeedDialog(BuildContext context, PlayerState state) {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    _showOptionsDialog(
      context,
      'Playback Speed',
      speeds.map((s) {
        return _DialogOption(
          label: '${s}x',
          selected: state.playbackSettings.speed == s,
          onTap: () {
            state.setSpeed(s);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showAspectRatioDialog(BuildContext context, PlayerState state) {
    _showOptionsDialog(
      context,
      'Aspect Ratio',
      AspectRatioMode.values.map((m) {
        return _DialogOption(
          label: state.playbackSettings
              .copyWith(aspectRatio: m)
              .aspectRatioLabel,
          selected: state.playbackSettings.aspectRatio == m,
          onTap: () {
            state.setAspectRatio(m);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showLoopDialog(BuildContext context, PlayerState state) {
    _showOptionsDialog(
      context,
      'Loop Mode',
      LoopMode.values.map((m) {
        return _DialogOption(
          label: state.playbackSettings.copyWith(loopMode: m).loopLabel,
          selected: state.playbackSettings.loopMode == m,
          onTap: () {
            state.updatePlaybackSettings(
                state.playbackSettings.copyWith(loopMode: m));
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showSubtitleColorDialog(BuildContext context, PlayerState state) {
    final colors = {
      'White': 0xFFFFFFFF,
      'Yellow': 0xFFFFFF00,
      'Green': 0xFF00FF00,
      'Cyan': 0xFF00FFFF,
      'Red': 0xFFFF0000,
    };
    _showOptionsDialog(
      context,
      'Subtitle Color',
      colors.entries.map((e) {
        return _DialogOption(
          label: e.key,
          selected: state.playbackSettings.subtitleColor == e.value,
          onTap: () {
            state.updatePlaybackSettings(
                state.playbackSettings.copyWith(subtitleColor: e.value));
            Navigator.pop(context);
          },
          color: Color(e.value),
        );
      }).toList(),
    );
  }

  void _showOptionsDialog(
      BuildContext context, String title, List<_DialogOption> options) {
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
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((o) => ListTile(
                  leading: o.color != null
                      ? Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: o.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                        )
                      : null,
                  title: Text(o.label,
                      style: TextStyle(
                          color: o.selected
                              ? const Color(0xFF00D9FF)
                              : Colors.white)),
                  trailing: o.selected
                      ? const Icon(Icons.check, color: Color(0xFF00D9FF))
                      : null,
                  onTap: o.onTap,
                )),
          ],
        ),
      ),
    );
  }

  String _colorName(int color) {
    switch (color) {
      case 0xFFFFFFFF:
        return 'White';
      case 0xFFFFFF00:
        return 'Yellow';
      case 0xFF00FF00:
        return 'Green';
      case 0xFF00FFFF:
        return 'Cyan';
      case 0xFFFF0000:
        return 'Red';
      default:
        return 'Custom';
    }
  }
}

class _DialogOption {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  _DialogOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });
}
