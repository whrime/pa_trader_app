import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_card.dart';
import '../models/task_group.dart';
import '../models/task_alert.dart';
import '../services/database_service.dart';
import 'alert_setting_screen.dart';

class TaskCardEditScreen extends StatefulWidget {
  final TaskCard? taskCard;

  const TaskCardEditScreen({Key? key, this.taskCard}) : super(key: key);

  @override
  State<TaskCardEditScreen> createState() => _TaskCardEditScreenState();
}

class _TaskCardEditScreenState extends State<TaskCardEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stockNameController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  
  List<TaskPeriod> _periods = [];
  List<TaskGroup> _groups = [];
  String? _selectedGroupId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    if (widget.taskCard != null) {
      _stockNameController.text = widget.taskCard!.stockName;
      _periods = List.from(widget.taskCard!.periods);
      _selectedGroupId = widget.taskCard!.groupId;
    }
    // 默认添加120分钟周期（必填）
    if (_periods.isEmpty) {
      _periods.add(TaskPeriod(
        periodType: '120分钟',
        sortOrder: 0,
        isRequired: true,
      ));
    }
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _databaseService.getAllTaskGroups();
      setState(() {
        _groups = groups;
      });
    } catch (e) {
      print('加载分组失败: $e');
    }
  }

  @override
  void dispose() {
    _stockNameController.dispose();
    super.dispose();
  }

  void _addPeriod() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择周期'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availablePeriodTypes.length,
            itemBuilder: (context, index) {
              final periodType = availablePeriodTypes[index];
              final alreadyAdded = _periods.any((p) => p.periodType == periodType);
              
              return ListTile(
                title: Text(periodType),
                enabled: !alreadyAdded,
                trailing: alreadyAdded
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: alreadyAdded
                    ? null
                    : () {
                        Navigator.pop(context);
                        setState(() {
                          _periods.add(TaskPeriod(
                            periodType: periodType,
                            sortOrder: _periods.length,
                            isRequired: periodType == '120分钟',
                          ));
                          // 重新排序
                          _sortPeriods();
                        });
                      },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _sortPeriods() {
    // 按优先级排序：5分钟 > 120分钟 > 日 > 周 > 月 > 季 > 年
    final orderMap = {
      '5分钟': 0,
      '120分钟': 1,
      '日': 2,
      '周': 3,
      '月': 4,
      '季': 5,
      '年': 6,
    };
    
    _periods.sort((a, b) {
      return (orderMap[a.periodType] ?? 99).compareTo(orderMap[b.periodType] ?? 99);
    });
    
    // 更新sortOrder
    for (int i = 0; i < _periods.length; i++) {
      _periods[i] = TaskPeriod(
        periodType: _periods[i].periodType,
        sortOrder: i,
        isRequired: _periods[i].isRequired,
        data: _periods[i].data,
      );
    }
  }

  void _removePeriod(int index) {
    final period = _periods[index];
    if (period.isRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('120分钟周期为必填项，不能删除')),
      );
      return;
    }
    
    setState(() {
      _periods.removeAt(index);
      _sortPeriods();
    });
  }

  void _editAlertSetting(int index) async {
    final period = _periods[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlertSettingScreen(
          alertSetting: period.alertSetting,
          onSave: (alertSetting) {
            setState(() {
              _periods[index] = TaskPeriod(
                periodType: period.periodType,
                sortOrder: period.sortOrder,
                isRequired: period.isRequired,
                data: period.data,
                alertSetting: alertSetting,
              );
            });
          },
        ),
      ),
    );
  }

  void _editPeriodData(int index) {
    final period = _periods[index];
    final data = period.data ?? PeriodData();
    
    final contextController = TextEditingController(text: data.context ?? '');
    final patternController = TextEditingController(text: data.pattern ?? '');
    final signalKController = TextEditingController(text: data.signalK ?? '');
    final summaryController = TextEditingController(text: data.summary ?? '');
    double score = data.score;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${period.periodType} - 数据填写'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: contextController,
                  decoration: const InputDecoration(
                    labelText: '背景/环境',
                    hintText: '输入背景分析',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: patternController,
                  decoration: const InputDecoration(
                    labelText: '形态',
                    hintText: '输入形态分析',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: signalKController,
                  decoration: const InputDecoration(
                    labelText: '信号K',
                    hintText: '输入信号K分析',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: summaryController,
                  decoration: const InputDecoration(
                    labelText: '总结',
                    hintText: '输入总结',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('评分: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Slider(
                        value: score,
                        min: -5,
                        max: 5,
                        divisions: 100,
                        label: score.toStringAsFixed(1),
                        onChanged: (value) {
                          setDialogState(() {
                            score = value;
                          });
                        },
                      ),
                    ),
                    Container(
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        score >= 0 ? '+${score.toStringAsFixed(1)}' : score.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: score >= 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getScoreDescription(score),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _periods[index] = TaskPeriod(
                    periodType: period.periodType,
                    sortOrder: period.sortOrder,
                    isRequired: period.isRequired,
                    data: PeriodData(
                      context: contextController.text.isEmpty ? null : contextController.text,
                      pattern: patternController.text.isEmpty ? null : patternController.text,
                      signalK: signalKController.text.isEmpty ? null : signalKController.text,
                      summary: summaryController.text.isEmpty ? null : summaryController.text,
                      score: score,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreDescription(double score) {
    if (score >= 4) return '强烈做多';
    if (score >= 3) return '明显做多';
    if (score >= 2) return '偏多信号';
    if (score >= 1) return '轻微偏多';
    if (score > 0) return '略微偏多';
    if (score == 0) return '观望';
    if (score > -1) return '略微偏空';
    if (score > -2) return '轻微偏空';
    if (score > -3) return '偏空信号';
    if (score > -4) return '明显做空';
    return '强烈做空';
  }

  Future<void> _saveTaskCard() async {
    if (!_formKey.currentState!.validate()) return;
    if (_stockNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入股票名称')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final taskCard = TaskCard(
        id: widget.taskCard?.id ?? const Uuid().v4(),
        stockName: _stockNameController.text.trim(),
        groupId: _selectedGroupId,
        createdAt: widget.taskCard?.createdAt ?? now,
        updatedAt: now,
        periods: _periods,
        dailyRecords: widget.taskCard?.dailyRecords ?? [],
      );

      await _databaseService.saveTaskCard(taskCard);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskCard == null ? '新建任务卡' : '编辑任务卡'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _saveTaskCard,
              child: const Text(
                '保存',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _stockNameController,
                decoration: const InputDecoration(
                  labelText: '股票名称',
                  hintText: '输入股票名称或代码',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入股票名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGroupId,
                decoration: const InputDecoration(
                  labelText: '所属分组',
                  hintText: '选择分组',
                  prefixIcon: Icon(Icons.folder),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('未分组'),
                  ),
                  ..._groups.map((group) => DropdownMenuItem(
                    value: group.id,
                    child: Text(group.name),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGroupId = value;
                  });
                },
              ),
              const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '分析周期',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addPeriod,
                  icon: const Icon(Icons.add),
                  label: const Text('添加周期'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '提示：120分钟为必填周期，5分钟可单独删除',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._buildPeriodList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPeriodList() {
    if (_periods.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              '暂无周期，点击"添加周期"按钮添加',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ];
    }

    return _periods.asMap().entries.map((entry) {
      final index = entry.key;
      final period = entry.value;
      final hasData = period.data != null;
      final score = period.data?.score ?? 0;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: hasData ? Colors.blue : Colors.grey,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Row(
            children: [
              Text(
                period.periodType,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (period.isRequired)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '必填',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red[700],
                    ),
                  ),
                ),
            ],
          ),
          subtitle: hasData
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '评分: ${score >= 0 ? '+' : ''}${score.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: score >= 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (period.data!.pattern != null)
                      Text('形态: ${period.data!.pattern}'),
                  ],
                )
              : const Text('点击编辑填写数据'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.orange),
                onPressed: () => _editAlertSetting(index),
                tooltip: '预警设置',
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _editPeriodData(index),
              ),
              if (!period.isRequired)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePeriod(index),
                ),
            ],
          ),
          onTap: () => _editPeriodData(index),
        ),
      );
    }).toList();
  }
}
