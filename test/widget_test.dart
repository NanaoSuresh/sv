import 'package:flutter_test/flutter_test.dart';
import 'package:vplayer/models/interpolation_settings.dart';

void main() {
  test('InterpolationSettings defaults', () {
    const settings = InterpolationSettings();
    expect(settings.mode, InterpolationMode.off);
    expect(settings.targetFps, TargetFps.fps60);
    expect(settings.targetFpsValue, 60);
    expect(settings.modeLabel, 'Off');
  });

  test('InterpolationSettings copyWith', () {
    const settings = InterpolationSettings();
    final updated = settings.copyWith(
      mode: InterpolationMode.quality,
      targetFps: TargetFps.fps120,
    );
    expect(updated.mode, InterpolationMode.quality);
    expect(updated.targetFpsValue, 120);
    expect(updated.modeLabel, 'Quality');
  });
}
