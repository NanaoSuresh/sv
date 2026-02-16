enum InterpolationMode { off, quality, performance }

enum TargetFps { fps60, fps120 }

class InterpolationSettings {
  final InterpolationMode mode;
  final TargetFps targetFps;
  final double motionSensitivity;

  const InterpolationSettings({
    this.mode = InterpolationMode.off,
    this.targetFps = TargetFps.fps60,
    this.motionSensitivity = 0.5,
  });

  InterpolationSettings copyWith({
    InterpolationMode? mode,
    TargetFps? targetFps,
    double? motionSensitivity,
  }) {
    return InterpolationSettings(
      mode: mode ?? this.mode,
      targetFps: targetFps ?? this.targetFps,
      motionSensitivity: motionSensitivity ?? this.motionSensitivity,
    );
  }

  int get targetFpsValue => targetFps == TargetFps.fps60 ? 60 : 120;

  String get modeLabel {
    switch (mode) {
      case InterpolationMode.off:
        return 'Off';
      case InterpolationMode.quality:
        return 'Quality';
      case InterpolationMode.performance:
        return 'Performance';
    }
  }
}

enum AspectRatioMode { auto, fill, fit, stretch, fourThree, sixteenNine }

enum LoopMode { off, single, all }

class PlaybackSettings {
  final double speed;
  final AspectRatioMode aspectRatio;
  final LoopMode loopMode;
  final double brightness;
  final double contrast;
  final double saturation;
  final double hue;
  final bool hwAcceleration;
  final bool backgroundAudio;
  final bool resumePlayback;
  final double subtitleSize;
  final int subtitleColor;
  final double subtitleDelay;
  final double audioDelay;

  const PlaybackSettings({
    this.speed = 1.0,
    this.aspectRatio = AspectRatioMode.auto,
    this.loopMode = LoopMode.off,
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.hue = 0.0,
    this.hwAcceleration = true,
    this.backgroundAudio = false,
    this.resumePlayback = true,
    this.subtitleSize = 55.0,
    this.subtitleColor = 0xFFFFFFFF,
    this.subtitleDelay = 0.0,
    this.audioDelay = 0.0,
  });

  PlaybackSettings copyWith({
    double? speed,
    AspectRatioMode? aspectRatio,
    LoopMode? loopMode,
    double? brightness,
    double? contrast,
    double? saturation,
    double? hue,
    bool? hwAcceleration,
    bool? backgroundAudio,
    bool? resumePlayback,
    double? subtitleSize,
    int? subtitleColor,
    double? subtitleDelay,
    double? audioDelay,
  }) {
    return PlaybackSettings(
      speed: speed ?? this.speed,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      loopMode: loopMode ?? this.loopMode,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      hue: hue ?? this.hue,
      hwAcceleration: hwAcceleration ?? this.hwAcceleration,
      backgroundAudio: backgroundAudio ?? this.backgroundAudio,
      resumePlayback: resumePlayback ?? this.resumePlayback,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      subtitleDelay: subtitleDelay ?? this.subtitleDelay,
      audioDelay: audioDelay ?? this.audioDelay,
    );
  }

  String get speedLabel => '${speed}x';

  String get aspectRatioLabel {
    switch (aspectRatio) {
      case AspectRatioMode.auto:
        return 'Auto';
      case AspectRatioMode.fill:
        return 'Fill';
      case AspectRatioMode.fit:
        return 'Fit';
      case AspectRatioMode.stretch:
        return 'Stretch';
      case AspectRatioMode.fourThree:
        return '4:3';
      case AspectRatioMode.sixteenNine:
        return '16:9';
    }
  }

  String get loopLabel {
    switch (loopMode) {
      case LoopMode.off:
        return 'Off';
      case LoopMode.single:
        return 'Single';
      case LoopMode.all:
        return 'All';
    }
  }
}
