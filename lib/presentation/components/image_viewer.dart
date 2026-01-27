import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageViewer extends StatefulWidget {
  final List<dynamic> images;
  final String fileName;

  const ImageViewer({
    required this.images,
    required this.fileName,
    super.key,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  int _currentPage = 0;
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.fileName, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          if (widget.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  "${_currentPage + 1}/${widget.images.length}",
                  style: const TextStyle(fontSize: 20, color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: widget.images.isEmpty
          ? const Center(
        child: Text(
          "No Images",
          style: TextStyle(color: Colors.white),
        ),
      )
          : Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final String base64String = widget.images[index].toString();
              Uint8List imageBytes;

              try {
                imageBytes = base64Decode(base64String);
              } catch (e) {
                return const Center(
                  child: Text(
                    "Invalid Image Data",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.white, size: 50),
                            SizedBox(height: 10),
                            Text('Image Load Failed', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 12 : 8,
                    height: _currentPage == i ? 12 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i ? Colors.white : Colors.white54,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
