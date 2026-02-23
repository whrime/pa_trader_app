import 'package:flutter/material.dart';
import 'setup_list_screen.dart';
import 'trading_calculator_screen.dart';
import 'history_screen.dart';
import '../models/trade_record.dart';
import '../models/setup_option.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static _HomeScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HomeScreenState>();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<TradingCalculatorScreenState> _calculatorKey = GlobalKey();
  final GlobalKey<SetupListScreenState> _setupListKey = GlobalKey();
  
  List<SetupOption> _customSetups = [];
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
    _screens.addAll([
      SetupListScreen(key: _setupListKey, onSetupsChanged: _updateSetups),
      TradingCalculatorScreen(key: _calculatorKey),
      HistoryScreen(
        onEditRecord: (record) {
          _handleEditRecord(record);
        },
      ),
    ]);
  }

  void _updateSetups(List<SetupOption> customSetups) {
    setState(() {
      _customSetups = customSetups;
    });
    _calculatorKey.currentState?.updateSetupOptions(allSetupOptions);
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
            label: 'Setup',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: '计算器',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '历史',
          ),
        ],
      ),
    );
  }
}
