import 'package:flutter/material.dart';
import '../models/task_card.dart';
import '../models/task_group.dart';
import '../services/database_service.dart';
import 'task_card_edit_screen.dart';

class TaskCardDetailScreen extends StatefulWidget {
  final TaskCard taskCard;

  const TaskCardDetailScreen({Key? key, required this.taskCard}) : super(key: key);

  @override
  State<TaskCardDetailScreen> createState() => _TaskCardDetailScreenState();
}

class _TaskCardDetailScreenState extends State<TaskCardDetailScreen> {
  late TaskCard _taskCard;
  TaskGroup? _group;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _taskCard = widget.taskCard;
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    if (_taskCard.groupId != null) {
      final group = await _databaseService.getTaskGroup(_taskCard.groupId!);
      if (mounted) {
        setState(() {
          _group = group;
        });
      }
    }
  }

  Future<void> _refreshTaskCard() async {
    final card = await _databaseService.getTaskCard(_taskCard.id);
    if (card != null && mounted) {
      setState(() {
        _taskCard = card;
      });
      await _loadGroup();
    }
  }

  void _showScoreHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('评分系统说明'),
        content: SingleChildScrollView(
          child: Text(scoreDescription),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _taskCard.priorityLevel.color;
    final score = _taskCard.priorityScore;

    return Scaffold(
      appBar: AppBar(
        title: Text(_taskCard.stockName),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showScoreHelp,
            tooltip: '评分说明',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskCardEditScreen(taskCard: _taskCard),
                ),
              );
              if (result == true) {
                await _refreshTaskCard();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部信息卡片
            _buildHeaderCard(priorityColor, score),
            const SizedBox(height: 16),
            // 周期数据列表
            ..._buildPeriodCards(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskCardEditScreen(taskCard: _taskCard),
            ),
          );
          if (result == true) {
            await _refreshTaskCard();
          }
        },
        icon: const Icon(Icons.edit),
        label: const Text('编辑数据'),
      ),
    );
  }

  Widget _buildHeaderCard(Color priorityColor, double score) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              priorityColor.withOpacity(0.1),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _taskCard.priorityLevel.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: score >= 0 ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: score >= 0 ? Colors.red[300]! : Colors.green[300]!,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    score >= 0
                        ? '+${score.toStringAsFixed(2)}'
                        : score.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: score >= 0 ? Colors.red[700] : Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_group != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      _group!.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem('周期数', '${_taskCard.periods.length}'),
                _buildInfoItem(
                  '已填写',
                  '${_taskCard.periods.where((p) => p.data != null).length}',
                ),
                _buildInfoItem(
                  '更新',
                  '${_taskCard.updatedAt.month}/${_taskCard.updatedAt.day}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPeriodCards() {
    if (_taskCard.periods.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              '暂无周期数据',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ];
    }

    return _taskCard.periods.asMap().entries.map((entry) {
      final index = entry.key;
      final period = entry.value;
      final data = period.data;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: data != null ? Colors.blue : Colors.grey,
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
          subtitle: data != null
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: data.score >= 0
                            ? Colors.red[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data.score >= 0
                            ? '+${data.score.toStringAsFixed(1)}'
                            : data.score.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: data.score >= 0
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getScoreDescription(data.score),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : const Text('暂无数据'),
          children: data != null
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDataRow('背景/环境', data.context),
                        _buildDataRow('形态', data.pattern),
                        _buildDataRow('信号K', data.signalK),
                        _buildDataRow('总结', data.summary),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: data.score >= 0
                                ? Colors.red[50]
                                : Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: data.score >= 0
                                  ? Colors.red[200]!
                                  : Colors.green[200]!,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '综合评分: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    data.score >= 0
                                        ? '+${data.score.toStringAsFixed(1)}'
                                        : data.score.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: data.score >= 0
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  _getScoreDescription(data.score),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: data.score >= 0
                                        ? Colors.red[600]
                                        : Colors.green[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.edit_note, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('暂无数据，点击编辑添加'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TaskCardEditScreen(taskCard: _taskCard),
                                ),
                              );
                              if (result == true) {
                                await _refreshTaskCard();
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('编辑'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
        ),
      );
    }).toList();
  }

  Widget _buildDataRow(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
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
}
