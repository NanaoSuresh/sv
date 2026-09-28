import 'dart:async';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path/path.dart' as p;

enum BoostQuality { fast, quality }

class FpsBoostResult {
  final String outputPath;
  final double sourceFps;
  final double targetFps;
  final Duration processingTime;

  const FpsBoostResult({
    required this.outputPath,
    required this.sourceFps,
    required this.targetFps,
    required this.processingTime,
  });
}

class FpsBoostService {
  int? _sessionId;
  bool _cancelled = false;

  bool get isProcessing => _sessionId != null;

  Future<double> getSourceFps(String inputPath) async {
    final session = await FFprobeKit.getMediaInformation(inputPath);
    final info = session.getMediaInformation();
    if (info == null) return 0;

    final streams = info.getStreams();
    for (final stream in streams) {
      final type = stream.getType();
      if (type == 'video') {
        // Try avg_frame_rate first, then r_frame_rate
        final avgFr = stream.getProperty('avg_frame_rate') as String?;
        final rFr = stream.getProperty('r_frame_rate') as String?;
        final fr = avgFr ?? rFr;
        if (fr != null && fr.contains('/')) {
          final parts = fr.split('/');
          final num = double.tryParse(parts[0]) ?? 0;
          final den = double.tryParse(parts[1]) ?? 1;
          if (den > 0) return num / den;
        }
        if (fr != null) {
          return double.tryParse(fr) ?? 0;
        }
      }
    }
    return 0;
  }

  Future<String?> getResolution(String inputPath) async {
    final session = await FFprobeKit.getMediaInformation(inputPath);
    final info = session.getMediaInformation();
    if (info == null) return null;

    final streams = info.getStreams();
    for (final stream in streams) {
      if (stream.getType() == 'video') {
        final w = stream.getWidth();
        final h = stream.getHeight();
        if (w != null && h != null) return '${w}x$h';
      }
    }
    return null;
  }

  Future<Duration?> getDuration(String inputPath) async {
    final session = await FFprobeKit.getMediaInformation(inputPath);
    final info = session.getMediaInformation();
    if (info == null) return null;

    final durationStr = info.getDuration();
    if (durationStr == null) return null;
    final seconds = double.tryParse(durationStr);
    if (seconds == null) return null;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  Future<FpsBoostResult> boost({
    required String inputPath,
    required BoostQuality quality,
    void Function(double progress, Duration elapsed)? onProgress,
  }) async {
    _cancelled = false;
    final stopwatch = Stopwatch()..start();

    // Get source info
    final sourceFps = await getSourceFps(inputPath);
    if (sourceFps <= 0) throw Exception('Could not detect source FPS');

    final totalDuration = await getDuration(inputPath);
    final totalMs = totalDuration?.inMilliseconds.toDouble() ?? 0;

    // Calculate target FPS (2x source, capped at 120)
    final targetFps = (sourceFps * 2).clamp(1.0, 120.0).roundToDouble();

    // Build output path
    final dir = p.dirname(inputPath);
    final name = p.basenameWithoutExtension(inputPath);
    final ext = p.extension(inputPath);
    final outputPath = p.join(dir, '${name}_${targetFps.round()}fps$ext');

    // Build minterpolate filter
    String vf;
    if (quality == BoostQuality.fast) {
      vf = 'minterpolate=fps=$targetFps:mi_mode=blend';
    } else {
      vf = 'minterpolate=fps=$targetFps:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:mb_size=16';
    }

    // Build FFmpeg command
    // Use libx264 for broad compatibility, -preset fast for reasonable speed
    final cmd = '-i "$inputPath" '
        '-vf "$vf" '
        '-c:v libx264 -preset fast -crf 18 '
        '-c:a copy '
        '-y "$outputPath"';

    final completer = Completer<FpsBoostResult>();

    final session = await FFmpegKit.executeAsync(
      cmd,
      (session) async {
        // Completion callback
        _sessionId = null;
        stopwatch.stop();

        if (_cancelled) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('Cancelled'));
          }
          return;
        }

        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          if (!completer.isCompleted) {
            completer.complete(FpsBoostResult(
              outputPath: outputPath,
              sourceFps: sourceFps,
              targetFps: targetFps,
              processingTime: stopwatch.elapsed,
            ));
          }
        } else {
          final logs = await session.getLogsAsString();
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('FFmpeg failed (code: $returnCode)\n$logs'),
            );
          }
        }
      },
      null, // Log callback
      (Statistics statistics) {
        // Statistics callback for progress
        if (totalMs > 0 && onProgress != null) {
          final timeMs = statistics.getTime().toDouble();
          final progress = (timeMs / totalMs).clamp(0.0, 1.0);
          onProgress(progress, stopwatch.elapsed);
        }
      },
    );

    _sessionId = session.getSessionId();

    return completer.future;
  }

  void cancel() {
    _cancelled = true;
    if (_sessionId != null) {
      FFmpegKit.cancel();
      _sessionId = null;
    }
  }
}
