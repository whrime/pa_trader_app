import 'package:flutter/material.dart';
import '../models/task_alert.dart';

class AlertSettingScreen extends StatefulWidget {
  final AlertSetting? alertSetting;
  final ValueChanged<AlertSetting> onSave;

  const AlertSettingScreen({
    Key? key,
    this.alertSetting,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AlertSettingScreen> createState() => _AlertSettingScreenState();
}

class _AlertSettingScreenState extends State<AlertSettingScreen> {
  late List<double> _upperPrices;
  late List<double> _lowerPrices;
  final TextEditingController _upperController = TextEditingController();
  final TextEditingController _lowerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _upperPrices = widget.alertSetting?.upperPrices ?? [];
    _lowerPrices = widget.alertSetting?.lowerPrices ?? [];
  }

  void _addUpperPrice() {
    final text = _upperController.text.trim();
    if (text.isNotEmpty) {
      final price = double.tryParse(text);
      if (price != null && price > 0) {
        setState(() {
          _upperPrices.add(price);
          _upperController.clear();
        });
      }
    }
  }

  void _addLowerPrice() {
    final text = _lowerController.text.trim();
    if (text.isNotEmpty) {
      final price = double.tryParse(text);
      if (price != null && price > 0) {
        setState(() {
          _lowerPrices.add(price);
          _lowerController.clear();
        });
      }
    }
  }

  void _removeUpperPrice(int index) {
    setState(() {
      _upperPrices.removeAt(index);
    });
  }

  void _removeLowerPrice(int index) {
    setState(() {
      _lowerPrices.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预警设置'),
        actions: [
          TextButton(
            onPressed: () {
              if (_upperPrices.isNotEmpty || _lowerPrices.isNotEmpty) {
                final alertSetting = AlertSetting(
                  upperPrices: _upperPrices..sort((a, b) => a.compareTo(b)),
                  lowerPrices: _lowerPrices..sort((a, b) => b.compareTo(a)),
                );
                widget.onSave(alertSetting);
                Navigator.pop(context);
              } else {
                widget.onSave(AlertSetting());
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '上沿价格（卖出预警）',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _upperController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '输入价格',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addUpperPrice,
                          child: const Text('添加'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_upperPrices.isNotEmpty) ...[
                      const Text('已设置的上沿价格：'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _upperPrices.asMap().entries.map((entry) {
                          final index = entry.key;
                          final price = entry.value;
                          return Chip(
                            label: Text('${price.toStringAsFixed(2)}'),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeUpperPrice(index),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '下沿价格（买入预警）',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _lowerController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '输入价格',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addLowerPrice,
                          child: const Text('添加'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_lowerPrices.isNotEmpty) ...[
                      const Text('已设置的下沿价格：'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _lowerPrices.asMap().entries.map((entry) {
                          final index = entry.key;
                          final price = entry.value;
                          return Chip(
                            label: Text('${price.toStringAsFixed(2)}'),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeLowerPrice(index),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
