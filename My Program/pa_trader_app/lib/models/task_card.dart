import 'package:flutter/material.dart';
import 'task_alert.dart';

class TaskCard {
  final String id;
  final String stockName;
  final String? groupId; // 所属分组ID
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TaskPeriod> periods;
  final List<DailyRecord> dailyRecords;

  TaskCard({
    required this.id,
    required this.stockName,
    this.groupId,
    required this.createdAt,
    required this.updatedAt,
    required this.periods,
    required this.dailyRecords,
  });

  TaskCard copyWith({
    String? id,
    String? stockName,
    String? groupId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TaskPeriod>? periods,
    List<DailyRecord>? dailyRecords,
  }) {
    return TaskCard(
      id: id ?? this.id,
      stockName: stockName ?? this.stockName,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      periods: periods ?? this.periods,
      dailyRecords: dailyRecords ?? this.dailyRecords,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stockName': stockName,
        'groupId': groupId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'periods': periods.map((p) => p.toJson()).toList(),
        'dailyRecords': dailyRecords.map((r) => r.toJson()).toList(),
      };

  factory TaskCard.fromJson(Map<String, dynamic> json) {
    return TaskCard(
      id: json['id'] ?? '',
      stockName: json['stockName'] ?? '',
      groupId: json['groupId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      periods: (json['periods'] as List?)
              ?.map((p) => TaskPeriod.fromJson(p))
              .toList() ??
          [],
      dailyRecords: (json['dailyRecords'] as List?)
              ?.map((r) => DailyRecord.fromJson(r))
              .toList() ??
          [],
    );
  }

  // 计算优先级分数
  double get priorityScore {
    if (periods.isEmpty) return 0;
    
    double totalScore = 0;
    double totalWeight = 0;
    
    for (var period in periods) {
      if (period.data != null) {
        totalScore += period.data!.score * period.weight;
        totalWeight += period.weight;
      }
    }
    
    if (totalWeight == 0) return 0;
    return totalScore / totalWeight;
  }

  // 获取优先级等级
  PriorityLevel get priorityLevel {
    final score = priorityScore.abs();
    if (score >= 4) return PriorityLevel.urgentImportant;
    if (score >= 3) return PriorityLevel.important;
    if (score >= 2) return PriorityLevel.normal;
    return PriorityLevel.low;
  }

  // 获取今日记录
  DailyRecord? getTodayRecord() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    try {
      return dailyRecords.firstWhere((r) {
        final recordDate = DateTime(r.date.year, r.date.month, r.date.day);
        return recordDate.isAtSameMomentAs(todayStart);
      });
    } catch (e) {
      return null;
    }
  }
}

class TaskPeriod {
  final String periodType; // 5分钟, 120分钟, 日, 周, 月, 季, 年
  final int sortOrder; // 排序顺序，数字越小越优先展示
  final bool isRequired; // 是否必填（120分钟为true）
  PeriodData? data;
  AlertSetting? alertSetting;

  TaskPeriod({
    required this.periodType,
    required this.sortOrder,
    this.isRequired = false,
    this.data,
    this.alertSetting,
  });

  double get weight {
    // 周期权重：短周期权重更高
    switch (periodType) {
      case '5分钟':
        return 0.25;
      case '120分钟':
        return 0.30; // 120分钟最重要
      case '日':
        return 0.25;
      case '周':
        return 0.12;
      case '月':
        return 0.05;
      case '季':
        return 0.02;
      case '年':
        return 0.01;
      default:
        return 0.1;
    }
  }

  Map<String, dynamic> toJson() => {
        'periodType': periodType,
        'sortOrder': sortOrder,
        'isRequired': isRequired,
        'data': data?.toJson(),
        'alertSetting': alertSetting?.toJson(),
      };

  factory TaskPeriod.fromJson(Map<String, dynamic> json) {
    return TaskPeriod(
      periodType: json['periodType'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      isRequired: json['isRequired'] ?? false,
      data: json['data'] != null ? PeriodData.fromJson(json['data']) : null,
      alertSetting: json['alertSetting'] != null ? AlertSetting.fromJson(json['alertSetting']) : null,
    );
  }
}

// 任务卡周期数据
class PeriodData {
  String? context; // 背景/环境
  String? pattern; // 形态
  String? signalK; // 信号K
  String? summary; // 总结
  double score; // 评分 -5 到 5

  PeriodData({
    this.context,
    this.pattern,
    this.signalK,
    this.summary,
    this.score = 0,
  });

  Map<String, dynamic> toJson() => {
        'context': context,
        'pattern': pattern,
        'signalK': signalK,
        'summary': summary,
        'score': score,
      };

  factory PeriodData.fromJson(Map<String, dynamic> json) {
    return PeriodData(
      context: json['context'],
      pattern: json['pattern'],
      signalK: json['signalK'],
      summary: json['summary'],
      score: (json['score'] ?? 0).toDouble(),
    );
  }
}

class DailyRecord {
  final DateTime date;
  final Map<String, PeriodData> periodDataMap; // key: periodType

  DailyRecord({
    required this.date,
    required this.periodDataMap,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'periodDataMap': periodDataMap.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    final mapData = json['periodDataMap'] as Map<String, dynamic>?;
    return DailyRecord(
      date: DateTime.parse(json['date']),
      periodDataMap: mapData?.map((k, v) => MapEntry(k, PeriodData.fromJson(v))) ?? {},
    );
  }
}

enum PriorityLevel {
  urgentImportant, // 紧急重要
  important,       // 重要
  normal,          // 普通
  low,             // 低优先级
}

extension PriorityLevelExtension on PriorityLevel {
  String get name {
    switch (this) {
      case PriorityLevel.urgentImportant:
        return '紧急重要';
      case PriorityLevel.important:
        return '重要';
      case PriorityLevel.normal:
        return '普通';
      case PriorityLevel.low:
        return '观望';
    }
  }

  Color get color {
    switch (this) {
      case PriorityLevel.urgentImportant:
        return Colors.red;
      case PriorityLevel.important:
        return Colors.orange;
      case PriorityLevel.normal:
        return Colors.blue;
      case PriorityLevel.low:
        return Colors.grey;
    }
  }
}

// 所有可用周期类型
final List<String> availablePeriodTypes = [
  '5分钟',
  '120分钟',
  '日',
  '周',
  '月',
  '季',
  '年',
];

// 评分说明
final String scoreDescription = '''
评分系统说明：

评分范围：-5.0 到 +5.0

正数（做多信号）：
• +4.0 ~ +5.0：强烈做多信号，建议重仓
• +3.0 ~ +4.0：明显做多信号，建议建仓
• +2.0 ~ +3.0：偏多信号，可轻仓尝试
• +1.0 ~ +2.0：轻微偏多，观望为主
• 0 ~ +1.0：略微偏多，等待确认

负数（做空信号）：
• -4.0 ~ -5.0：强烈做空信号，建议空仓或做空
• -3.0 ~ -4.0：明显做空信号，建议减仓
• -2.0 ~ -3.0：偏空信号，谨慎操作
• -1.0 ~ -2.0：轻微偏空，注意风险
• -1.0 ~ 0：略微偏空，观望为主

0分：中性，无明显信号，建议观望

绝对值越大，信号越明确；
接近0分，说明市场处于震荡或观望状态。
''';
