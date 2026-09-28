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

  /// Apply frame interpolation using mpv's minterpolate video filter.
  ///
  /// Why minterpolate instead of mpv's --interpolation flag:
  /// mpv's GPU temporal interpolation (--interpolation --video-sync=display-resample)
  /// requires direct vsync control over the display. On Android, media_kit renders
  /// to a Surface consumed by Flutter's Texture widget, so mpv has no vsync timing.
  /// The result: --interpolation silently does nothing visible.
  ///
  /// minterpolate is a CPU video filter that ACTUALLY generates new intermediate
  /// frames using motion estimation. It outputs real 60fps frames that are visible
  /// regardless of the rendering pipeline.
  ///
  /// Trade-off: requires software decoding (hwdec=no) so the CPU filter chain
  /// can access frames. Performance mode (blend) is lightweight. Quality mode
  /// (mci) is heavier but produces better results.
  Future<void> applyToPlayer(Player player, {double displayRefreshRate = 60.0}) async {
    if (_settings.mode == InterpolationMode.off) {
      await _setMpvProperty(player, 'vf', '');
      await _setMpvProperty(player, 'interpolation', 'no');
      await _setMpvProperty(player, 'video-sync', 'audio');
      await _setMpvProperty(player, 'hwdec', 'auto');
      await _setMpvProperty(player, 'override-display-fps', '0');
      return;
    }

    final targetFps = _settings.targetFpsValue;

    // Software decoding is REQUIRED for minterpolate to work.
    // With hwdec=auto or auto-copy, frames either stay on GPU (filter skipped)
    // or cause gralloc buffer lock errors on Mali GPUs.
    // hwdec=no decodes on CPU so the filter chain can process frames.
    await _setMpvProperty(player, 'hwdec', 'no');

    // Build the minterpolate filter string
    String vf;
    if (_settings.mode == InterpolationMode.performance) {
      // blend mode: simply blends adjacent frames
      // Very lightweight, minimal CPU overhead
      // Produces slight ghosting on fast motion but smooth overall
      vf = 'minterpolate=fps=$targetFps:mi_mode=blend';
    } else {
      // mci mode: motion compensated interpolation (true MEMC)
      // Analyzes motion vectors and generates proper intermediate frames
      // mc_mode=aobmc: adaptive overlapped block motion compensation
      // me_mode=bidir: bidirectional motion estimation for accuracy
      // mb_size: macroblock size — smaller = finer detail but heavier
      //   Scale with sensitivity: high sensitivity = smaller blocks
      final mbSize = (16 - (_settings.motionSensitivity * 8)).round().clamp(8, 16);
      vf = 'minterpolate=fps=$targetFps:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:mb_size=$mbSize';
    }

    await _setMpvProperty(player, 'vf', vf);

    // Standard audio sync — no display-resample needed since the filter
    // outputs real frames at the target FPS
    await _setMpvProperty(player, 'video-sync', 'audio');
    await _setMpvProperty(player, 'interpolation', 'no');
    await _setMpvProperty(player, 'override-display-fps', '0');
  }

  String get statusText {
    if (_settings.mode == InterpolationMode.off) {
      return 'MEMC Off';
    }
    return 'MEMC ${_settings.modeLabel} → ${_settings.targetFpsValue} FPS';
  }
}
