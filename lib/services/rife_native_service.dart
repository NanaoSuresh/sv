import 'package:flutter/services.dart';

/// Dart-side interface to the native RIFE ncnn Vulkan plugin.
///
/// To enable this feature:
/// 1. Run ./scripts/setup_rife.sh to download ncnn + RIFE model
/// 2. Add externalNativeBuild to android/app/build.gradle.kts
/// 3. Rebuild the app
///
/// When the native library is not available, [isAvailable] returns false
/// and all operations gracefully no-op.
class RifeNativeService {
  static const _channel = MethodChannel('com.vplayer.rife');

  /// Check if the native RIFE library is loaded and available.
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Initialize the RIFE model.
  /// [modelPath] is the directory containing flownet.param and flownet.bin.
  /// [gpuId] selects the Vulkan GPU (0 = default).
  static Future<bool> init({required String modelPath, int gpuId = 0, bool useVulkan = true}) async {
    try {
      final result = await _channel.invokeMethod<bool>('init', {
        'modelPath': modelPath,
        'gpuId': gpuId,
        'useVulkan': useVulkan,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Destroy the RIFE model and free resources.
  static Future<void> destroy() async {
    try {
      await _channel.invokeMethod('destroy');
    } catch (_) {}
  }

  /// Get the number of Vulkan GPUs available.
  static Future<int> getGpuCount() async {
    try {
      final result = await _channel.invokeMethod<int>('getGpuCount');
      return result ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
