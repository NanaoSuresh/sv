import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/interpolation_service.dart';
import '../services/settings_service.dart';
import 'interpolation_settings.dart';

class PlayerState extends ChangeNotifier {
  late final Player player;
  late final VideoController videoController;
  final InterpolationService _interpolationService = InterpolationService();
  final SettingsService _settingsService = SettingsService();

  bool _isInitialized = false;
  String? _currentFile;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  double _estimatedFps = 0.0;
  PlaybackSettings _playbackSettings = const PlaybackSettings();
  bool _controlsLocked = false;

  // Track info
  List<AudioTrack> _audioTracks = [];
  List<SubtitleTrack> _subtitleTracks = [];
  AudioTrack _currentAudioTrack = AudioTrack.auto();
  SubtitleTrack _currentSubtitleTrack = SubtitleTrack.no();

  bool get isInitialized => _isInitialized;
  String? get currentFile => _currentFile;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  double get estimatedFps => _estimatedFps;
  InterpolationSettings get interpolationSettings =>
      _interpolationService.settings;
  String get interpolationStatus => _interpolationService.statusText;
  PlaybackSettings get playbackSettings => _playbackSettings;
  bool get controlsLocked => _controlsLocked;
  List<AudioTrack> get audioTracks => _audioTracks;
  List<SubtitleTrack> get subtitleTracks => _subtitleTracks;
  AudioTrack get currentAudioTrack => _currentAudioTrack;
  SubtitleTrack get currentSubtitleTrack => _currentSubtitleTrack;

  PlayerState() {
    _init();
  }

  Future<void> _init() async {
    player = Player();
    videoController = VideoController(player);

    final savedSettings = await _settingsService.loadSettings();
    _interpolationService.updateSettings(savedSettings);

    final savedPlayback = await _settingsService.loadPlaybackSettings();
    _playbackSettings = savedPlayback;

    // Listen to player streams
    player.stream.position.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    player.stream.duration.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    player.stream.playing.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    player.stream.tracks.listen((tracks) {
      _audioTracks = tracks.audio;
      _subtitleTracks = tracks.subtitle;
      notifyListeners();
    });

    player.stream.track.listen((track) {
      _currentAudioTrack = track.audio;
      _currentSubtitleTrack = track.subtitle;
      notifyListeners();
    });

    player.stream.width.listen((_) => _updateFpsEstimate());

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _setMpvProperty(String name, String value) async {
    try {
      await (player.platform as dynamic).setProperty(name, value);
    } catch (_) {}
  }

  Future<void> _updateFpsEstimate() async {
    try {
      final fps =
          await (player.platform as dynamic).getProperty('estimated-vf-fps');
      if (fps is String) {
        _estimatedFps = double.tryParse(fps) ?? 0.0;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> openFile(String path) async {
    _currentFile = path;
    await player.open(Media(path));
    await _interpolationService.applyToPlayer(player);
    _applyPlaybackSettings();
    notifyListeners();
  }

  Future<void> openUrl(String url) async {
    _currentFile = url;
    await player.open(Media(url));
    await _interpolationService.applyToPlayer(player);
    _applyPlaybackSettings();
    notifyListeners();
  }

  void togglePlayPause() {
    player.playOrPause();
  }

  void seek(Duration position) {
    player.seek(position);
  }

  void toggleControlsLock() {
    _controlsLocked = !_controlsLocked;
    notifyListeners();
  }

  // --- Interpolation ---

  Future<void> updateInterpolation(InterpolationSettings settings) async {
    _interpolationService.updateSettings(settings);
    await _interpolationService.applyToPlayer(player);
    await _settingsService.saveSettings(settings);
    notifyListeners();
  }

  // --- Playback Settings ---

  Future<void> updatePlaybackSettings(PlaybackSettings settings) async {
    _playbackSettings = settings;
    _applyPlaybackSettings();
    await _settingsService.savePlaybackSettings(settings);
    notifyListeners();
  }

  void _applyPlaybackSettings() {
    player.setRate(_playbackSettings.speed);

    // Loop mode
    switch (_playbackSettings.loopMode) {
      case LoopMode.off:
        player.setPlaylistMode(PlaylistMode.none);
        break;
      case LoopMode.single:
        player.setPlaylistMode(PlaylistMode.single);
        break;
      case LoopMode.all:
        player.setPlaylistMode(PlaylistMode.loop);
        break;
    }

    // Video EQ via mpv
    _setMpvProperty('brightness', _playbackSettings.brightness.toStringAsFixed(0));
    _setMpvProperty('contrast', _playbackSettings.contrast.toStringAsFixed(0));
    _setMpvProperty('saturation', _playbackSettings.saturation.toStringAsFixed(0));
    _setMpvProperty('hue', _playbackSettings.hue.toStringAsFixed(0));

    // Subtitle styling
    _setMpvProperty('sub-font-size', _playbackSettings.subtitleSize.toStringAsFixed(0));
    final r = (_playbackSettings.subtitleColor >> 16) & 0xFF;
    final g = (_playbackSettings.subtitleColor >> 8) & 0xFF;
    final b = _playbackSettings.subtitleColor & 0xFF;
    _setMpvProperty('sub-color', '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}');

    // Audio/subtitle delay
    _setMpvProperty('sub-delay', _playbackSettings.subtitleDelay.toStringAsFixed(1));
    _setMpvProperty('audio-delay', _playbackSettings.audioDelay.toStringAsFixed(1));

    // HW acceleration (only when MEMC is off — MEMC always uses hwdec=auto)
    if (_interpolationService.settings.mode == InterpolationMode.off) {
      _setMpvProperty(
          'hwdec', _playbackSettings.hwAcceleration ? 'auto' : 'no');
    }
  }

  // --- Speed ---

  void setSpeed(double speed) {
    updatePlaybackSettings(_playbackSettings.copyWith(speed: speed));
  }

  // --- Aspect Ratio ---

  void cycleAspectRatio() {
    final modes = AspectRatioMode.values;
    final nextIndex =
        (modes.indexOf(_playbackSettings.aspectRatio) + 1) % modes.length;
    updatePlaybackSettings(
        _playbackSettings.copyWith(aspectRatio: modes[nextIndex]));
  }

  void setAspectRatio(AspectRatioMode mode) {
    updatePlaybackSettings(_playbackSettings.copyWith(aspectRatio: mode));
  }

  // --- Loop ---

  void cycleLoopMode() {
    final modes = LoopMode.values;
    final nextIndex =
        (modes.indexOf(_playbackSettings.loopMode) + 1) % modes.length;
    updatePlaybackSettings(
        _playbackSettings.copyWith(loopMode: modes[nextIndex]));
  }

  // --- Audio track ---

  void setAudioTrack(AudioTrack track) {
    player.setAudioTrack(track);
  }

  // --- Subtitle track ---

  void setSubtitleTrack(SubtitleTrack track) {
    player.setSubtitleTrack(track);
  }

  // --- Video EQ ---

  void setVideoEq({
    double? brightness,
    double? contrast,
    double? saturation,
    double? hue,
  }) {
    updatePlaybackSettings(_playbackSettings.copyWith(
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      hue: hue,
    ));
  }

  void resetVideoEq() {
    updatePlaybackSettings(_playbackSettings.copyWith(
      brightness: 0.0,
      contrast: 0.0,
      saturation: 0.0,
      hue: 0.0,
    ));
  }

  // --- Subtitle settings ---

  void setSubtitleSize(double size) {
    updatePlaybackSettings(_playbackSettings.copyWith(subtitleSize: size));
  }

  void setSubtitleDelay(double delay) {
    updatePlaybackSettings(_playbackSettings.copyWith(subtitleDelay: delay));
  }

  void setAudioDelay(double delay) {
    updatePlaybackSettings(_playbackSettings.copyWith(audioDelay: delay));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
