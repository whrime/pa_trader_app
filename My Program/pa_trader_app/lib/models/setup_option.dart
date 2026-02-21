class SetupOption {
  final String concept;
  final String entryPoint;
  final String stopLoss;
  final String targetPrice;
  final String reason;
  final String chartIllustration;
  final String chartDescription;

  SetupOption({
    required this.concept,
    required this.entryPoint,
    required this.stopLoss,
    required this.targetPrice,
    required this.reason,
    required this.chartIllustration,
    required this.chartDescription,
  });

  // 从Map创建对象
  factory SetupOption.fromMap(String key, Map<String, dynamic> map) {
    return SetupOption(
      concept: map['概念'] ?? '',
      entryPoint: map['入场点'] ?? '',
      stopLoss: map['止损点'] ?? '',
      targetPrice: map['上涨目标位'] ?? '',
      reason: map['原因'] ?? '',
      chartIllustration: map['图例'] ?? '',
      chartDescription: map['图例说明'] ?? '',
    );
  }

  // 预定义的选项数据
  static Map<String, SetupOption> get predefinedOptions {
    return {
      '突破回调': SetupOption(
        concept: '价格突破后回踩确认入场',
        entryPoint: '回踩支撑位',
        stopLoss: '突破前低点',
        targetPrice: '前高阻力位',
        reason: '趋势延续',
        chartIllustration: 'breakout_pullback.png',
        chartDescription: '突破回调图表示例',
      ),
      '双底形态': SetupOption(
        concept: 'W形态底部反转',
        entryPoint: '颈线突破',
        stopLoss: '第二个底部下方',
        targetPrice: '形态高度1:1',
        reason: '反转信号',
        chartIllustration: 'double_bottom.png',
        chartDescription: '双底形态图表示例',
      ),
      '头肩底': SetupOption(
        concept: '经典反转形态',
        entryPoint: '颈线突破',
        stopLoss: '右肩下方',
        targetPrice: '头到颈线距离',
        reason: '趋势反转',
        chartIllustration: 'head_shoulders.png',
        chartDescription: '头肩底图表示例',
      ),
      '三角形整理': SetupOption(
        concept: '收敛整理后突破',
        entryPoint: '趋势线突破',
        stopLoss: '形态内部',
        targetPrice: '形态高度',
        reason: '整理结束',
        chartIllustration: 'triangle.png',
        chartDescription: '三角形整理图表示例',
      ),
    };
  }
}