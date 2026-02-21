import 'package:flutter/material.dart';
import 'custom_input_field.dart';

class TradingInputSection extends StatefulWidget {
  final Function() onAutoCalculate;
  final Function(String) onSetupChange;
  final TextEditingController capitalController;
  final TextEditingController stopLossPercentController;
  final TextEditingController positionPercentController;
  final TextEditingController setupController;
  final TextEditingController holdingDaysController;
  final TextEditingController entryPeriodController;
  final TextEditingController entryPriceController;
  final TextEditingController lotsController;
  final TextEditingController usedCapitalController;
  final TextEditingController stopLossController;
  final TextEditingController onceTargetPriceController;
  final TextEditingController doubleTargetPriceController;
  final TextEditingController prevLowController;
  final TextEditingController prevHighController;
  final TextEditingController waveDiffController;
  final TextEditingController actualExitController;
  final TextEditingController riskRewardController;
  final List<String> setupOptions;

  const TradingInputSection({
    Key? key,
    required this.onAutoCalculate,
    required this.onSetupChange,
    required this.capitalController,
    required this.stopLossPercentController,
    required this.positionPercentController,
    required this.setupController,
    required this.holdingDaysController,
    required this.entryPeriodController,
    required this.entryPriceController,
    required this.lotsController,
    required this.usedCapitalController,
    required this.stopLossController,
    required this.onceTargetPriceController,
    required this.doubleTargetPriceController,
    required this.prevLowController,
    required this.prevHighController,
    required this.waveDiffController,
    required this.actualExitController,
    required this.riskRewardController,
    required this.setupOptions,
  }) : super(key: key);

  @override
  State<TradingInputSection> createState() => _TradingInputSectionState();
}

class _TradingInputSectionState extends State<TradingInputSection> {
  @override
  void initState() {
    super.initState();
    // 初始设置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onAutoCalculate();
    });
  }

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
              '交易参数输入',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            
            // 第一行：总资金、止损百分比、仓位占比
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomInputField(
                    label: '总资金(w):',
                    controller: widget.capitalController,
                    onChanged: (_) => widget.onAutoCalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomInputField(
                    label: '止损百分比:',
                    controller: widget.stopLossPercentController,
                    dropdownItems: const ['0.5%', '1%', '2%', '3%', '4%'],
                    onChanged: (_) => widget.onAutoCalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReadOnlyDisplayField(
                    label: '仓位占比:',
                    value: widget.positionPercentController.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 第二行：Setup、持仓时间、入场周期
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomInputField(
                    label: 'Setup:',
                    controller: widget.setupController,
                    dropdownItems: widget.setupOptions,
                    onChanged: (value) {
                      widget.onSetupChange(value);
                      widget.onAutoCalculate();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomInputField(
                    label: '持仓时间(天):',
                    controller: widget.holdingDaysController,
                    onChanged: (_) => widget.onAutoCalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomInputField(
                    label: '入场周期:',
                    controller: widget.entryPeriodController,
                    dropdownItems: const [
                      '120min筛选/5min入场',
                      '60min筛选/15min入场',
                      '日线筛选/60min入场',
                      '周线筛选/日线入场'
                    ],
                    onChanged: (_) => widget.onAutoCalculate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 第三行：建仓、手数、使用资金
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomInputField(
                    label: '建仓:',
                    controller: widget.entryPriceController,
                    onChanged: (_) => widget.onAutoCalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReadOnlyDisplayField(
                    label: '手数:',
                    value: widget.lotsController.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReadOnlyDisplayField(
                    label: '使用资金:',
                    value: widget.usedCapitalController.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 第四行：止损、一倍目标价、两倍目标价
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomInputField(
                    label: '止损:',
                    controller: widget.stopLossController,
                    onChanged: (_) => widget.onAutoCalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReadOnlyDisplayField(
                    label: '一倍目标价:',
                    value: widget.onceTargetPriceController.text,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReadOnlyDisplayField(
                    label: '两倍目标价:',
                    value: widget.doubleTargetPriceController.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 第五行：前波段低点、前波段高点、波段差
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomInputField(
                    label: '前波段低点:',
                    controller: widget.prevLowController,
                    onChanged: (_) => widget.onAutoCalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomInputField(
                    label: '前波段高点:',
                    controller: widget.prevHighController,
                    onChanged: (_) => widget.onAutoCalculate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReadOnlyDisplayField(
                    label: '波段差:',
                    value: widget.waveDiffController.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 第六行：实际出场价、盈亏比
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomInputField(
                    label: '实际出场价:',
                    controller: widget.actualExitController,
                    onChanged: (_) {
                      // 只触发盈亏比计算
                      widget.riskRewardController.text = _calculateRiskReward();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ReadOnlyDisplayField(
                    label: '盈亏比:',
                    value: widget.riskRewardController.text,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculateRiskReward() {
    try {
      double entryPrice = double.tryParse(widget.entryPriceController.text) ?? 0;
      double stopLoss = double.tryParse(widget.stopLossController.text) ?? 0;
      
      if (entryPrice == 0 || stopLoss == 0) return '';
      
      double loss = entryPrice - stopLoss;
      if (loss <= 0) return '';
      
      double actualExit = double.tryParse(widget.actualExitController.text) ?? 0;
      
      if (actualExit > 0) {
        double profit = actualExit - entryPrice;
        double riskReward = profit / loss;
        return '实际: ${riskReward.toStringAsFixed(2)}:1';
      } else {
        double targetPrice = double.tryParse(widget.onceTargetPriceController.text) ?? 0;
        if (targetPrice > 0) {
          double profit = targetPrice - entryPrice;
          double riskReward = profit / loss;
          return '预期: ${riskReward.toStringAsFixed(2)}:1';
        }
      }
    } catch (e) {
      return '';
    }
    return '';
  }
}