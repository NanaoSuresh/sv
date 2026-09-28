import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player_state.dart';
import '../services/fps_boost_service.dart';
import 'player_screen.dart';

class BoostFpsScreen extends StatefulWidget {
  final String filePath;
  const BoostFpsScreen({super.key, required this.filePath});

  @override
  State<BoostFpsScreen> createState() => _BoostFpsScreenState();
}

class _BoostFpsScreenState extends State<BoostFpsScreen> {
  final FpsBoostService _service = FpsBoostService();
  BoostQuality _quality = BoostQuality.fast;

  // Video info
  double _sourceFps = 0;
  String _resolution = '';
  Duration _duration = Duration.zero;
  bool _loadingInfo = true;

  // Processing state
  bool _processing = false;
  double _progress = 0;
  Duration _elapsed = Duration.zero;
  String? _error;
  FpsBoostResult? _result;

  @override
  void initState() {
    super.initState();
    _loadVideoInfo();
  }

  @override
  void dispose() {
    if (_processing) _service.cancel();
    super.dispose();
  }

  Future<void> _loadVideoInfo() async {
    try {
      final fps = await _service.getSourceFps(widget.filePath);
      final res = await _service.getResolution(widget.filePath);
      final dur = await _service.getDuration(widget.filePath);
      if (mounted) {
        setState(() {
          _sourceFps = fps;
          _resolution = res ?? 'Unknown';
          _duration = dur ?? Duration.zero;
          _loadingInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to read video info: $e';
          _loadingInfo = false;
        });
      }
    }
  }

  double get _targetFps => (_sourceFps * 2).clamp(1, 120).roundToDouble();

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Duration get _eta {
    if (_progress <= 0) return Duration.zero;
    final totalEstimate = _elapsed.inMilliseconds / _progress;
    final remaining = totalEstimate - _elapsed.inMilliseconds;
    return Duration(milliseconds: remaining.round().clamp(0, 999999999));
  }

  Future<void> _startBoost() async {
    setState(() {
      _processing = true;
      _progress = 0;
      _elapsed = Duration.zero;
      _error = null;
      _result = null;
    });

    try {
      final result = await _service.boost(
        inputPath: widget.filePath,
        quality: _quality,
        onProgress: (progress, elapsed) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _elapsed = elapsed;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _result = result;
          _processing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _processing = false;
        });
      }
    }
  }

  void _playResult() {
    if (_result == null) return;
    final playerState = context.read<PlayerState>();
    playerState.openFile(_result!.outputPath);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PlayerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filename = widget.filePath.split('/').last;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Boost FPS'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loadingInfo
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Video Info Card
                  _buildCard(
                    title: 'Video Info',
                    icon: Icons.movie_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          filename,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _infoBadge(
                                '${_sourceFps.toStringAsFixed(1)} FPS',
                                Icons.speed),
                            const SizedBox(width: 12),
                            _infoBadge(_resolution, Icons.aspect_ratio),
                            const SizedBox(width: 12),
                            _infoBadge(_formatDuration(_duration),
                                Icons.timer_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Settings Card
                  _buildCard(
                    title: 'Interpolation Settings',
                    icon: Icons.tune,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quality Mode',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _qualityChip(
                              label: 'Fast',
                              subtitle: 'Blend (quick)',
                              selected: _quality == BoostQuality.fast,
                              onTap: () => setState(
                                  () => _quality = BoostQuality.fast),
                            ),
                            const SizedBox(width: 12),
                            _qualityChip(
                              label: 'Quality',
                              subtitle: 'MEMC (slow)',
                              selected: _quality == BoostQuality.quality,
                              onTap: () => setState(
                                  () => _quality = BoostQuality.quality),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.double_arrow,
                                color: Color(0xFF00D9FF), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_sourceFps.toStringAsFixed(0)} FPS → ${_targetFps.toStringAsFixed(0)} FPS',
                              style: const TextStyle(
                                color: Color(0xFF00D9FF),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _quality == BoostQuality.fast
                              ? 'Blends adjacent frames. Fast but may show ghosting on fast motion.'
                              : 'Motion-compensated interpolation. Slow but produces real new frames with motion estimation.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Processing Card
                  if (_processing || _result != null || _error != null)
                    _buildCard(
                      title: _result != null
                          ? 'Complete!'
                          : _error != null
                              ? 'Error'
                              : 'Processing...',
                      icon: _result != null
                          ? Icons.check_circle
                          : _error != null
                              ? Icons.error
                              : Icons.hourglass_top,
                      iconColor: _result != null
                          ? Colors.green
                          : _error != null
                              ? Colors.red
                              : const Color(0xFF00D9FF),
                      child: Column(
                        children: [
                          if (_processing) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: _progress,
                                    strokeWidth: 6,
                                    color: const Color(0xFF00D9FF),
                                    backgroundColor: Colors.white12,
                                  ),
                                  Text(
                                    '${(_progress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Elapsed: ${_formatDuration(_elapsed)}',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12),
                                ),
                                const SizedBox(width: 24),
                                Text(
                                  'ETA: ${_formatDuration(_eta)}',
                                  style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () {
                                _service.cancel();
                                setState(() => _processing = false);
                              },
                              icon: const Icon(Icons.cancel, size: 18),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ],
                          if (_result != null) ...[
                            const SizedBox(height: 8),
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              '${_result!.sourceFps.toStringAsFixed(0)} → ${_result!.targetFps.toStringAsFixed(0)} FPS',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Completed in ${_formatDuration(_result!.processingTime)}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _playResult,
                              icon: const Icon(Icons.play_arrow),
                              label:
                                  const Text('Play Enhanced Video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _startBoost,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Boost button
                  if (!_processing && _result == null)
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                            _sourceFps > 0 ? _startBoost : null,
                        icon: const Icon(Icons.rocket_launch, size: 24),
                        label: const Text(
                          'Boost FPS',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF6C63FF)
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF00D9FF).withValues(alpha: 0.05),
                      border: Border.all(
                        color:
                            const Color(0xFF00D9FF).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF00D9FF), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This creates a new video file with real interpolated frames using FFmpeg\'s minterpolate engine. '
                            'Processing time depends on video length and quality mode. '
                            'The enhanced file is saved alongside the original.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    Color iconColor = const Color(0xFF00D9FF),
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _qualityChip({
    required String label,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _processing ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? const Color(0xFF00D9FF).withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.03),
            border: Border.all(
              color: selected
                  ? const Color(0xFF00D9FF)
                  : Colors.white.withValues(alpha: 0.1),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF00D9FF)
                      : Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
