import 'package:flutter/material.dart';

// 预警设置 - 每个周期可以有多个预警
class AlertSetting {
  final List<double> upperPrices; // 上沿价格
  final List<double> lowerPrices; // 下沿价格
  final DateTime createdAt;
  final DateTime updatedAt;

  AlertSetting({
    this.upperPrices = const [],
    this.lowerPrices = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // 检查价格是否达到预警
  List<AlertTrigger> checkPrice(double currentPrice) {
    final triggers = <AlertTrigger>[];
    
    // 检查上沿
    for (final price in upperPrices) {
      if (currentPrice >= price) {
        triggers.add(AlertTrigger(
          taskCardId: '',
          stockName: '',
          periodType: '',
          type: AlertType.upper,
          price: price,
          triggeredPrice: currentPrice,
          triggeredAt: DateTime.now(),
        ));
      }
    }
    
    // 检查下沿
    for (final price in lowerPrices) {
      if (currentPrice <= price) {
        triggers.add(AlertTrigger(
          taskCardId: '',
          stockName: '',
          periodType: '',
          type: AlertType.lower,
          price: price,
          triggeredPrice: currentPrice,
          triggeredAt: DateTime.now(),
        ));
      }
    }
    
    return triggers;
  }

  Map<String, dynamic> toJson() => {
        'upperPrices': upperPrices,
        'lowerPrices': lowerPrices,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AlertSetting.fromJson(Map<String, dynamic> json) {
    return AlertSetting(
      upperPrices: List<double>.from(json['upperPrices'] ?? []),
      lowerPrices: List<double>.from(json['lowerPrices'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  AlertSetting copyWith({
    List<double>? upperPrices,
    List<double>? lowerPrices,
    DateTime? updatedAt,
  }) {
    return AlertSetting(
      upperPrices: upperPrices ?? this.upperPrices,
      lowerPrices: lowerPrices ?? this.lowerPrices,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// 预警触发记录
class AlertTrigger {
  final String id;
  final String taskCardId;
  final String stockName;
  final String periodType;
  final AlertType type; // 上沿或下沿
  final double price; // 预警价格
  final double triggeredPrice; // 触发时的实际价格
  final DateTime triggeredAt;
  final bool isMarked; // 是否已标记

  AlertTrigger({
    String? id,
    required this.taskCardId,
    required this.stockName,
    required this.periodType,
    required this.type,
    required this.price,
    required this.triggeredPrice,
    required this.triggeredAt,
    this.isMarked = false,
  }) : id = id ?? '${DateTime.now().millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskCardId': taskCardId,
        'stockName': stockName,
        'periodType': periodType,
        'type': type.name,
        'price': price,
        'triggeredPrice': triggeredPrice,
        'triggeredAt': triggeredAt.toIso8601String(),
        'isMarked': isMarked,
      };

  factory AlertTrigger.fromJson(Map<String, dynamic> json) {
    return AlertTrigger(
      id: json['id'],
      taskCardId: json['taskCardId'],
      stockName: json['stockName'],
      periodType: json['periodType'],
      type: AlertType.values.firstWhere((e) => e.name == json['type']),
      price: json['price'].toDouble(),
      triggeredPrice: json['triggeredPrice'].toDouble(),
      triggeredAt: DateTime.parse(json['triggeredAt']),
      isMarked: json['isMarked'] ?? false,
    );
  }

  AlertTrigger copyWith({bool? isMarked}) {
    return AlertTrigger(
      id: id,
      taskCardId: taskCardId,
      stockName: stockName,
      periodType: periodType,
      type: type,
      price: price,
      triggeredPrice: triggeredPrice,
      triggeredAt: triggeredAt,
      isMarked: isMarked ?? this.isMarked,
    );
  }
}

// 预警类型
enum AlertType {
  upper, // 上沿
  lower, // 下沿
}

// 预警类型扩展
extension AlertTypeExtension on AlertType {
  String get name {
    switch (this) {
      case AlertType.upper:
        return '上沿';
      case AlertType.lower:
        return '下沿';
    }
  }

  Color get color {
    switch (this) {
      case AlertType.upper:
        return Colors.red;
      case AlertType.lower:
        return Colors.green;
    }
  }

  String get icon {
    switch (this) {
      case AlertType.upper:
        return '↑';
      case AlertType.lower:
        return '↓';
    }
  }
}
