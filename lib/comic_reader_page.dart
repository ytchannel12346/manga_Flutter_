import 'dart:io';
import 'package:flutter/material.dart';

enum ComicReadMode { vertical, mangaRtl, comicLtr }

class ComicPageSource {
  const ComicPageSource.file(this.file) : url = null, headers = null;
  const ComicPageSource.network(this.url, {this.headers}) : file = null;

  final File? file;
  final String? url;
  final Map<String, String>? headers;

  ImageProvider toProvider() => file != null
      ? FileImage(file!)
      : NetworkImage(url!, headers: headers);
}

class ComicReaderPage extends StatefulWidget {
  const ComicReaderPage({
    super.key,
    required this.title,
    required this.pages,
    this.initialPage = 0,
    this.onPageChanged,
  });

  final String title;
  final List<ComicPageSource> pages;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;

  @override
  State<ComicReaderPage> createState() => _ComicReaderPageState();
}

class _ComicReaderPageState extends State<ComicReaderPage> {
  late int _currentIndex = widget.initialPage;
  late PageController _pageController = PageController(initialPage: _currentIndex);
  ComicReadMode _mode = ComicReadMode.mangaRtl;
  bool _showControls = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _precacheNearby(int index) {
    for (final offset in [1, 2]) {
      final next = index + offset;
      if (next < widget.pages.length) {
        precacheImage(widget.pages[next].toProvider(), context);
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    widget.onPageChanged?.call(index);
    _precacheNearby(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showControls = !_showControls),
            child: _mode == ComicReadMode.vertical
                ? _buildVerticalReader()
                : _buildPagedReader(),
          ),
          if (_showControls) _buildTopBar(),
          if (_showControls) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildPagedReader() {
    return PageView.builder(
      controller: _pageController,
      reverse: _mode == ComicReadMode.mangaRtl,
      itemCount: widget.pages.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        return InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: Center(
            child: Image(
              image: widget.pages[index].toProvider(),
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalReader() {
    return ListView.builder(
      itemCount: widget.pages.length,
      itemBuilder: (context, index) {
        return Image(
          image: widget.pages[index].toProvider(),
          fit: BoxFit.fitWidth,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<ComicReadMode>(
            icon: const Icon(Icons.menu_book),
            onSelected: (mode) => setState(() {
              _mode = mode;
              _pageController = PageController(initialPage: _currentIndex);
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: ComicReadMode.mangaRtl, child: Text('日漫 (右至左)')),
              PopupMenuItem(value: ComicReadMode.comicLtr, child: Text('普通 (左至右)')),
              PopupMenuItem(value: ComicReadMode.vertical, child: Text('條漫 (上下捲動)')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Text(
                '${_currentIndex + 1} / ${widget.pages.length}',
                style: const TextStyle(color: Colors.white),
              ),
              Expanded(
                child: Slider(
                  value: _currentIndex.toDouble(),
                  min: 0,
                  max: (widget.pages.length - 1).clamp(0, double.infinity).toDouble(),
                  onChanged: (val) {
                    final target = val.round();
                    setState(() => _currentIndex = target);
                    if (_mode != ComicReadMode.vertical) {
                      _pageController.jumpToPage(target);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
