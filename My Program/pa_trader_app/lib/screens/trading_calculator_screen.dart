import 'package:flutter/material.dart';
import '../models/setup_option.dart';
import '../widgets/trading_input_section.dart';
import '../widgets/setup_display_section.dart';

class TradingCalculatorScreen extends StatefulWidget {
  const TradingCalculatorScreen({Key? key}) : super(key: key);

  @override
  State<TradingCalculatorScreen> createState() => _TradingCalculatorScreenState();
}

class _TradingCalculatorScreenState extends State<TradingCalculatorScreen> {
  // 控制器
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
  late TextEditingController actualExitController;
  late TextEditingController riskRewardController;

  // 数据
  late Map<String, SetupOption> setupOptions;
  late SetupOption? currentSetup;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeData();
  }

  void _initializeControllers() {
    capitalController = TextEditingController(text: '10');
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
    actualExitController = TextEditingController();
    riskRewardController = TextEditingController();
  }

  void _initializeData() {
    setupOptions = SetupOption.predefinedOptions;
    currentSetup = null;
  }

  @override
  void dispose() {
    // 释放控制器
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
    actualExitController.dispose();
    riskRewardController.dispose();
    super.dispose();
  }

  // 自动计算所有值
  void autoCalculate() {
    calculateLots();
    calculateUsedCapital();
    calculatePositionPercent();
    calculateWaveDifference();
    calculateTargetPrices();
    calculateRiskReward();
    
    // 强制刷新UI
    setState(() {});
  }

  // 计算手数
  void calculateLots() {
    try {
      double capital = double.tryParse(capitalController.text) ?? 0;
      capital *= 10000; // 转换为元
      
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
        } else {
          lotsController.text = '0';
        }
      } else {
        lotsController.text = '';
      }
    } catch (e) {
      lotsController.text = '';
    }
  }

  // 计算使用资金
  void calculateUsedCapital() {
    try {
      double entryPrice = double.tryParse(entryPriceController.text) ?? 0;
      int lots = int.tryParse(lotsController.text) ?? 0;
      
      if (entryPrice > 0 && lots > 0) {
        double usedCapital = lots * 100 * entryPrice;
        usedCapitalController.text = _formatNumber(usedCapital);
      } else {
        usedCapitalController.text = '';
      }
    } catch (e) {
      usedCapitalController.text = '';
    }
  }

  // 计算仓位占比
  void calculatePositionPercent() {
    try {
      double capital = double.tryParse(capitalController.text) ?? 0;
      capital *= 10000;
      
      String usedCapitalStr = usedCapitalController.text.replaceAll(',', '');
      double usedCapital = double.tryParse(usedCapitalStr) ?? 0;
      
      if (usedCapital > 0 && capital > 0) {
        double positionPercent = (usedCapital * 100) / capital;
        positionPercentController.text = '${positionPercent.toStringAsFixed(2)}%';
      } else {
        positionPercentController.text = '';
      }
    } catch (e) {
      positionPercentController.text = '';
    }
  }

  // 计算波段差
  void calculateWaveDifference() {
    try {
      double prevHigh = double.tryParse(prevHighController.text) ?? 0;
      double prevLow = double.tryParse(prevLowController.text) ?? 0;
      
      if (prevHigh > 0 && prevLow > 0) {
        double waveDiff = prevHigh - prevLow;
        waveDiffController.text = waveDiff.toStringAsFixed(2);
      } else {
        waveDiffController.text = '';
      }
    } catch (e) {
      waveDiffController.text = '';
    }
  }

  // 计算目标价
  void calculateTargetPrices() {
    try {
      double entryPrice = double.tryParse(entryPriceController.text) ?? 0;
      double stopLoss = double.tryParse(stopLossController.text) ?? 0;
      
      if (entryPrice > 0 && stopLoss > 0) {
        double priceDiff = entryPrice - stopLoss;
        if (priceDiff > 0) {
          double targetPrice1x = priceDiff + entryPrice;
          onceTargetPriceController.text = targetPrice1x.toStringAsFixed(2);
          
          double targetPrice2x = priceDiff * 2 + entryPrice;
          doubleTargetPriceController.text = targetPrice2x.toStringAsFixed(2);
        } else {
          onceTargetPriceController.text = '';
          doubleTargetPriceController.text = '';
        }
      } else {
        onceTargetPriceController.text = '';
        doubleTargetPriceController.text = '';
      }
    } catch (e) {
      onceTargetPriceController.text = '';
      doubleTargetPriceController.text = '';
    }
  }

  // 计算盈亏比
  void calculateRiskReward() {
    try {
      double entryPrice = double.tryParse(entryPriceController.text) ?? 0;
      double stopLoss = double.tryParse(stopLossController.text) ?? 0;
      
      if (entryPrice == 0 || stopLoss == 0) {
        riskRewardController.text = '';
        return;
      }
      
      double loss = entryPrice - stopLoss;
      if (loss <= 0) {
        riskRewardController.text = '';
        return;
      }
      
      double actualExit = double.tryParse(actualExitController.text) ?? 0;
      
      if (actualExit > 0) {
        double profit = actualExit - entryPrice;
        double riskReward = profit / loss;
        riskRewardController.text = '实际: ${riskReward.toStringAsFixed(2)}:1';
      } else {
        double targetPrice = double.tryParse(onceTargetPriceController.text) ?? 0;
        if (targetPrice > 0) {
          double profit = targetPrice - entryPrice;
          double riskReward = profit / loss;
          riskRewardController.text = '预期: ${riskReward.toStringAsFixed(2)}:1';
        } else {
          riskRewardController.text = '';
        }
      }
    } catch (e) {
      riskRewardController.text = '';
    }
  }

  // 格式化数字
  String _formatNumber(double number) {
    return number.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Setup变化时
  void onSetupChange(String? value) {
    if (value != null && setupOptions.containsKey(value)) {
      setState(() {
        currentSetup = setupOptions[value];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PA Trader'),
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
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
                actualExitController: actualExitController,
                riskRewardController: riskRewardController,
                setupOptions: setupOptions.keys.toList(),
              ),
              
              // Setup详细信息区域
              SetupDisplaySection(
                currentSetup: currentSetup,
                setupName: setupController.text,
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}