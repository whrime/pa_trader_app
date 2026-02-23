import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trade_record.dart';

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
        version: 2,
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
      print('Database table created successfully');
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
}
