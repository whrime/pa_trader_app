import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/review_option.dart';

class ReviewEditScreen extends StatefulWidget {
  final ReviewOption? review;

  const ReviewEditScreen({
    Key? key, this.review}) : super(key: key);

  @override
  State<ReviewEditScreen> createState() => _ReviewEditScreenState();
}

class _ReviewEditScreenState extends State<ReviewEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _shortDescController;
  late TextEditingController _contentController;
  List<TextEditingController> _questionControllers = [];
  List<TextEditingController> _answerControllers = [];
  List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.review?.name ?? '');
    _shortDescController = TextEditingController(text: widget.review?.shortDescription ?? '');
    _contentController = TextEditingController(text: widget.review?.content ?? '');
    _imagePaths = List.from(widget.review?.imagePaths ?? []);

    if (widget.review?.qaList != null) {
      for (var qa in widget.review!.qaList) {
        _questionControllers.add(TextEditingController(text: qa.question));
        _answerControllers.add(TextEditingController(text: qa.answer));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _contentController.dispose();
    for (var c in _questionControllers) {
      c.dispose();
    }
    for (var c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            if (!_imagePaths.contains(file.path)) {
              _imagePaths.add(file.path);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _addQaItem() {
    setState(() {
      _questionControllers.add(TextEditingController());
      _answerControllers.add(TextEditingController());
    });
  }

  void _removeQaItem(int index) {
    setState(() {
      _questionControllers[index].dispose();
      _answerControllers[index].dispose();
      _questionControllers.removeAt(index);
      _answerControllers.removeAt(index);
    });
  }

  void _saveReview() {
    if (_formKey.currentState!.validate()) {
      List<QaItem> qaItems = [];
      for (int i = 0; i < _questionControllers.length; i++) {
        if (_questionControllers[i].text.isNotEmpty || _answerControllers[i].text.isNotEmpty) {
          qaItems.add(QaItem(
            question: _questionControllers[i].text,
            answer: _answerControllers[i].text,
          ));
        }
      }

      final review = ReviewOption(
        id: widget.review?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        shortDescription: _shortDescController.text,
        content: _contentController.text,
        imagePaths: _imagePaths,
        qaList: qaItems,
      );

      Navigator.pop(context, review);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.review != null ? '编辑复盘' : '新增复盘'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveReview,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('基本信息'),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _nameController,
              label: '标题',
              hint: '请输入复盘标题',
              required: true,
            ),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _shortDescController,
              label: '简介',
              hint: '简短描述',
              required: true,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('图片'),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 24),
            _buildSectionTitle('分析内容'),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextFormField(
                  controller: _contentController,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    hintText: '请输入详细分析内容...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(height: 1.8),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入分析内容';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('补充问答'),
                IconButton(
                  onPressed: _addQaItem,
                  icon: const Icon(Icons.add_circle, color: Colors.purple),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_questionControllers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    '点击 + 按钮添加问答',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...List.generate(_questionControllers.length, (index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(14),
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
                            const SizedBox(width: 8),
                            const Text(
                              '问题',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _removeQaItem(index),
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _questionControllers[index],
                          decoration: const InputDecoration(
                            hintText: '输入问题...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            SizedBox(width: 36),
                            Text(
                              '回答',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _answerControllers[index],
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: '输入回答...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return '请输入$label';
        }
        return null;
      },
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_imagePaths.isNotEmpty) ...[
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imagePaths.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImage(_imagePaths[index]),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.photo_library),
          label: Text(_imagePaths.isEmpty ? '从相册选择图片' : '添加更多图片'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String path) {
    final isNetwork = path.startsWith('http');
    final isAbsolutePath = path.startsWith('/') || path.contains(':\\');

    if (isNetwork) {
      return Image.network(
        path,
        height: 150,
        width: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 150,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else if (isAbsolutePath) {
      return Image.file(
        File(path),
        height: 150,
        width: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 150,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.asset(
        path,
        height: 150,
        width: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 150,
            height: 150,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }
}
