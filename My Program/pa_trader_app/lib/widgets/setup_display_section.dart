import 'package:flutter/material.dart';
import '../models/setup_option.dart';


class SetupDisplaySection extends StatelessWidget {
  final SetupOption? currentSetup;
  final String setupName;

  const SetupDisplaySection({
    Key? key,
    required this.currentSetup,
    required this.setupName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Setup详细信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            
            // 左右分栏
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：图表区域
                Expanded(
                  child: _buildChartSection(),
                ),
                const SizedBox(width: 16),
                // 右侧：详细说明
                Expanded(
                  child: _buildDetailSection(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '图表示例',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: currentSetup != null
              ? _buildChartContent()
              : _buildEmptyChart(),
        ),
      ],
    );
  }

  Widget _buildChartContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Setup: $setupName',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('图表: ${currentSetup!.chartIllustration}'),
          const SizedBox(height: 4),
          Text('图例说明: ${currentSetup!.chartDescription}'),
          const SizedBox(height: 8),
          const Text(
            '（图表占位区域）',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return const Center(
      child: Text(
        '请选择一个Setup查看详细信息\n\n图表显示区域',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Setup详细说明',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: currentSetup != null
              ? _buildDetailTable()
              : _buildEmptyDetail(),
        ),
      ],
    );
  }

  Widget _buildDetailTable() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildDetailRow('概念', currentSetup!.concept),
        const Divider(),
        _buildDetailRow('入场点', currentSetup!.entryPoint),
        const Divider(),
        _buildDetailRow('止损点', currentSetup!.stopLoss),
        const Divider(),
        _buildDetailRow('上涨目标位', currentSetup!.targetPrice),
        const Divider(),
        _buildDetailRow('原因', currentSetup!.reason),
      ],
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
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

  Widget _buildEmptyDetail() {
    return const Center(
      child: Text(
        '选择Setup查看详细说明',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}