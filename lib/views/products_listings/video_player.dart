import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class VideoPlayerScreen extends StatefulWidget {
  final List<String> videoUrls;
  final int initialIndex;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrls,
    this.initialIndex = 0,
    this.title = 'Videos',
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideo(_currentIndex);
    
    // Auto-hide controls after 3 seconds
    _scheduleControlsHide();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _controller.pause();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _initializeVideo(int index) {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    _controller = VideoPlayerController.network(widget.videoUrls[index]);

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _duration = _controller.value.duration;
        });
        
        _controller.addListener(_videoListener);
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load video';
        });
      }
    });
  }

  void _videoListener() {
    if (mounted && _controller.value.isInitialized) {
      setState(() {
        _position = _controller.value.position;
        _isPlaying = _controller.value.isPlaying;
      });

      // Auto-hide controls when playing
      if (_isPlaying && _showControls) {
        _scheduleControlsHide();
      }
    }
  }

  void _scheduleControlsHide() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _togglePlayPause() {
    if (_controller.value.isInitialized) {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    }
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    if (_isPlaying) {
      _scheduleControlsHide();
    }
  }

  void _seekToPosition(double value) {
    final Duration newPosition = Duration(
      milliseconds: (value * _duration.inMilliseconds).round(),
    );
    _controller.seekTo(newPosition);
  }

  void _changeVideo(int newIndex) {
    if (newIndex >= 0 && newIndex < widget.videoUrls.length && newIndex != _currentIndex) {
      _controller.pause();
      _controller.removeListener(_videoListener);
      _controller.dispose();

      setState(() {
        _currentIndex = newIndex;
      });

      _initializeVideo(newIndex);
      _pageController.animateToPage(
        newIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleFullscreen() {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds'
        : '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return WillPopScope(
      onWillPop: () async {
        if (isLandscape) {
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: isLandscape ? null : AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            '${widget.title} (${_currentIndex + 1}/${widget.videoUrls.length})',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          // actions: [
          //   IconButton(
          //     icon: Icon(Icons.fullscreen, color: Colors.white),
          //     onPressed: _toggleFullscreen,
          //   ),
          // ],
        ),
        body: Column(
          children: [
            // Video Player Section
            Expanded(
              flex: isLandscape ? 1 : 2,
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: GestureDetector(
                  onTap: _showControlsTemporarily,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video Player
                      if (_controller.value.isInitialized && !_hasError)
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),

                      // Loading Indicator
                      if (_isLoading)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF2B342)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading video...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),

                      // Error Display
                      if (_hasError)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 64),
                            SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _initializeVideo(_currentIndex),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFF2B342),
                              ),
                              child: Text('Retry'),
                            ),
                          ],
                        ),

                      // Video Controls Overlay
                      if (_showControls && _controller.value.isInitialized && !_hasError)
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              stops: [0.0, 0.3, 0.7, 1.0],
                            ),
                          ),
                          child: Column(
                            children: [
                              // Top Controls
                              if (isLandscape)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.arrow_back, color: Colors.white),
                                        onPressed: () {
                                          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                                          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                                          Navigator.pop(context);
                                        },
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${widget.title} (${_currentIndex + 1}/${widget.videoUrls.length})',
                                          style: TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.fullscreen_exit, color: Colors.white),
                                        onPressed: _toggleFullscreen,
                                      ),
                                    ],
                                  ),
                                ),

                              Spacer(),

                              // Center Play/Pause Button
                              GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(16),
                                  child: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),

                              Spacer(),

                              // Bottom Controls
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Column(
                                  children: [
                                    // Progress Bar
                                    Row(
                                      children: [
                                        Text(
                                          _formatDuration(_position),
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              activeTrackColor: Color(0xFFF2B342),
                                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                                              thumbColor: Color(0xFFF2B342),
                                              overlayColor: Color(0xFFF2B342).withOpacity(0.3),
                                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                                              trackHeight: 3,
                                            ),
                                            child: Slider(
                                              value: _duration.inMilliseconds > 0
                                                  ? _position.inMilliseconds / _duration.inMilliseconds
                                                  : 0.0,
                                              onChanged: _seekToPosition,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          _formatDuration(_duration),
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 8),

                                    // Control Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          onPressed: _currentIndex > 0 
                                              ? () => _changeVideo(_currentIndex - 1)
                                              : null,
                                          icon: Icon(
                                            Icons.skip_previous,
                                            color: _currentIndex > 0 ? Colors.white : Colors.white38,
                                            size: 32,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            final newPosition = _position - Duration(seconds: 10);
                                            _controller.seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
                                          },
                                          icon: Icon(Icons.replay_10, color: Colors.white, size: 32),
                                        ),
                                        IconButton(
                                          onPressed: _togglePlayPause,
                                          icon: Icon(
                                            _isPlaying ? Icons.pause : Icons.play_arrow,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            final newPosition = _position + Duration(seconds: 10);
                                            _controller.seekTo(newPosition < _duration ? newPosition : _duration);
                                          },
                                          icon: Icon(Icons.forward_10, color: Colors.white, size: 32),
                                        ),
                                        IconButton(
                                          onPressed: _currentIndex < widget.videoUrls.length - 1
                                              ? () => _changeVideo(_currentIndex + 1)
                                              : null,
                                          icon: Icon(
                                            Icons.skip_next,
                                            color: _currentIndex < widget.videoUrls.length - 1 ? Colors.white : Colors.white38,
                                            size: 32,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Video List (only in portrait mode)
            if (!isLandscape && widget.videoUrls.length > 1)
              Container(
                height: 120,
                color: Colors.grey[900],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Playlist',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: widget.videoUrls.length,
                        itemBuilder: (context, index) {
                          final isSelected = index == _currentIndex;
                          return GestureDetector(
                            onTap: () => _changeVideo(index),
                            child: Container(
                              width: 80,
                              margin: EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFFF2B342) : Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? Border.all(color: Color(0xFFF2B342), width: 2) : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected ? Icons.play_circle_fill : Icons.play_circle_outline,
                                    color: isSelected ? Colors.black : Colors.white,
                                    size: 24,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
}