import 'package:shared_preferences/shared_preferences.dart';
import '../models/interpolation_settings.dart';

class SettingsService {
  static const _keyMode = 'interpolation_mode';
  static const _keyTargetFps = 'target_fps';
  static const _keySensitivity = 'motion_sensitivity';
  static const _keySpeed = 'playback_speed';
  static const _keyAspectRatio = 'aspect_ratio';
  static const _keyLoopMode = 'loop_mode';
  static const _keyBrightness = 'eq_brightness';
  static const _keyContrast = 'eq_contrast';
  static const _keySaturation = 'eq_saturation';
  static const _keyHue = 'eq_hue';
  static const _keyHwAccel = 'hw_acceleration';
  static const _keyBgAudio = 'background_audio';
  static const _keyResume = 'resume_playback';
  static const _keySubSize = 'subtitle_size';
  static const _keySubColor = 'subtitle_color';
  static const _keySubDelay = 'subtitle_delay';
  static const _keyAudioDelay = 'audio_delay';

  Future<InterpolationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_keyMode) ?? 0;
    final fpsIndex = prefs.getInt(_keyTargetFps) ?? 0;
    final sensitivity = prefs.getDouble(_keySensitivity) ?? 0.5;

    return InterpolationSettings(
      mode: InterpolationMode.values[modeIndex],
      targetFps: TargetFps.values[fpsIndex],
      motionSensitivity: sensitivity,
    );
  }

  Future<void> saveSettings(InterpolationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, settings.mode.index);
    await prefs.setInt(_keyTargetFps, settings.targetFps.index);
    await prefs.setDouble(_keySensitivity, settings.motionSensitivity);
  }

  Future<PlaybackSettings> loadPlaybackSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return PlaybackSettings(
      speed: prefs.getDouble(_keySpeed) ?? 1.0,
      aspectRatio: AspectRatioMode
          .values[prefs.getInt(_keyAspectRatio) ?? 0],
      loopMode: LoopMode.values[prefs.getInt(_keyLoopMode) ?? 0],
      brightness: prefs.getDouble(_keyBrightness) ?? 0.0,
      contrast: prefs.getDouble(_keyContrast) ?? 0.0,
      saturation: prefs.getDouble(_keySaturation) ?? 0.0,
      hue: prefs.getDouble(_keyHue) ?? 0.0,
      hwAcceleration: prefs.getBool(_keyHwAccel) ?? true,
      backgroundAudio: prefs.getBool(_keyBgAudio) ?? false,
      resumePlayback: prefs.getBool(_keyResume) ?? true,
      subtitleSize: prefs.getDouble(_keySubSize) ?? 55.0,
      subtitleColor: prefs.getInt(_keySubColor) ?? 0xFFFFFFFF,
      subtitleDelay: prefs.getDouble(_keySubDelay) ?? 0.0,
      audioDelay: prefs.getDouble(_keyAudioDelay) ?? 0.0,
    );
  }

  Future<void> savePlaybackSettings(PlaybackSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySpeed, settings.speed);
    await prefs.setInt(_keyAspectRatio, settings.aspectRatio.index);
    await prefs.setInt(_keyLoopMode, settings.loopMode.index);
    await prefs.setDouble(_keyBrightness, settings.brightness);
    await prefs.setDouble(_keyContrast, settings.contrast);
    await prefs.setDouble(_keySaturation, settings.saturation);
    await prefs.setDouble(_keyHue, settings.hue);
    await prefs.setBool(_keyHwAccel, settings.hwAcceleration);
    await prefs.setBool(_keyBgAudio, settings.backgroundAudio);
    await prefs.setBool(_keyResume, settings.resumePlayback);
    await prefs.setDouble(_keySubSize, settings.subtitleSize);
    await prefs.setInt(_keySubColor, settings.subtitleColor);
    await prefs.setDouble(_keySubDelay, settings.subtitleDelay);
    await prefs.setDouble(_keyAudioDelay, settings.audioDelay);
  }

  // Resume position storage
  Future<void> saveResumePosition(String filePath, Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('resume_$filePath', position.inMilliseconds);
  }

  Future<Duration?> getResumePosition(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('resume_$filePath');
    return ms != null ? Duration(milliseconds: ms) : null;
  }
}
