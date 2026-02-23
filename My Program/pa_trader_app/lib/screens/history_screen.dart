import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trade_record.dart';
import '../services/database_service.dart';
import 'home_screen.dart';

class HistoryScreen extends StatefulWidget {
  final Function(TradeRecord) onEditRecord;

  const HistoryScreen({
    Key? key,
    required this.onEditRecord,
  }) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<TradeRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final records = await _databaseService.getAllRecords();
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    }
  }

  Future<void> _deleteRecord(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _databaseService.deleteRecord(id);
        await _loadRecords();
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

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecords,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('暂无历史记录', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            record.stockName.isNotEmpty
                                ? record.stockName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        title: Text(
                          record.stockName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('建仓: ${record.entryPrice ?? '-'}'),
                            Text('时间: ${_formatDate(record.tradeDate)}'),
                            if (record.updateTime != null)
                              Text(
                                '更新: ${_formatDate(record.updateTime!)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                widget.onEditRecord(record);
                                HomeScreen.of(context)?.switchToTab(1);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRecord(record.id!),
                            ),
                          ],
                        ),
                        onTap: () {
                          // 点击查看详情
                          _showRecordDetail(record);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  void _showRecordDetail(TradeRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '交易详情 - ${record.stockName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildDetailRow('股票名称', record.stockName),
                      _buildDetailRow('交易时间', _formatDate(record.tradeDate)),
                      if (record.updateTime != null)
                        _buildDetailRow('更新时间', _formatDate(record.updateTime!)),
                      _buildDetailRow('Setup', record.setup ?? '-'),
                      _buildDetailRow('总资金(w)', record.capital ?? '-'),
                      _buildDetailRow('止损百分比', record.stopLossPercent ?? '-'),
                      _buildDetailRow('持仓时间(天)', record.holdingDays ?? '-'),
                      _buildDetailRow('入场周期', record.entryPeriod ?? '-'),
                      const Divider(),
                      _buildDetailRow('入场价', record.entryPrice ?? '-'),
                      _buildDetailRow('止损价', record.stopLoss ?? '-'),
                      _buildDetailRow('手数', record.lots ?? '-'),
                      _buildDetailRow('使用资金', record.usedCapital ?? '-'),
                      _buildDetailRow('仓位占比', record.positionPercent ?? '-'),
                      const Divider(),
                      _buildDetailRow('前波段低点', record.prevLow ?? '-'),
                      _buildDetailRow('前波段高点', record.prevHigh ?? '-'),
                      _buildDetailRow('波段差', record.waveDiff ?? '-'),
                      _buildDetailRow('50%回调位', record.fiftyPercentRetrace ?? '-'),
                      _buildDetailRow('一倍目标价', record.onceTargetPrice ?? '-'),
                      _buildDetailRow('二倍目标价', record.doubleTargetPrice ?? '-'),
                      const Divider(),
                      _buildDetailRow('实际出场价', record.actualExit ?? '-'),
                      _buildDetailRow('风报比', record.riskReward ?? '-'),
                      if (record.notes != null && record.notes!.isNotEmpty)
                        _buildDetailRow('备注', record.notes!),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}