import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trade_record.dart';

class HistoryDetailScreen extends StatefulWidget {
  final List<TradeRecord> records;
  final int initialIndex;

  const HistoryDetailScreen({
    Key? key,
    required this.records,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
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
    if (_currentIndex < widget.records.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.records[_currentIndex].stockName}'),
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
              itemCount: widget.records.length,
              itemBuilder: (context, index) {
                return _HistoryDetailContent(
                  record: widget.records[index],
                  formatDate: _formatDate,
                );
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Text(
              '${_currentIndex + 1} / ${widget.records.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _currentIndex < widget.records.length - 1 ? _goToNext : null,
              icon: const Text('下一个'),
              label: const Icon(Icons.keyboard_arrow_down, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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

class _HistoryDetailContent extends StatelessWidget {
  final TradeRecord record;
  final String Function(DateTime) formatDate;

  const _HistoryDetailContent({
    required this.record,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard('基本信息', [
              _buildDetailRow('股票名称', record.stockName),
              _buildDetailRow('交易时间', formatDate(record.tradeDate)),
              if (record.updateTime != null)
                _buildDetailRow('更新时间', formatDate(record.updateTime!)),
              _buildDetailRow('Setup策略', record.setup ?? '-'),
            ]),
            _buildSectionCard('资金与风险', [
              _buildDetailRow('总资金(w)', record.capital?.toString() ?? '-'),
              _buildDetailRow('止损百分比', '${record.stopLossPercent ?? '-'}'),
              _buildDetailRow('持仓时间(天)', record.holdingDays?.toString() ?? '-'),
              _buildDetailRow('入场周期', record.entryPeriod ?? '-'),
            ]),
            _buildSectionCard('入场与止损', [
              _buildDetailRow('入场价', record.entryPrice?.toString() ?? '-'),
              _buildDetailRow('止损价', record.stopLoss?.toString() ?? '-'),
              _buildDetailRow('手数', record.lots?.toString() ?? '-'),
              _buildDetailRow('使用资金', record.usedCapital?.toString() ?? '-'),
              _buildDetailRow('仓位占比', '${record.positionPercent ?? '-'}'),
            ]),
            _buildSectionCard('目标价位', [
              _buildDetailRow('前波段低点', record.prevLow?.toString() ?? '-'),
              _buildDetailRow('前波段高点', record.prevHigh?.toString() ?? '-'),
              _buildDetailRow('波段差', record.waveDiff?.toString() ?? '-'),
              _buildDetailRow('50%回调位', record.fiftyPercentRetrace?.toString() ?? '-'),
              _buildDetailRow('一倍目标价', record.onceTargetPrice?.toString() ?? '-'),
              _buildDetailRow('二倍目标价', record.doubleTargetPrice?.toString() ?? '-'),
            ]),
            _buildSectionCard('交易结果', [
              _buildDetailRow('实际出场价', record.actualExit?.toString() ?? '-'),
              _buildDetailRow('风报比', record.riskReward?.toString() ?? '-'),
            ]),
            if (record.notes != null && record.notes!.isNotEmpty)
              _buildSectionCard('备注', [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    record.notes!,
                    style: const TextStyle(height: 1.6),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
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
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
