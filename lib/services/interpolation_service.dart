import 'package:media_kit/media_kit.dart';
import '../models/interpolation_settings.dart';

class InterpolationService {
  InterpolationSettings _settings = const InterpolationSettings();

  InterpolationSettings get settings => _settings;

  void updateSettings(InterpolationSettings settings) {
    _settings = settings;
  }

  Future<void> _setMpvProperty(Player player, String name, String value) async {
    await (player.platform as dynamic).setProperty(name, value);
  }

  /// Apply interpolation using mpv's GPU-based temporal interpolation.
  ///
  /// How this works:
  /// - `video-sync=display-resample` tells mpv to resample the video to match
  ///   the display's refresh rate (e.g. 60Hz or 120Hz).
  /// - `interpolation=yes` enables temporal interpolation between frames,
  ///   so mpv generates smooth intermediate frames in the GPU shader.
  /// - `tscale` controls the temporal scaling algorithm used.
  /// - `override-display-fps` forces mpv to target a specific FPS.
  ///
  /// This does NOT use CPU video filters (minterpolate is too heavy for mobile).
  /// It keeps hwdec=auto so frames stay on GPU — no gralloc copy issues.
  Future<void> applyToPlayer(Player player) async {
    if (_settings.mode == InterpolationMode.off) {
      await _setMpvProperty(player, 'vf', '');
      await _setMpvProperty(player, 'interpolation', 'no');
      await _setMpvProperty(player, 'video-sync', 'audio');
      await _setMpvProperty(player, 'hwdec', 'auto');
      return;
    }

    // Keep full hardware decoding — no auto-copy needed.
    // GPU temporal interpolation works directly with hwdec output.
    await _setMpvProperty(player, 'hwdec', 'auto');

    // Remove any CPU video filters
    await _setMpvProperty(player, 'vf', '');

    // Tell mpv to resample video output to match the display/target rate
    await _setMpvProperty(player, 'video-sync', 'display-resample');

    // Enable GPU temporal interpolation between frames
    await _setMpvProperty(player, 'interpolation', 'yes');

    // Force mpv to target our desired FPS regardless of actual display rate
    final targetFps = _settings.targetFpsValue;
    await _setMpvProperty(player, 'override-display-fps', '$targetFps');

    // Temporal scaling algorithm:
    // Quality mode: mitchell — high-quality cubic interpolation, sharper
    // Performance mode: oversample — lightweight, duplicates with blending
    final tscale = _settings.mode == InterpolationMode.quality
        ? 'mitchell'
        : 'oversample';
    await _setMpvProperty(player, 'tscale', tscale);

    // tscale-window controls the interpolation window size.
    // Higher = smoother but more GPU work. Scale with motion sensitivity.
    final windowRadius = 1.0 + (_settings.motionSensitivity * 2.0);
    await _setMpvProperty(
        player, 'tscale-radius', windowRadius.toStringAsFixed(1));
  }

  String get statusText {
    if (_settings.mode == InterpolationMode.off) {
      return 'MEMC Off';
    }
    return 'MEMC ${_settings.modeLabel} → ${_settings.targetFpsValue} FPS';
  }
}
