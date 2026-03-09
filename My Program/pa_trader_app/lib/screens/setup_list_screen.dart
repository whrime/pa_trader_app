import 'package:flutter/material.dart';
import '../models/setup_option.dart';
import 'setup_detail_screen.dart';
import 'setup_edit_screen.dart';

class SetupListScreen extends StatefulWidget {
  final Function(SetupOption)? onSelectSetup;
  final Function(List<SetupOption>)? onSetupsChanged;

  const SetupListScreen({
    Key? key,
    this.onSelectSetup,
    this.onSetupsChanged,
  }) : super(key: key);

  @override
  State<SetupListScreen> createState() => SetupListScreenState();
}

class SetupListScreenState extends State<SetupListScreen> {
  List<SetupOption> _customSetups = [];

  @override
  void initState() {
    super.initState();
    _loadCustomSetups();
  }

  Future<void> _loadCustomSetups() async {
    setState(() {});
  }

  void _notifySetupsChanged() {
    widget.onSetupsChanged?.call(_customSetups);
  }

  void updateCustomSetups(List<SetupOption> customSetups) {
    setState(() {
      _customSetups = customSetups;
    });
  }

  List<SetupOption> get _allSetups {
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

  void performSearch() {
    final setups = _allSetups;
    showSearch(
      context: context,
      delegate: _SetupSearchDelegate(setups, widget.onSelectSetup, _isCustomSetup, _navigateToEdit, _deleteCustomSetup),
    );
  }

  void performAdd() {
    _navigateToEdit();
  }

  Future<void> _navigateToEdit({SetupOption? setup}) async {
    final result = await Navigator.push<SetupOption>(
      context,
      MaterialPageRoute(
        builder: (context) => SetupEditScreen(setup: setup),
      ),
    );

    if (result != null) {
      setState(() {
        if (setup != null) {
          final index = _customSetups.indexWhere((s) => s.id == setup.id);
          if (index != -1) {
            _customSetups[index] = result;
          } else {
            _customSetups.add(result);
          }
        } else {
          _customSetups.add(result);
        }
      });
      _notifySetupsChanged();
    }
  }

  void _deleteCustomSetup(SetupOption setup) {
    setState(() {
      _customSetups.removeWhere((s) => s.id == setup.id);
    });
    _notifySetupsChanged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('删除成功')),
    );
  }

  bool _isCustomSetup(SetupOption setup) {
    return _customSetups.any((s) => s.id == setup.id);
  }

  @override
  Widget build(BuildContext context) {
    final setups = _allSetups;

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: setups.length,
        itemBuilder: (context, index) {
          final setup = setups[index];
          final isCustom = _isCustomSetup(setup);
          return _SetupCard(
            setup: setup,
            index: index,
            isCustom: isCustom,
            onTap: () {
              if (widget.onSelectSetup != null) {
                widget.onSelectSetup!(setup);
                Navigator.pop(context);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetupDetailScreen(
                      setups: setups,
                      initialIndex: index,
                    ),
                  ),
                );
              }
            },
            onEdit: () => _navigateToEdit(setup: setup),
            onDelete: isCustom ? () => _deleteCustomSetup(setup) : null,
          );
        },
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final SetupOption setup;
  final int index;
  final bool isCustom;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SetupCard({
    required this.setup,
    required this.index,
    required this.isCustom,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCustom
                        ? [Colors.green[400]!, Colors.green[600]!]
                        : [Colors.blue[400]!, Colors.blue[600]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            setup.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '自定义',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      setup.shortDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (isCustom)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupSearchDelegate extends SearchDelegate {
  final List<SetupOption> setups;
  final Function(SetupOption)? onSelectSetup;
  final bool Function(SetupOption) isCustomSetup;
  final Function({SetupOption? setup}) navigateToEdit;
  final Function(SetupOption) deleteCustomSetup;

  _SetupSearchDelegate(this.setups, this.onSelectSetup, this.isCustomSetup, this.navigateToEdit, this.deleteCustomSetup);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = setups.where((setup) {
      return setup.name.toLowerCase().contains(query.toLowerCase()) ||
          setup.shortDescription.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final setup = results[index];
        final isCustom = isCustomSetup(setup);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isCustom ? Colors.green[400] : Colors.blue[400],
            child: Text(
              setup.name[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(setup.name)),
              if (isCustom)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '自定义',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            setup.shortDescription,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isCustom
              ? IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => deleteCustomSetup(setup),
                )
              : null,
          onTap: () {
            if (onSelectSetup != null) {
              onSelectSetup!(setup);
              close(context, null);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SetupDetailScreen(
                    setups: results,
                    initialIndex: index,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
