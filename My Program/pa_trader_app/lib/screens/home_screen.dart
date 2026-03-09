import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'setup_list_screen.dart';
import 'trading_calculator_screen.dart';
import 'history_screen.dart';
import 'review_list_screen.dart';
import 'task_card_list_screen.dart';
import '../models/trade_record.dart';
import '../models/setup_option.dart';
import '../models/review_option.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static _HomeScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HomeScreenState>();
  }
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  final GlobalKey<TradingCalculatorScreenState> _calculatorKey = GlobalKey();
  final GlobalKey<SetupListScreenState> _setupListKey = GlobalKey();
  final GlobalKey<ReviewListScreenState> _reviewListKey = GlobalKey();
  
  List<SetupOption> _customSetups = [];
  List<ReviewOption> _customReviews = [];
  List<SetupOption> get allSetups {
    final customIds = _customSetups.map((s) => s.id).toSet();
    final filteredPredefined = SetupOption.predefinedList.where((s) => !customIds.contains(s.id));
    final all = [...filteredPredefined, ..._customSetups];
    all.sort((a, b) {
      final numA = int.tryParse(a.id) ?? 999;
      final numB = int.tryParse(b.id) ?? 999;
      return numA.compareTo(numB);
    });
    return all;
  }
  Map<String, SetupOption> get allSetupOptions {
    return {for (var setup in allSetups) setup.name: setup};
  }

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    
    _screens.addAll([
      // Setup和复盘组合在一起
      Scaffold(
        appBar: AppBar(
          title: const Text('策略与复盘'),
          leading: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.upload_file),
                  title: Text('导出'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('导入'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                if (_tabController.index == 0) {
                  _setupListKey.currentState?.performSearch();
                } else {
                  _reviewListKey.currentState?.performSearch();
                }
              },
              tooltip: '搜索',
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_tabController.index == 0) {
                  _setupListKey.currentState?.performAdd();
                } else {
                  _reviewListKey.currentState?.performAdd();
                }
              },
              tooltip: '新增',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Setup'),
              Tab(text: '复盘'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            SetupListScreen(key: _setupListKey, onSetupsChanged: _updateSetups),
            ReviewListScreen(key: _reviewListKey, onReviewsChanged: _updateReviews),
          ],
        ),
      ),
      TradingCalculatorScreen(key: _calculatorKey),
      const TaskCardListScreen(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateSetups(List<SetupOption> customSetups) {
    setState(() {
      _customSetups = customSetups;
    });
    _calculatorKey.currentState?.updateSetupOptions(allSetupOptions);
    _setupListKey.currentState?.updateCustomSetups(customSetups);
  }

  void _updateReviews(List<ReviewOption> customReviews) {
    setState(() {
      _customReviews = customReviews;
    });
    _reviewListKey.currentState?.updateCustomReviews(customReviews);
  }

  void _handleEditRecord(TradeRecord record) {
    setState(() {
      _selectedIndex = 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatorKey.currentState?.loadRecordForEdit(record);
    });
  }

  void switchToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleMenuAction(String action) {
    if (_tabController.index == 0) {
      if (action == 'export') {
        _exportSetup();
      } else if (action == 'import') {
        _importSetup();
      }
    } else {
      if (action == 'export') {
        _exportReview();
      } else if (action == 'import') {
        _importReview();
      }
    }
  }

  Future<void> _exportSetup() async {
    try {
      final exportData = {
        'setups': _customSetups.map((s) => s.toJson()).toList(),
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      final buffer = StringBuffer();
      buffer.writeln('# Setup策略数据导出');
      buffer.writeln('# 导出时间: ${DateTime.now()}');
      buffer.writeln('# ============================================');
      buffer.writeln();
      buffer.writeln('# --- JSON DATA START ---');
      buffer.writeln(jsonString);
      buffer.writeln('# --- JSON DATA END ---');

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'setup_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      await _openFolderAndSelectFile(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出成功: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _exportReview() async {
    try {
      final exportData = {
        'reviews': _customReviews.map((r) => r.toJson()).toList(),
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      final buffer = StringBuffer();
      buffer.writeln('# 复盘数据导出');
      buffer.writeln('# 导出时间: ${DateTime.now()}');
      buffer.writeln('# ============================================');
      buffer.writeln();
      buffer.writeln('# --- JSON DATA START ---');
      buffer.writeln(jsonString);
      buffer.writeln('# --- JSON DATA END ---');

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'review_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      await _openFolderAndSelectFile(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出成功: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _importSetup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      String? jsonString;
      final lines = content.split('\n');
      bool inJsonBlock = false;
      final jsonLines = <String>[];

      for (final line in lines) {
        if (line.contains('# --- JSON DATA START ---')) {
          inJsonBlock = true;
          continue;
        }
        if (line.contains('# --- JSON DATA END ---')) {
          inJsonBlock = false;
          break;
        }
        if (inJsonBlock) {
          jsonLines.add(line);
        }
      }

      if (jsonLines.isNotEmpty) {
        jsonString = jsonLines.join('\n');
      } else {
        jsonString = content;
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      if (jsonData.containsKey('setups')) {
        final setups = jsonData['setups'] as List;
        int importCount = 0;
        
        for (var item in setups) {
          final setup = SetupOption.fromJson(item as Map<String, dynamic>);
          final existingIndex = _customSetups.indexWhere((s) => s.id == setup.id);
          if (existingIndex == -1) {
            _customSetups.add(setup);
            importCount++;
          }
        }
        
        _updateSetups(_customSetups);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 $importCount 个Setup策略')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _importReview() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      String? jsonString;
      final lines = content.split('\n');
      bool inJsonBlock = false;
      final jsonLines = <String>[];

      for (final line in lines) {
        if (line.contains('# --- JSON DATA START ---')) {
          inJsonBlock = true;
          continue;
        }
        if (line.contains('# --- JSON DATA END ---')) {
          inJsonBlock = false;
          break;
        }
        if (inJsonBlock) {
          jsonLines.add(line);
        }
      }

      if (jsonLines.isNotEmpty) {
        jsonString = jsonLines.join('\n');
      } else {
        jsonString = content;
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      if (jsonData.containsKey('reviews')) {
        final reviews = jsonData['reviews'] as List;
        int importCount = 0;
        
        for (var item in reviews) {
          final review = ReviewOption.fromJson(item as Map<String, dynamic>);
          final existingIndex = _customReviews.indexWhere((r) => r.id == review.id);
          if (existingIndex == -1) {
            _customReviews.add(review);
            importCount++;
          }
        }
        
        _updateReviews(_customReviews);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 $importCount 个复盘策略')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _openFolderAndSelectFile(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', filePath]);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [File(filePath).parent.path]);
      }
    } catch (e) {
      print('打开文件夹失败: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculatorKey.currentState?.updateSetupOptions(allSetupOptions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '策略与复盘',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: '计算器',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: '任务卡',
          ),
        ],
      ),
    );
  }
}
