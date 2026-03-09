import 'package:flutter/material.dart';
import '../models/task_card.dart';
import '../models/task_group.dart';
import '../models/task_alert.dart';
import '../services/database_service.dart';
import 'task_card_edit_screen.dart';

class TaskCardDetailScreen extends StatefulWidget {
  final TaskCard taskCard;
  final List<TaskCard>? taskCards;
  final int? initialIndex;

  const TaskCardDetailScreen({
    Key? key, 
    required this.taskCard,
    this.taskCards,
    this.initialIndex,
  }) : super(key: key);

  @override
  State<TaskCardDetailScreen> createState() => _TaskCardDetailScreenState();
}

class _TaskCardDetailScreenState extends State<TaskCardDetailScreen> {
  late TaskCard _taskCard;
  late PageController _pageController;
  late int _currentIndex;
  TaskGroup? _group;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _taskCard = widget.taskCard;
    _currentIndex = widget.initialIndex ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
    _loadGroup();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (widget.taskCards != null && _currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (widget.taskCards != null && _currentIndex < widget.taskCards!.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

    if (widget.taskCards != null) {
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
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _taskCard = widget.taskCards![index];
                    _loadGroup();
                  });
                },
                itemCount: widget.taskCards!.length,
                itemBuilder: (context, index) {
                  final card = widget.taskCards![index];
                  return _buildTaskCardContent(card, priorityColor, score);
                },
              ),
            ),
            _buildNavigationBar(),
          ],
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
    } else {
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
          child: _buildTaskCardContent(_taskCard, priorityColor, score),
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
  }

  Widget _buildTaskCardContent(TaskCard card, Color priorityColor, double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 头部信息卡片
        _buildHeaderCard(card, priorityColor, score),
        const SizedBox(height: 16),
        // 周期数据列表
        ..._buildPeriodCards(card),
        const SizedBox(height: 32),
      ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Text(
              '${_currentIndex + 1} / ${widget.taskCards!.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _currentIndex < widget.taskCards!.length - 1 ? _goToNext : null,
              icon: const Text('下一个'),
              label: const Icon(Icons.keyboard_arrow_down, size: 20),
              style: ElevatedButton.styleFrom(
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

  Widget _buildHeaderCard(TaskCard card, Color priorityColor, double score) {
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
                  card.priorityLevel.name,
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
                _buildInfoItem('周期数', '${card.periods.length}'),
                _buildInfoItem(
                  '已填写',
                  '${card.periods.where((p) => p.data != null).length}',
                ),
                _buildInfoItem(
                  '更新',
                  '${card.updatedAt.month}/${card.updatedAt.day}',
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

  List<Widget> _buildPeriodCards(TaskCard card) {
    if (card.periods.isEmpty) {
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

    return card.periods.asMap().entries.map((entry) {
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
              // 预警图标
              if (period.alertSetting != null &&
                  (period.alertSetting!.upperPrices.isNotEmpty ||
                      period.alertSetting!.lowerPrices.isNotEmpty))
                const Icon(
                  Icons.notifications,
                  color: Colors.orange,
                  size: 18,
                ),
              if (period.alertSetting != null &&
                  (period.alertSetting!.upperPrices.isNotEmpty ||
                      period.alertSetting!.lowerPrices.isNotEmpty))
                const SizedBox(width: 8),
              Text(
                period.periodType,
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                        // 预警价格设置
                        if (period.alertSetting != null &&
                            (period.alertSetting!.upperPrices.isNotEmpty ||
                                period.alertSetting!.lowerPrices.isNotEmpty))
                          _buildAlertSettingCard(period.alertSetting!),
                        // 预警达到按钮
                        if (period.alertSetting != null &&
                            (period.alertSetting!.upperPrices.isNotEmpty ||
                                period.alertSetting!.lowerPrices.isNotEmpty))
                          _buildAlertTriggerButton(card, period),
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
                                      TaskCardEditScreen(taskCard: card),
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

  Widget _buildAlertSettingCard(AlertSetting alertSetting) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '预警设置',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE65100), // Colors.orange[800]
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (alertSetting.upperPrices.isNotEmpty) ...[
              const Text(
                '上沿价格（卖出预警）:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: alertSetting.upperPrices.map((price) {
                  return Chip(
                    label: Text('${price.toStringAsFixed(3)}'),
                    backgroundColor: Color(0xFFFFEBEE), // Colors.red[100]
                    labelStyle: TextStyle(color: Color(0xFFB71C1C)), // Colors.red[700]
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            if (alertSetting.lowerPrices.isNotEmpty) ...[
              const Text(
                '下沿价格（买入预警）:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: alertSetting.lowerPrices.map((price) {
                  return Chip(
                    label: Text('${price.toStringAsFixed(3)}'),
                    backgroundColor: Color(0xFFE8F5E0), // Colors.green[100]
                    labelStyle: TextStyle(color: Color(0xFF1B5E20)), // Colors.green[700]
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTriggerButton(TaskCard card, TaskPeriod period) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () async {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('预警达到'),
              content: const Text('确认此周期的预警已达到？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('确认'),
                ),
              ],
            ),
          );

          if (result == true) {
            // 记录预警达到
            final trigger = AlertTrigger(
              taskCardId: card.id,
              stockName: card.stockName,
              periodType: period.periodType,
              type: period.alertSetting!.upperPrices.isNotEmpty ? AlertType.upper : AlertType.lower,
              price: period.alertSetting!.upperPrices.isNotEmpty 
                  ? period.alertSetting!.upperPrices.first 
                  : period.alertSetting!.lowerPrices.first,
              triggeredPrice: 0, // 实际价格需要从外部获取
              triggeredAt: DateTime.now(),
            );
            
            await _databaseService.saveAlertTrigger(trigger);
            
            // 询问是否修改周期卡片
            final modifyResult = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('修改周期卡片'),
                content: const Text('是否需要修改此周期的卡片信息？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('稍后'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('现在修改'),
                  ),
                ],
              ),
            );

            if (modifyResult == true) {
              // 跳转到编辑界面
              final editResult = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskCardEditScreen(taskCard: card),
                ),
              );
              if (editResult == true) {
                await _refreshTaskCard();
              }
            }
          }
        },
        icon: const Icon(Icons.notification_important),
        label: const Text('标记预警达到'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
        ),
      ),
    );
  }
}
