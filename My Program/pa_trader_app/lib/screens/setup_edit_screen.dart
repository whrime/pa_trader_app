import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/setup_option.dart';

class SetupEditScreen extends StatefulWidget {
  final SetupOption? setup;

  const SetupEditScreen({
    Key? key, this.setup}) : super(key: key);

  @override
  State<SetupEditScreen> createState() => _SetupEditScreenState();
}

class _SetupEditScreenState extends State<SetupEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _shortDescController;
  late TextEditingController _conceptController;
  late TextEditingController _entryPointController;
  late TextEditingController _stopLossController;
  late TextEditingController _targetPriceController;
  late TextEditingController _reasonController;
  late TextEditingController _contentController;
  List<TextEditingController> _questionControllers = [];
  List<TextEditingController> _answerControllers = [];
  List<String> _imagePaths = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.setup?.name ?? '');
    _shortDescController = TextEditingController(text: widget.setup?.shortDescription ?? '');
    _conceptController = TextEditingController(text: widget.setup?.concept ?? '');
    _entryPointController = TextEditingController(text: widget.setup?.entryPoint ?? '');
    _stopLossController = TextEditingController(text: widget.setup?.stopLoss ?? '');
    _targetPriceController = TextEditingController(text: widget.setup?.targetPrice ?? '');
    _reasonController = TextEditingController(text: widget.setup?.reason ?? '');
    _contentController = TextEditingController(text: widget.setup?.content ?? '');
    _imagePaths = List.from(widget.setup?.imagePaths ?? []);
    
    if (widget.setup?.qaList != null) {
      for (var qa in widget.setup!.qaList) {
        _questionControllers.add(TextEditingController(text: qa.question));
        _answerControllers.add(TextEditingController(text: qa.answer));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortDescController.dispose();
    _conceptController.dispose();
    _entryPointController.dispose();
    _stopLossController.dispose();
    _targetPriceController.dispose();
    _reasonController.dispose();
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

  void _saveSetup() {
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

      final setup = SetupOption(
        id: widget.setup?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        shortDescription: _shortDescController.text,
        concept: _conceptController.text,
        entryPoint: _entryPointController.text,
        stopLoss: _stopLossController.text,
        targetPrice: _targetPriceController.text,
        reason: _reasonController.text,
        imagePaths: _imagePaths,
        content: _contentController.text,
        qaList: qaItems,
      );

      Navigator.pop(context, setup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setup != null ? '编辑策略' : '新增策略'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('基础信息'),
            _buildTextField(_nameController, '策略名称', true),
            _buildTextField(_shortDescController, '简短描述', true),
            const SizedBox(height: 16),
            _buildSectionTitle('策略图片'),
            _buildImagePicker(),
            const SizedBox(height: 16),
            _buildSectionTitle('策略要素'),
            _buildTextField(_conceptController, '概念', false),
            _buildTextField(_entryPointController, '入场点', false),
            _buildTextField(_stopLossController, '止损', false),
            _buildTextField(_targetPriceController, '目标价', false),
            _buildTextField(_reasonController, '原因', false),
            const SizedBox(height: 16),
            _buildSectionTitle('详细内容'),
            _buildTextField(_contentController, '内容说明', false, maxLines: 10),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('补充问答'),
                TextButton.icon(
                  onPressed: _addQaItem,
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
            for (int i = 0; i < _questionControllers.length; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('问题 ${i + 1}', style: TextStyle(color: Colors.grey[600])),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () => _removeQaItem(i),
                          ),
                        ],
                      ),
                      _buildTextField(_questionControllers[i], '问题', false, padding: false),
                      _buildTextField(_answerControllers[i], '答案', false, padding: false, maxLines: 3),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSetup,
        icon: const Icon(Icons.save),
        label: Text(widget.setup != null ? '保存' : '创建'),
      ),
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
                        child: Image.file(
                          File(_imagePaths[index]),
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool required, {
    int maxLines = 1,
    bool padding = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding ? 12 : 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return '请输入$label';
          }
          return null;
        },
      ),
    );
  }
}
