import 'package:flutter/material.dart';
import '../models/task_alert.dart';
import '../services/database_service.dart';

class AlertTriggerListScreen extends StatefulWidget {
  const AlertTriggerListScreen({Key? key}) : super(key: key);

  @override
  State<AlertTriggerListScreen> createState() => _AlertTriggerListScreenState();
}

class _AlertTriggerListScreenState extends State<AlertTriggerListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<AlertTrigger> _todayTriggers = [];
  List<AlertTrigger> _historyTriggers = [];
  bool _isLoading = true;
  int _currentTab = 0; // 0: 当日记录, 1: 历史记录

  @override
  void initState() {
    super.initState();
    _loadTriggers();
  }

  Future<void> _loadTriggers() async {
    setState(() => _isLoading = true);
    try {
      final todayTriggers = await _databaseService.getTodayAlertTriggers();
      final historyTriggers = await _databaseService.getAllAlertTriggers();
      
      // 过滤出非今日的记录
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final filteredHistory = historyTriggers.where((trigger) {
        final triggerDate = trigger.triggeredAt;
        return !(triggerDate.year == today.year &&
            triggerDate.month == today.month &&
            triggerDate.day == today.day);
      }).toList();
      
      setState(() {
        _todayTriggers = todayTriggers;
        _historyTriggers = filteredHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    }
  }

  Future<void> _markTrigger(AlertTrigger trigger, bool marked) async {
    try {
      await _databaseService.markAlertTrigger(trigger.id, marked);
      setState(() {
        _todayTriggers = _todayTriggers.map((t) {
          if (t.id == trigger.id) {
            return t.copyWith(isMarked: marked);
          }
          return t;
        }).toList();
        _historyTriggers = _historyTriggers.map((t) {
          if (t.id == trigger.id) {
            return t.copyWith(isMarked: marked);
          }
          return t;
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    }
  }

  Future<void> _deleteTrigger(AlertTrigger trigger) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条预警记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _databaseService.deleteAlertTrigger(trigger.id);
        setState(() {
          _todayTriggers.removeWhere((t) => t.id == trigger.id);
          _historyTriggers.removeWhere((t) => t.id == trigger.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预警达成记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTriggers,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              initialIndex: _currentTab,
              child: Column(
                children: [
                  TabBar(
                    onTap: (index) {
                      setState(() {
                        _currentTab = index;
                      });
                    },
                    tabs: const [
                      Tab(text: '当日记录'),
                      Tab(text: '历史记录'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildTodayTriggersView(),
                        _buildHistoryTriggersView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTodayTriggersView() {
    final modifiedTriggers = _todayTriggers.where((t) => t.isMarked).toList();
    final pendingTriggers = _todayTriggers.where((t) => !t.isMarked).toList();

    if (_todayTriggers.isEmpty) {
      return _buildEmptyView('今日暂无预警达成记录');
    }

    return ListView(
      children: [
        if (pendingTriggers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '待修改',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          ...pendingTriggers.map((trigger) => _AlertTriggerItem(
                trigger: trigger,
                onMark: (marked) => _markTrigger(trigger, marked),
                onDelete: () => _deleteTrigger(trigger),
              )),
        ],
        if (modifiedTriggers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '已修改',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          ...modifiedTriggers.map((trigger) => _AlertTriggerItem(
                trigger: trigger,
                onMark: (marked) => _markTrigger(trigger, marked),
                onDelete: () => _deleteTrigger(trigger),
              )),
        ],
      ],
    );
  }

  Widget _buildHistoryTriggersView() {
    if (_historyTriggers.isEmpty) {
      return _buildEmptyView('暂无历史预警记录');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _historyTriggers.length,
      itemBuilder: (context, index) {
        final trigger = _historyTriggers[index];
        return _AlertTriggerItem(
          trigger: trigger,
          onMark: (marked) => _markTrigger(trigger, marked),
          onDelete: () => _deleteTrigger(trigger),
        );
      },
    );
  }

  Widget _buildEmptyView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _AlertTriggerItem extends StatelessWidget {
  final AlertTrigger trigger;
  final ValueChanged<bool> onMark;
  final VoidCallback onDelete;

  const _AlertTriggerItem({
    required this.trigger,
    required this.onMark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trigger.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: trigger.type.color),
                  ),
                  child: Row(
                    children: [
                      Text(
                        trigger.type.icon,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: trigger.type.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trigger.type.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: trigger.type.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trigger.stockName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Checkbox(
                  value: trigger.isMarked,
                  onChanged: (value) {
                    if (value != null) {
                      onMark(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '周期: ${trigger.periodType}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Text(
                  '预警价格: ${trigger.price.toStringAsFixed(3)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '触发价格: ${trigger.triggeredPrice.toStringAsFixed(3)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Text(
                  _formatTime(trigger.triggeredAt),
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
