import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trade_record.dart';
import '../models/task_card.dart';
import '../models/task_group.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'trade_records.db');
      
      print('Database path: $path');
      
      return await openDatabase(
        path,
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) {
          print('Database opened successfully');
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS trade_records(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          stockName TEXT NOT NULL,
          tradeDate TEXT NOT NULL,
          updateTime TEXT,
          capital TEXT,
          stopLossPercent TEXT,
          setup TEXT,
          holdingDays TEXT,
          entryPeriod TEXT,
          entryPrice TEXT,
          stopLoss TEXT,
          prevLow TEXT,
          prevHigh TEXT,
          actualExit TEXT,
          notes TEXT,
          lots TEXT,
          usedCapital TEXT,
          positionPercent TEXT,
          waveDiff TEXT,
          onceTargetPrice TEXT,
          doubleTargetPrice TEXT,
          fiftyPercentRetrace TEXT,
          riskReward TEXT
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_cards(
          id TEXT PRIMARY KEY,
          stockName TEXT NOT NULL,
          groupId TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          periods TEXT NOT NULL,
          dailyRecords TEXT NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_groups(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          sortOrder INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
      
      print('Database tables created successfully');
    } catch (e) {
      print('Error creating table: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE trade_records ADD COLUMN lots TEXT');
      await db.execute('ALTER TABLE trade_records ADD COLUMN usedCapital TEXT');
      await db.execute('ALTER TABLE trade_records ADD COLUMN positionPercent TEXT');
      await db.execute('ALTER TABLE trade_records ADD COLUMN waveDiff TEXT');
      await db.execute('ALTER TABLE trade_records ADD COLUMN onceTargetPrice TEXT');
      await db.execute('ALTER TABLE trade_records ADD COLUMN doubleTargetPrice TEXT');
      await db.execute('ALTER TABLE trade_records ADD COLUMN fiftyPercentRetrace TEXT');
      await db.execute('ALTER TABLE trade_records ADD COLUMN riskReward TEXT');
      print('Database upgraded to version 2');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_cards(
          id TEXT PRIMARY KEY,
          stockName TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL,
          periods TEXT NOT NULL,
          dailyRecords TEXT NOT NULL
        )
      ''');
      print('Database upgraded to version 3');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE task_cards ADD COLUMN groupId TEXT');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS task_groups(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          sortOrder INTEGER NOT NULL,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
      print('Database upgraded to version 4');
    }
  }

  Future<int> insertRecord(TradeRecord record) async {
    try {
      Database db = await database;
      int id = await db.insert('trade_records', record.toMap());
      print('Record inserted with id: $id');
      return id;
    } catch (e) {
      print('Error inserting record: $e');
      rethrow;
    }
  }

  Future<int> updateRecord(TradeRecord record) async {
    try {
      Database db = await database;
      int count = await db.update(
        'trade_records',
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
      print('Record updated: $count');
      return count;
    } catch (e) {
      print('Error updating record: $e');
      rethrow;
    }
  }

  Future<List<TradeRecord>> getAllRecords() async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'trade_records',
        orderBy: 'tradeDate DESC',
      );
      print('Found ${maps.length} records');
      return List.generate(maps.length, (i) {
        return TradeRecord.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error getting records: $e');
      return [];
    }
  }

  Future<int> deleteRecord(int id) async {
    try {
      Database db = await database;
      int count = await db.delete(
        'trade_records',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Record deleted: $count');
      return count;
    } catch (e) {
      print('Error deleting record: $e');
      rethrow;
    }
  }

  Future<TradeRecord?> getRecordById(int id) async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'trade_records',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return TradeRecord.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error getting record by id: $e');
      return null;
    }
  }

  // Task Card methods
  Future<void> saveTaskCard(TaskCard taskCard) async {
    try {
      Database db = await database;
      await db.insert(
        'task_cards',
        {
          'id': taskCard.id,
          'stockName': taskCard.stockName,
          'groupId': taskCard.groupId,
          'createdAt': taskCard.createdAt.toIso8601String(),
          'updatedAt': taskCard.updatedAt.toIso8601String(),
          'periods': jsonEncode(taskCard.periods.map((p) => p.toJson()).toList()),
          'dailyRecords': jsonEncode(taskCard.dailyRecords.map((r) => r.toJson()).toList()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('TaskCard saved: ${taskCard.id}');
    } catch (e) {
      print('Error saving task card: $e');
      rethrow;
    }
  }

  Future<List<TaskCard>> getAllTaskCards() async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'task_cards',
        orderBy: 'updatedAt DESC',
      );
      print('Found ${maps.length} task cards');
      return List.generate(maps.length, (i) {
        return TaskCard(
          id: maps[i]['id'],
          stockName: maps[i]['stockName'],
          createdAt: DateTime.parse(maps[i]['createdAt']),
          updatedAt: DateTime.parse(maps[i]['updatedAt']),
          periods: (jsonDecode(maps[i]['periods']) as List)
              .map((p) => TaskPeriod.fromJson(p))
              .toList(),
          dailyRecords: (jsonDecode(maps[i]['dailyRecords']) as List)
              .map((r) => DailyRecord.fromJson(r))
              .toList(),
        );
      });
    } catch (e) {
      print('Error getting task cards: $e');
      return [];
    }
  }

  Future<TaskCard?> getTaskCard(String id) async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'task_cards',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return TaskCard(
          id: maps[0]['id'],
          stockName: maps[0]['stockName'],
          createdAt: DateTime.parse(maps[0]['createdAt']),
          updatedAt: DateTime.parse(maps[0]['updatedAt']),
          periods: (jsonDecode(maps[0]['periods']) as List)
              .map((p) => TaskPeriod.fromJson(p))
              .toList(),
          dailyRecords: (jsonDecode(maps[0]['dailyRecords']) as List)
              .map((r) => DailyRecord.fromJson(r))
              .toList(),
        );
      }
      return null;
    } catch (e) {
      print('Error getting task card: $e');
      return null;
    }
  }

  Future<void> deleteTaskCard(String id) async {
    try {
      Database db = await database;
      await db.delete(
        'task_cards',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('TaskCard deleted: $id');
    } catch (e) {
      print('Error deleting task card: $e');
      rethrow;
    }
  }

  // Task Group methods
  Future<void> saveTaskGroup(TaskGroup group) async {
    try {
      Database db = await database;
      await db.insert(
        'task_groups',
        {
          'id': group.id,
          'name': group.name,
          'description': group.description,
          'sortOrder': group.sortOrder,
          'createdAt': group.createdAt.toIso8601String(),
          'updatedAt': group.updatedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('TaskGroup saved: ${group.id}');
    } catch (e) {
      print('Error saving task group: $e');
      rethrow;
    }
  }

  Future<List<TaskGroup>> getAllTaskGroups() async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'task_groups',
        orderBy: 'sortOrder ASC',
      );
      print('Found ${maps.length} task groups');
      return List.generate(maps.length, (i) {
        return TaskGroup(
          id: maps[i]['id'],
          name: maps[i]['name'],
          description: maps[i]['description'],
          sortOrder: maps[i]['sortOrder'],
          createdAt: DateTime.parse(maps[i]['createdAt']),
          updatedAt: DateTime.parse(maps[i]['updatedAt']),
        );
      });
    } catch (e) {
      print('Error getting task groups: $e');
      return [];
    }
  }

  Future<TaskGroup?> getTaskGroup(String id) async {
    try {
      Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'task_groups',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return TaskGroup(
          id: maps[0]['id'],
          name: maps[0]['name'],
          description: maps[0]['description'],
          sortOrder: maps[0]['sortOrder'],
          createdAt: DateTime.parse(maps[0]['createdAt']),
          updatedAt: DateTime.parse(maps[0]['updatedAt']),
        );
      }
      return null;
    } catch (e) {
      print('Error getting task group: $e');
      return null;
    }
  }

  Future<void> deleteTaskGroup(String id) async {
    try {
      Database db = await database;
      // 删除分组前，将该分组下的任务卡设为未分组
      await db.update(
        'task_cards',
        {'groupId': null},
        where: 'groupId = ?',
        whereArgs: [id],
      );
      // 删除分组
      await db.delete(
        'task_groups',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('TaskGroup deleted: $id');
    } catch (e) {
      print('Error deleting task group: $e');
      rethrow;
    }
  }

  Future<List<TaskCard>> getTaskCardsByGroup(String? groupId) async {
    try {
      Database db = await database;
      List<Map<String, dynamic>> maps;
      
      if (groupId == null || groupId == TaskGroupPresets.allGroupId) {
        // 获取所有任务卡
        maps = await db.query(
          'task_cards',
          orderBy: 'updatedAt DESC',
        );
      } else if (groupId == TaskGroupPresets.ungroupedId) {
        // 获取未分组的任务卡
        maps = await db.query(
          'task_cards',
          where: 'groupId IS NULL',
          orderBy: 'updatedAt DESC',
        );
      } else {
        // 获取指定分组的任务卡
        maps = await db.query(
          'task_cards',
          where: 'groupId = ?',
          whereArgs: [groupId],
          orderBy: 'updatedAt DESC',
        );
      }
      
      return List.generate(maps.length, (i) {
        return TaskCard(
          id: maps[i]['id'],
          stockName: maps[i]['stockName'],
          groupId: maps[i]['groupId'],
          createdAt: DateTime.parse(maps[i]['createdAt']),
          updatedAt: DateTime.parse(maps[i]['updatedAt']),
          periods: (jsonDecode(maps[i]['periods']) as List)
              .map((p) => TaskPeriod.fromJson(p))
              .toList(),
          dailyRecords: (jsonDecode(maps[i]['dailyRecords']) as List)
              .map((r) => DailyRecord.fromJson(r))
              .toList(),
        );
      });
    } catch (e) {
      print('Error getting task cards by group: $e');
      return [];
    }
  }

  Future<void> moveTaskCardToGroup(String cardId, String? groupId) async {
    try {
      Database db = await database;
      await db.update(
        'task_cards',
        {'groupId': groupId},
        where: 'id = ?',
        whereArgs: [cardId],
      );
      print('TaskCard moved to group: $cardId -> $groupId');
    } catch (e) {
      print('Error moving task card to group: $e');
      rethrow;
    }
  }
}
