import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import '../models/player_state.dart';

enum _GestureType { none, brightness, volume, seek }

class GestureControls extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const GestureControls({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  State<GestureControls> createState() => _GestureControlsState();
}

class _GestureControlsState extends State<GestureControls> {
  _GestureType _gestureType = _GestureType.none;
  double _currentBrightness = 0.5;
  double _currentVolume = 0.5;
  double _seekDelta = 0.0;
  bool _showIndicator = false;
  Timer? _doubleTapTimer;
  int _tapCount = 0;
  Offset? _tapPosition;
  bool _showDoubleTapFeedback = false;
  bool _doubleTapIsForward = false;
  Timer? _hideIndicatorTimer;

  @override
  void initState() {
    super.initState();
    _initValues();
  }

  Future<void> _initValues() async {
    try {
      _currentBrightness = await ScreenBrightness.instance.application;
    } catch (_) {
      _currentBrightness = 0.5;
    }
    try {
      _currentVolume = await VolumeController.instance.getVolume();
    } catch (_) {
      _currentVolume = 0.5;
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _hideIndicatorTimer?.cancel();
    super.dispose();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final x = details.globalPosition.dx;

    if (x < screenWidth / 2) {
      _gestureType = _GestureType.brightness;
    } else {
      _gestureType = _GestureType.volume;
    }
    setState(() => _showIndicator = true);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final delta = -details.delta.dy / (screenHeight * 0.6);

    if (_gestureType == _GestureType.brightness) {
      _currentBrightness = (_currentBrightness + delta).clamp(0.0, 1.0);
      ScreenBrightness.instance.setApplicationScreenBrightness(_currentBrightness);
    } else if (_gestureType == _GestureType.volume) {
      _currentVolume = (_currentVolume + delta).clamp(0.0, 1.0);
      VolumeController.instance.setVolume(_currentVolume);
    }
    setState(() {});
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _gestureType = _GestureType.none;
    _hideIndicatorTimer?.cancel();
    _hideIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showIndicator = false);
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _gestureType = _GestureType.seek;
    _seekDelta = 0;
    setState(() => _showIndicator = true);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_gestureType != _GestureType.seek) return;
    final screenWidth = MediaQuery.of(context).size.width;
    _seekDelta += details.delta.dx / screenWidth * 120;
    setState(() {});
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_gestureType == _GestureType.seek && _seekDelta.abs() > 1) {
      final state = context.read<PlayerState>();
      final newPos =
          state.position + Duration(seconds: _seekDelta.round());
      if (newPos < Duration.zero) {
        state.seek(Duration.zero);
      } else if (newPos > state.duration) {
        state.seek(state.duration);
      } else {
        state.seek(newPos);
      }
    }
    _gestureType = _GestureType.none;
    _seekDelta = 0;
    _hideIndicatorTimer?.cancel();
    _hideIndicatorTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showIndicator = false);
    });
  }

  void _handleTapUp(TapUpDetails details) {
    _tapPosition = details.globalPosition;
    _tapCount++;

    if (_tapCount == 1) {
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(const Duration(milliseconds: 250), () {
        if (_tapCount == 1) {
          widget.onTap();
        }
        _tapCount = 0;
      });
    } else if (_tapCount == 2) {
      _doubleTapTimer?.cancel();
      _tapCount = 0;

      final screenWidth = MediaQuery.of(context).size.width;
      final isForward = (_tapPosition?.dx ?? 0) > screenWidth / 2;
      final state = context.read<PlayerState>();

      if (isForward) {
        final newPos = state.position + const Duration(seconds: 10);
        state.seek(newPos > state.duration ? state.duration : newPos);
      } else {
        final newPos = state.position - const Duration(seconds: 10);
        state.seek(newPos < Duration.zero ? Duration.zero : newPos);
      }

      setState(() {
        _showDoubleTapFeedback = true;
        _doubleTapIsForward = isForward;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _showDoubleTapFeedback = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: _handleTapUp,
          onVerticalDragStart: _onVerticalDragStart,
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: widget.child,
        ),

        // Brightness/Volume indicator
        if (_showIndicator &&
            (_gestureType == _GestureType.brightness ||
                _gestureType == _GestureType.volume))
          Center(
            child: _buildVerticalIndicator(),
          ),

        // Seek indicator
        if (_showIndicator && _gestureType == _GestureType.seek)
          Center(
            child: _buildSeekIndicator(),
          ),

        // Double tap feedback
        if (_showDoubleTapFeedback)
          Positioned(
            left: _doubleTapIsForward ? null : 40,
            right: _doubleTapIsForward ? 40 : null,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _doubleTapIsForward
                          ? Icons.fast_forward_rounded
                          : Icons.fast_rewind_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '10s',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVerticalIndicator() {
    final isBrightness = _gestureType == _GestureType.brightness;
    final value = isBrightness ? _currentBrightness : _currentVolume;
    final icon = isBrightness
        ? (value > 0.5 ? Icons.brightness_high : Icons.brightness_low)
        : (value > 0.5
            ? Icons.volume_up
            : (value > 0 ? Icons.volume_down : Icons.volume_off));

    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                isBrightness
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF00D9FF),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeekIndicator() {
    final isForward = _seekDelta >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isForward ? Icons.fast_forward : Icons.fast_rewind,
            color: const Color(0xFF00D9FF),
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '${isForward ? '+' : ''}${_seekDelta.round()}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
