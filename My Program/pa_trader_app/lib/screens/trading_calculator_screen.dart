import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_input_field.dart';
import '../models/setup_option.dart';
import '../models/trade_record.dart';
import '../services/database_service.dart';
import '../widgets/trading_input_section.dart';
import 'setup_detail_screen.dart';
import 'home_screen.dart';

class TradingCalculatorScreen extends StatefulWidget {
  const TradingCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<TradingCalculatorScreen> createState() => TradingCalculatorScreenState();
}

class TradingCalculatorScreenState extends State<TradingCalculatorScreen> {
  // 所有控制器
  late TextEditingController stockNameController;
  late TextEditingController currentTimeController;
  late TextEditingController capitalController;
  late TextEditingController stopLossPercentController;
  late TextEditingController positionPercentController;
  late TextEditingController setupController;
  late TextEditingController holdingDaysController;
  late TextEditingController entryPeriodController;
  late TextEditingController entryPriceController;
  late TextEditingController lotsController;
  late TextEditingController usedCapitalController;
  late TextEditingController stopLossController;
  late TextEditingController onceTargetPriceController;
  late TextEditingController doubleTargetPriceController;
  late TextEditingController prevLowController;
  late TextEditingController prevHighController;
  late TextEditingController waveDiffController;
  late TextEditingController fiftyPercentRetraceController;
  late TextEditingController actualExitController;
  late TextEditingController riskRewardController;
  late TextEditingController notesController;

  Map<String, SetupOption> setupOptions = {};
  SetupOption? currentSetup;
  
  final DatabaseService _databaseService = DatabaseService();
  TradeRecord? _editingRecord;

  @override
  void initState() {
    super.initState();
    _initControllers();
    setupOptions = SetupOption.predefinedOptions;
    _updateCurrentTime();
  }

  void _initControllers() {
    stockNameController = TextEditingController();
    currentTimeController = TextEditingController();
    capitalController = TextEditingController(text: '30');
    stopLossPercentController = TextEditingController(text: '1%');
    positionPercentController = TextEditingController();
    setupController = TextEditingController();
    holdingDaysController = TextEditingController();
    entryPeriodController = TextEditingController(text: '120min筛选/5min入场');
    entryPriceController = TextEditingController();
    lotsController = TextEditingController();
    usedCapitalController = TextEditingController();
    stopLossController = TextEditingController();
    onceTargetPriceController = TextEditingController();
    doubleTargetPriceController = TextEditingController();
    prevLowController = TextEditingController();
    prevHighController = TextEditingController();
    waveDiffController = TextEditingController();
    fiftyPercentRetraceController = TextEditingController();
    actualExitController = TextEditingController();
    riskRewardController = TextEditingController();
    notesController = TextEditingController();
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    currentTimeController.text = DateFormat('yyyy-MM-dd HH:mm').format(now);
  }

  void updateSetupOptions(Map<String, SetupOption> options) {
    setState(() {
      setupOptions = options;
      if (setupController.text.isNotEmpty && options.containsKey(setupController.text)) {
        currentSetup = options[setupController.text];
      }
    });
  }

  void loadRecordForEdit(TradeRecord record) {
    setState(() {
      _editingRecord = record;
      
      // 填充所有数据
      stockNameController.text = record.stockName;
      capitalController.text = record.capital ?? '10';
      stopLossPercentController.text = record.stopLossPercent ?? '1%';
      setupController.text = record.setup ?? '';
      holdingDaysController.text = record.holdingDays ?? '';
      entryPeriodController.text = record.entryPeriod ?? '120min筛选/5min入场';
      entryPriceController.text = record.entryPrice ?? '';
      stopLossController.text = record.stopLoss ?? '';
      prevLowController.text = record.prevLow ?? '';
      prevHighController.text = record.prevHigh ?? '';
      actualExitController.text = record.actualExit ?? '';
      notesController.text = record.notes ?? '';
      
      // 触发自动计算
      autoCalculate();
      
      // 更新Setup显示
      if (record.setup != null && setupOptions.containsKey(record.setup)) {
        currentSetup = setupOptions[record.setup];
      }
    });
  }

  @override
  void dispose() {
    stockNameController.dispose();
    currentTimeController.dispose();
    capitalController.dispose();
    stopLossPercentController.dispose();
    positionPercentController.dispose();
    setupController.dispose();
    holdingDaysController.dispose();
    entryPeriodController.dispose();
    entryPriceController.dispose();
    lotsController.dispose();
    usedCapitalController.dispose();
    stopLossController.dispose();
    onceTargetPriceController.dispose();
    doubleTargetPriceController.dispose();
    prevLowController.dispose();
    prevHighController.dispose();
    waveDiffController.dispose();
    fiftyPercentRetraceController.dispose();
    actualExitController.dispose();
    riskRewardController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void autoCalculate() {
    _calculateLots();
    _calculateUsedCapital();
    _calculatePositionPercent();
    _calculateWaveDifference();
    _calculateTargetPrices();
    _calculateFiftyPercentRetrace();
    _calculateRiskReward();
    setState(() {});
  }

  void _calculateLots() {
    try {
      double capital = double.tryParse(capitalController.text) ?? 0;
      capital *= 10000;
      
      String percentStr = stopLossPercentController.text;
      double stopLossPercent = double.tryParse(percentStr.replaceAll('%', '')) ?? 0;
      stopLossPercent /= 100;
      
      double entryPrice = double.tryParse(entryPriceController.text) ?? 0;
      double stopLoss = double.tryParse(stopLossController.text) ?? 0;
      
      if (entryPrice > 0 && stopLoss > 0 && entryPrice != stopLoss) {
        double priceDiff = (entryPrice - stopLoss).abs();
        if (priceDiff > 0) {
          double lots = (capital * stopLossPercent) / priceDiff;
          lots = (lots ~/ 100).toDouble();
          lotsController.text = lots.toInt().toString();
        }
      }
    } catch (e) {
      lotsController.text = '';
    }
  }

  void _calculateUsedCapital() {
    try {
      double entryPrice = double.tryParse(entryPriceController.text) ?? 0;
      int lots = int.tryParse(lotsController.text) ?? 0;
      
      if (entryPrice > 0 && lots > 0) {
        double usedCapital = lots * 100 * entryPrice;
        usedCapitalController.text = usedCapital.toStringAsFixed(3);
      }
    } catch (e) {
      usedCapitalController.text = '';
    }
  }

  void _calculatePositionPercent() {
    try {
      double capital = double.tryParse(capitalController.text) ?? 0;
      capital *= 10000;
      
      double usedCapital = double.tryParse(usedCapitalController.text) ?? 0;
      
      if (usedCapital > 0 && capital > 0) {
        double positionPercent = (usedCapital * 100) / capital;
        positionPercentController.text = '${positionPercent.toStringAsFixed(3)}%';
      }
    } catch (e) {
      positionPercentController.text = '';
    }
  }

  void _calculateWaveDifference() {
    try {
      double prevHigh = double.tryParse(prevHighController.text) ?? 0;
      double prevLow = double.tryParse(prevLowController.text) ?? 0;
      
      if (prevHigh > 0 && prevLow > 0) {
        double waveDiff = prevHigh - prevLow;
        waveDiffController.text = waveDiff.toStringAsFixed(3);
      }
    } catch (e) {
      waveDiffController.text = '';
    }
  }

  void _calculateFiftyPercentRetrace() {
    try {
      double prevHigh = double.tryParse(prevHighController.text) ?? 0;
      double prevLow = double.tryParse(prevLowController.text) ?? 0;
      
      if (prevHigh > 0 && prevLow > 0) {
        double retrace = prevLow + (prevHigh - prevLow) / 2;
        fiftyPercentRetraceController.text = retrace.toStringAsFixed(3);
      }
    } catch (e) {
      fiftyPercentRetraceController.text = '';
    }
  }

  void _calculateTargetPrices() {
    try {
      double entryPrice = double.tryParse(entryPriceController.text) ?? 0;
      double stopLoss = double.tryParse(stopLossController.text) ?? 0;
      
      if (entryPrice > 0 && stopLoss > 0) {
        double priceDiff = entryPrice - stopLoss;
        if (priceDiff > 0) {
          double targetPrice1x = priceDiff + entryPrice;
          onceTargetPriceController.text = targetPrice1x.toStringAsFixed(3);
          
          double targetPrice2x = priceDiff * 2 + entryPrice;
          doubleTargetPriceController.text = targetPrice2x.toStringAsFixed(3);
        }
      }
    } catch (e) {
      onceTargetPriceController.text = '';
      doubleTargetPriceController.text = '';
    }
  }

  void _calculateRiskReward() {
    try {
      double entryPrice = double.tryParse(entryPriceController.text) ?? 0;
      double stopLoss = double.tryParse(stopLossController.text) ?? 0;
      
      if (entryPrice == 0 || stopLoss == 0) return;
      
      double loss = entryPrice - stopLoss;
      if (loss <= 0) return;
      
      double actualExit = double.tryParse(actualExitController.text) ?? 0;
      
      if (actualExit > 0) {
        double profit = actualExit - entryPrice;
        double riskReward = profit / loss;
        riskRewardController.text = '实际: ${riskReward.toStringAsFixed(3)}:1';
      } else {
        double targetPrice = double.tryParse(onceTargetPriceController.text) ?? 0;
        if (targetPrice > 0) {
          double profit = targetPrice - entryPrice;
          double riskReward = profit / loss;
          riskRewardController.text = '预期: ${riskReward.toStringAsFixed(3)}:1';
        }
      }
    } catch (e) {
      riskRewardController.text = '';
    }
  }

  void onSetupChange(String? value) {
    if (value != null && setupOptions.containsKey(value)) {
      setState(() {
        currentSetup = setupOptions[value];
      });
    }
  }

  Future<void> _saveRecord() async {
    if (stockNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入股票名称')),
      );
      return;
    }

    try {
      final now = DateTime.now();
      final record = TradeRecord(
        id: _editingRecord?.id,
        stockName: stockNameController.text,
        tradeDate: _editingRecord?.tradeDate ?? now,
        updateTime: _editingRecord != null ? now : null,
        capital: capitalController.text,
        stopLossPercent: stopLossPercentController.text,
        setup: setupController.text,
        holdingDays: holdingDaysController.text,
        entryPeriod: entryPeriodController.text,
        entryPrice: entryPriceController.text,
        stopLoss: stopLossController.text,
        prevLow: prevLowController.text,
        prevHigh: prevHighController.text,
        actualExit: actualExitController.text,
        notes: notesController.text,
        lots: lotsController.text,
        usedCapital: usedCapitalController.text,
        positionPercent: positionPercentController.text,
        waveDiff: waveDiffController.text,
        onceTargetPrice: onceTargetPriceController.text,
        doubleTargetPrice: doubleTargetPriceController.text,
        fiftyPercentRetrace: fiftyPercentRetraceController.text,
        riskReward: riskRewardController.text,
      );

      if (_editingRecord != null) {
        await _databaseService.updateRecord(record);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新成功')),
        );
      } else {
        await _databaseService.insertRecord(record);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
      }

      // 清空编辑状态
      setState(() {
        _editingRecord = null;
      });
      
      // 可选：清空表单
      _clearForm();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  void _clearForm() {
    stockNameController.clear();
    capitalController.text = '10';
    stopLossPercentController.text = '1%';
    setupController.clear();
    holdingDaysController.clear();
    entryPeriodController.text = '120min筛选/5min入场';
    entryPriceController.clear();
    stopLossController.clear();
    prevLowController.clear();
    prevHighController.clear();
    actualExitController.clear();
    notesController.clear();
    _updateCurrentTime();
    autoCalculate();
    setState(() {
      _editingRecord = null;
      currentSetup = null;
    });
  }

  void _navigateToHistory() {
    HomeScreen.of(context)?.switchToTab(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PA Trader'),
        elevation: 2,
        actions: [
          // 历史记录按钮
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _navigateToHistory,
          ),
          // 新建记录按钮
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _clearForm,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 股票信息和时间栏
              LayoutBuilder(
  builder: (context, constraints) {
    // 判断是否为手机模式（宽度小于600）
    bool isMobile = constraints.maxWidth < 600;
    
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isMobile
            ? Column(
                children: [
                  // 手机模式：股票名称单独一行
                  CustomInputField(
                    label: '股票名称:',
                    controller: stockNameController,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 12),
                  // 手机模式：当前时间单独一行
                  ReadOnlyDisplayField(
                    label: '当前时间:',
                    value: currentTimeController.text,
                  ),
                ],
              )
            : Row(
                children: [
                  // 平板/桌面模式：一行显示两个
                  Expanded(
                    child: CustomInputField(
                      label: '股票名称:',
                      controller: stockNameController,
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReadOnlyDisplayField(
                      label: '当前时间:',
                      value: currentTimeController.text,
                    ),
                  ),
                ],
              ),
      ),
    );
  },
),
              
              // Setup信息区域
              if (currentSetup != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        final setupList = setupOptions.values.toList();
                        final index = setupList.indexWhere((s) => s.id == currentSetup!.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SetupDetailScreen(
                              setups: setupList,
                              initialIndex: index >= 0 ? index : 0,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '当前 Setup: ${setupController.text}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentSetup?.shortDescription ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '查看详情',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              
              // 交易参数输入区域
              TradingInputSection(
                onAutoCalculate: autoCalculate,
                onSetupChange: onSetupChange,
                capitalController: capitalController,
                stopLossPercentController: stopLossPercentController,
                positionPercentController: positionPercentController,
                setupController: setupController,
                holdingDaysController: holdingDaysController,
                entryPeriodController: entryPeriodController,
                entryPriceController: entryPriceController,
                lotsController: lotsController,
                usedCapitalController: usedCapitalController,
                stopLossController: stopLossController,
                onceTargetPriceController: onceTargetPriceController,
                doubleTargetPriceController: doubleTargetPriceController,
                prevLowController: prevLowController,
                prevHighController: prevHighController,
                waveDiffController: waveDiffController,
                fiftyPercentRetraceController: fiftyPercentRetraceController,
                actualExitController: actualExitController,
                riskRewardController: riskRewardController,
                setupOptions: setupOptions.keys.toList(),
              ),
              const SizedBox(height: 8),
              
              // 备注输入
              Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '备注',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '添加备注...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 保存按钮
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveRecord,
                        icon: Icon(_editingRecord != null ? Icons.update : Icons.save),
                        label: Text(_editingRecord != null ? '更新记录' : '保存记录'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (_editingRecord != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearForm,
                          icon: const Icon(Icons.close),
                          label: const Text('取消编辑'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}