import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/review_option.dart';

class ReviewDetailScreen extends StatefulWidget {
  final List<ReviewOption> reviews;
  final int initialIndex;

  const ReviewDetailScreen({
    Key? key,
    required this.reviews,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.reviews.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reviews[_currentIndex].name),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.reviews.length,
              itemBuilder: (context, index) {
                return _ReviewDetailContent(review: widget.reviews[index]);
              },
            ),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _currentIndex > 0 ? _goToPrevious : null,
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              label: const Text('上一个'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Text(
              '${_currentIndex + 1} / ${widget.reviews.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _currentIndex < widget.reviews.length - 1 ? _goToNext : null,
              icon: const Text('下一个'),
              label: const Icon(Icons.keyboard_arrow_down, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewDetailContent extends StatelessWidget {
  final ReviewOption review;

  const _ReviewDetailContent({required this.review});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (review.imagePaths.isNotEmpty)
            _buildImageSection(context),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContentSection(),
                if (review.qaList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildQaSection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: SizedBox(
        height: 280,
        child: PageView.builder(
          itemCount: review.imagePaths.length,
          itemBuilder: (context, index) {
            final imagePath = review.imagePaths[index];
            final isNetwork = imagePath.startsWith('http');
            final isAbsolutePath = imagePath.startsWith('/') || imagePath.contains(':\\');

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewImageGalleryScreen(
                              imagePaths: review.imagePaths,
                              title: review.name,
                            ),
                          ),
                        );
                      },
                      child: isNetwork
                          ? Image.network(
                              imagePath,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildErrorWidget();
                              },
                            )
                          : isAbsolutePath
                              ? Image.file(
                                  File(imagePath),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildErrorWidget();
                                  },
                                )
                              : Image.asset(
                                  imagePath,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildErrorWidget();
                                  },
                                ),
                    ),
                  ),
                  if (review.imagePaths.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}/${review.imagePaths.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              '图片加载失败',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分析内容',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            review.content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '补充问答',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...review.qaList.asMap().entries.map((entry) {
          final index = entry.key;
          final qa = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Q${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      qa.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[50],
                  child: Text(
                    qa.answer,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

class ReviewImageGalleryScreen extends StatefulWidget {
  final List<String> imagePaths;
  final String title;

  const ReviewImageGalleryScreen({
    Key? key,
    required this.imagePaths,
    required this.title,
  }) : super(key: key);

  @override
  State<ReviewImageGalleryScreen> createState() => _ReviewImageGalleryScreenState();
}

class _ReviewImageGalleryScreenState extends State<ReviewImageGalleryScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.imagePaths.length,
            builder: (context, index) {
              final imagePath = widget.imagePaths[index];
              final isNetwork = imagePath.startsWith('http');
              final isAbsolutePath = imagePath.startsWith('/') || imagePath.contains(':\\');

              ImageProvider provider;
              if (isNetwork) {
                provider = NetworkImage(imagePath);
              } else if (isAbsolutePath) {
                provider = FileImage(File(imagePath));
              } else {
                provider = AssetImage(imagePath);
              }

              return PhotoViewGalleryPageOptions(
                imageProvider: provider,
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: 'review_image_$index'),
              );
            },
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
              ),
            ),
          ),
          if (widget.imagePaths.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imagePaths.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
