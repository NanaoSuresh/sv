import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/interpolation_settings.dart';
import '../models/player_state.dart';

class StatsOverlay extends StatefulWidget {
  const StatsOverlay({super.key});

  @override
  State<StatsOverlay> createState() => _StatsOverlayState();
}

class _StatsOverlayState extends State<StatsOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      context.read<PlayerState>().refreshStats();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerState>(
      builder: (context, state, _) {
        final interp = state.interpolationSettings;
        final memcOn = interp.mode != InterpolationMode.off;

        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Vplayer Debug Stats',
                style: TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              _stat('Source FPS', state.estimatedFps.toStringAsFixed(1)),
              _stat('Display FPS', state.displayFps.isNotEmpty
                  ? '${double.tryParse(state.displayFps)?.toStringAsFixed(1) ?? state.displayFps} Hz'
                  : 'N/A'),
              _stat('VO Output FPS', state.voFps.isNotEmpty
                  ? (double.tryParse(state.voFps)?.toStringAsFixed(1) ?? state.voFps)
                  : 'N/A'),
              _stat('Video Sync', state.videoSync.isNotEmpty
                  ? state.videoSync
                  : 'N/A'),
              _stat('Vsync Ratio', state.vsyncRatio.isNotEmpty
                  ? state.vsyncRatio
                  : 'N/A'),
              _stat('Dropped', state.droppedFrames.isNotEmpty
                  ? state.droppedFrames
                  : '0'),
              const Divider(color: Colors.white24, height: 12),
              _stat('MEMC', memcOn
                  ? '${interp.modeLabel} → ${interp.targetFpsValue} FPS'
                  : 'Off',
                  valueColor: memcOn ? const Color(0xFF00D9FF) : Colors.white54),
              _stat('Interpolation', memcOn ? 'YES (GPU tscale)' : 'NO',
                  valueColor: memcOn ? Colors.greenAccent : Colors.white54),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

