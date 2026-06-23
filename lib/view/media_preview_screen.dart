import 'dart:io';

import 'package:blood_donation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

/// Review screen shown after the user picks/records an attachment, BEFORE it is
/// sent. Lets them preview the image/video, add an optional caption, then
/// confirm or back out.
///
/// Pops with the caption [String] (possibly empty) on send, or `null` if the
/// user cancels — the caller only uploads when a non-null value comes back.
class MediaPreviewScreen extends StatefulWidget {
  final File file;
  final bool isVideo;

  const MediaPreviewScreen({
    super.key,
    required this.file,
    required this.isVideo,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  final TextEditingController _caption = TextEditingController();

  VideoPlayerController? _video;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final c = VideoPlayerController.file(widget.file);
      _video = c;
      await c.initialize();
      if (!mounted) return;
      setState(() => _videoReady = true);
      c
        ..setLooping(true)
        ..play();
    } catch (_) {
      // Leave _videoReady false → a placeholder shows; the user can still send.
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    _video?.dispose();
    super.dispose();
  }

  void _toggleVideo() {
    final c = _video;
    if (c == null || !_videoReady) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  void _send() => Navigator.pop(context, _caption.text.trim());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context), // cancel → null
        ),
        title: Text(
          widget.isVideo ? 'Send video' : 'Send photo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: Center(child: _preview())),
          _composer(),
        ],
      ),
    );
  }

  Widget _preview() {
    if (!widget.isVideo) {
      return InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Image.file(widget.file, fit: BoxFit.contain),
      );
    }

    final c = _video;
    if (!_videoReady || c == null) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    return GestureDetector(
      onTap: _toggleVideo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)),
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
                c.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 44.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12.w, 10.h, 12.w, MediaQuery.of(context).viewInsets.bottom + 12.h),
      color: Colors.black,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.xl.r),
              ),
              child: TextField(
                controller: _caption,
                maxLines: 4,
                minLines: 1,
                style: TextStyle(fontSize: 15.sp, color: Colors.white),
                cursorColor: Colors.white,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add a caption…',
                  hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14.sp),
                  filled: false,
                  isDense: true,
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _send,
            child: Container(
              height: 46.r,
              width: 46.r,
              decoration: BoxDecoration(
                gradient: AppGradients.hero,
                shape: BoxShape.circle,
                boxShadow: AppGradients.glow(AppColors.primary, alpha: 0.3),
              ),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }
}
