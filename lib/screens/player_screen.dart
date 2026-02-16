import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';
import '../models/interpolation_settings.dart';
import '../models/player_state.dart';
import '../widgets/gesture_controls.dart';
import '../widgets/memc_controls.dart';
import '../widgets/playback_controls.dart';
import '../widgets/player_top_bar.dart';
import '../widgets/track_selector_sheet.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _showControls = true;
  bool _showMemcPanel = false;
  bool _landscapeLocked = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _autoHideControls();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _showControls) {
        final state = context.read<PlayerState>();
        if (state.isPlaying) {
          setState(() => _showControls = false);
        }
      }
    });
  }

  void _toggleOrientation() {
    setState(() {
      _landscapeLocked = !_landscapeLocked;
      if (_landscapeLocked) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _autoHideControls();
  }

  BoxFit _getBoxFit(AspectRatioMode mode) {
    switch (mode) {
      case AspectRatioMode.auto:
      case AspectRatioMode.fit:
        return BoxFit.contain;
      case AspectRatioMode.fill:
      case AspectRatioMode.sixteenNine:
      case AspectRatioMode.fourThree:
        return BoxFit.cover;
      case AspectRatioMode.stretch:
        return BoxFit.fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<PlayerState>(
        builder: (context, state, _) {
          if (!state.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
            );
          }

          final isLocked = state.controlsLocked;

          return Stack(
            children: [
              // Video layer
              Center(
                child: Video(
                  controller: state.videoController,
                  fill: Colors.black,
                  fit: _getBoxFit(state.playbackSettings.aspectRatio),
                ),
              ),

              // Gesture layer (works even when controls hidden, unless locked)
              if (!isLocked)
                GestureControls(
                  onTap: _toggleControls,
                  child: const SizedBox.expand(),
                ),

              // Locked state — only show lock button
              if (isLocked)
                GestureDetector(
                  onTap: () {},
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox.expand(
                    child: Center(
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.lock,
                              color: Colors.white, size: 28),
                        ),
                        onPressed: state.toggleControlsLock,
                      ),
                    ),
                  ),
                ),

              // Controls overlay (only if not locked)
              if (_showControls && !isLocked) ...[
                // Top bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: PlayerTopBar(
                    title: _getTitle(state.currentFile),
                    state: state,
                    onBack: () => Navigator.pop(context),
                    onMemcTap: () =>
                        setState(() => _showMemcPanel = !_showMemcPanel),
                    onAudioTap: () => _showAudioTrackSheet(context, state),
                    onSubtitleTap: () =>
                        _showSubtitleTrackSheet(context, state),
                    onRotateTap: _toggleOrientation,
                  ),
                ),

                // Bottom playback controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: PlaybackControls(
                        onLockTap: state.toggleControlsLock,
                      ),
                    ),
                  ),
                ),
              ],

              // MEMC panel
              if (_showMemcPanel && !isLocked)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 300,
                  child: MemcControls(
                    onClose: () => setState(() => _showMemcPanel = false),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showAudioTrackSheet(BuildContext context, PlayerState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TrackSelectorSheet(
        title: 'Audio Track',
        tracks: state.audioTracks
            .map((t) => TrackOption(
                  id: t.id,
                  label: t.title ?? t.language ?? t.id,
                  selected: t.id == state.currentAudioTrack.id,
                ))
            .toList(),
        onSelected: (id) {
          final track = state.audioTracks.firstWhere((t) => t.id == id);
          state.setAudioTrack(track);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSubtitleTrackSheet(BuildContext context, PlayerState state) {
    final tracks = <TrackOption>[
      TrackOption(id: 'no', label: 'None', selected: state.currentSubtitleTrack.id == 'no'),
      ...state.subtitleTracks.map((t) => TrackOption(
            id: t.id,
            label: t.title ?? t.language ?? t.id,
            selected: t.id == state.currentSubtitleTrack.id,
          )),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TrackSelectorSheet(
        title: 'Subtitle Track',
        tracks: tracks,
        onSelected: (id) {
          if (id == 'no') {
            state.setSubtitleTrack(SubtitleTrack.no());
          } else {
            final track = state.subtitleTracks.firstWhere((t) => t.id == id);
            state.setSubtitleTrack(track);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  String _getTitle(String? path) {
    if (path == null) return 'Vplayer';
    final uri = Uri.tryParse(path);
    if (uri != null && uri.hasScheme) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : path;
    }
    return path.split('/').last;
  }
}
