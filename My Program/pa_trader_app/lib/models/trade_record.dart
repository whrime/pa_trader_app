class TradeRecord {
  int? id;
  String stockName;
  DateTime tradeDate;
  DateTime? updateTime;

  String? capital;
  String? stopLossPercent;
  String? setup;
  String? holdingDays;
  String? entryPeriod;
  String? entryPrice;
  String? stopLoss;
  String? prevLow;
  String? prevHigh;
  String? actualExit;
  String? notes;
  
  String? lots;
  String? usedCapital;
  String? positionPercent;
  String? waveDiff;
  String? onceTargetPrice;
  String? doubleTargetPrice;
  String? fiftyPercentRetrace;
  String? riskReward;

  TradeRecord({
    this.id,
    required this.stockName,
    required this.tradeDate,
    this.updateTime,
    this.capital,
    this.stopLossPercent,
    this.setup,
    this.holdingDays,
    this.entryPeriod,
    this.entryPrice,
    this.stopLoss,
    this.prevLow,
    this.prevHigh,
    this.actualExit,
    this.notes,
    this.lots,
    this.usedCapital,
    this.positionPercent,
    this.waveDiff,
    this.onceTargetPrice,
    this.doubleTargetPrice,
    this.fiftyPercentRetrace,
    this.riskReward,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stockName': stockName,
      'tradeDate': tradeDate.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
      'capital': capital,
      'stopLossPercent': stopLossPercent,
      'setup': setup,
      'holdingDays': holdingDays,
      'entryPeriod': entryPeriod,
      'entryPrice': entryPrice,
      'stopLoss': stopLoss,
      'prevLow': prevLow,
      'prevHigh': prevHigh,
      'actualExit': actualExit,
      'notes': notes,
      'lots': lots,
      'usedCapital': usedCapital,
      'positionPercent': positionPercent,
      'waveDiff': waveDiff,
      'onceTargetPrice': onceTargetPrice,
      'doubleTargetPrice': doubleTargetPrice,
      'fiftyPercentRetrace': fiftyPercentRetrace,
      'riskReward': riskReward,
    };
  }

  factory TradeRecord.fromMap(Map<String, dynamic> map) {
    return TradeRecord(
      id: map['id'],
      stockName: map['stockName'],
      tradeDate: DateTime.parse(map['tradeDate']),
      updateTime: map['updateTime'] != null ? DateTime.parse(map['updateTime']) : null,
      capital: map['capital'],
      stopLossPercent: map['stopLossPercent'],
      setup: map['setup'],
      holdingDays: map['holdingDays'],
      entryPeriod: map['entryPeriod'],
      entryPrice: map['entryPrice'],
      stopLoss: map['stopLoss'],
      prevLow: map['prevLow'],
      prevHigh: map['prevHigh'],
      actualExit: map['actualExit'],
      notes: map['notes'],
      lots: map['lots'],
      usedCapital: map['usedCapital'],
      positionPercent: map['positionPercent'],
      waveDiff: map['waveDiff'],
      onceTargetPrice: map['onceTargetPrice'],
      doubleTargetPrice: map['doubleTargetPrice'],
      fiftyPercentRetrace: map['fiftyPercentRetrace'],
      riskReward: map['riskReward'],
    );
  }
}
