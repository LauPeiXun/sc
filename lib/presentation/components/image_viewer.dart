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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 背景全黑，沉浸式体验
      appBar: AppBar(
        title: Text(
          "${widget.fileName} (${_currentPage + 1}/${widget.images.length})",
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: widget.images.isEmpty
          ? const Center(child: Text("No Images", style: TextStyle(color: Colors.white)))
          : PageView.builder(
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
            return const Center(child: Text("Invalid Image Data", style: TextStyle(color: Colors.white)));
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
    );
  }
}