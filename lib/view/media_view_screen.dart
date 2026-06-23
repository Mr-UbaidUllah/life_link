import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

/// Fullscreen viewer for a chat attachment — pinch-to-zoom for images, a tap
/// play/pause player for videos. Pushed from a media [MessageBubble].
class MediaViewScreen extends StatelessWidget {
  final String url;
  final bool isVideo;
  final String? heroTag;

  const MediaViewScreen({
    super.key,
    required this.url,
    required this.isVideo,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: isVideo ? _VideoView(url: url) : _ImageView(url: url, heroTag: heroTag),
      ),
    );
  }
}

class _ImageView extends StatelessWidget {
  final String url;
  final String? heroTag;
  const _ImageView({required this.url, this.heroTag});

  @override
  Widget build(BuildContext context) {
    Widget image = Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const CircularProgressIndicator(color: Colors.white);
      },
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded,
          color: Colors.white54, size: 64),
    );
    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: SizedBox.expand(child: image),
    );
  }
}

class _VideoView extends StatefulWidget {
  final String url;
  const _VideoView({required this.url});

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      _controller = c;
      await c.initialize();
      if (!mounted) return;
      setState(() => _initialized = true);
      c
        ..setLooping(true)
        ..play();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const Icon(Icons.error_outline_rounded,
          color: Colors.white54, size: 64);
    }
    final c = _controller;
    if (!_initialized || c == null) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
          // Play/pause affordance — fades while playing.
          AnimatedOpacity(
            opacity: c.value.isPlaying ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                c.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 44.sp,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              c,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFFD7263D),
                bufferedColor: Colors.white38,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
