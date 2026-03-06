import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/task_card.dart';
import '../models/task_group.dart';
import '../services/database_service.dart';
import 'task_card_edit_screen.dart';
import 'task_card_detail_screen.dart';
import 'task_group_manage_screen.dart';

class TaskCardListScreen extends StatefulWidget {
  const TaskCardListScreen({Key? key}) : super(key: key);

  @override
  State<TaskCardListScreen> createState() => _TaskCardListScreenState();
}

class _TaskCardListScreenState extends State<TaskCardListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<TaskCard> _taskCards = [];
  List<TaskGroup> _groups = [];
  String? _selectedGroupId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _loadGroups();
      await _loadTaskCards();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    }
  }

  Future<void> _loadGroups() async {
    final groups = await _databaseService.getAllTaskGroups();
    final defaultGroups = TaskGroupPresets.defaultGroups;
    
    // 合并默认分组和自定义分组
    final allGroups = [...defaultGroups, ...groups];
    
    // 按 sortOrder 排序
    allGroups.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    
    // 如果当前选中的分组不存在，重置为"全部"
    if (_selectedGroupId != null && 
        !allGroups.any((g) => g.id == _selectedGroupId)) {
      _selectedGroupId = TaskGroupPresets.allGroupId;
    }
    
    // 如果还没有选中分组，默认选中"全部"
    if (_selectedGroupId == null) {
      _selectedGroupId = TaskGroupPresets.allGroupId;
    }
    
    setState(() {
      _groups = allGroups;
    });
  }

  Future<void> _loadTaskCards() async {
    final cards = await _databaseService.getTaskCardsByGroup(_selectedGroupId);
    // 按优先级排序
    cards.sort((a, b) {
      final scoreA = a.priorityScore.abs();
      final scoreB = b.priorityScore.abs();
      return scoreB.compareTo(scoreA);
    });
    setState(() {
      _taskCards = cards;
      _isLoading = false;
    });
  }

  Future<void> _deleteTaskCard(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个任务卡吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _databaseService.deleteTaskCard(id);
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Future<void> _moveTaskCardToGroup(TaskCard card) async {
    final groups = _groups.where((g) => 
      g.id != TaskGroupPresets.allGroupId && 
      g.id != TaskGroupPresets.ungroupedId
    ).toList();
    
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先创建分组')),
      );
      return;
    }

    final selectedGroup = await showDialog<TaskGroup>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移动到分组'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                title: Text(group.name),
                subtitle: group.description != null ? Text(group.description!) : null,
                onTap: () => Navigator.pop(context, group),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (selectedGroup != null) {
      try {
        await _databaseService.moveTaskCardToGroup(card.id, selectedGroup!.id);
        await _loadTaskCards();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已移动到 ${selectedGroup!.name}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移动失败: $e')),
        );
      }
    }
  }

  Future<void> _exportToTxt() async {
    try {
      // 使用JSON格式导出，便于导入时解析
      final exportData = {
        'groups': _groups.where((g) => 
          g.id != TaskGroupPresets.allGroupId && 
          g.id != TaskGroupPresets.ungroupedId
        ).map((g) => g.toJson()).toList(),
        'taskCards': _taskCards.map((card) => card.toJson()).toList(),
      };
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // 添加文件头信息
      final StringBuffer buffer = StringBuffer();
      buffer.writeln('# 任务卡数据导出');
      buffer.writeln('# 导出时间: ${DateTime.now()}');
      buffer.writeln('# 版本: 2.0');
      buffer.writeln('# ============================================');
      buffer.writeln();
      buffer.writeln('# 以下是JSON格式数据，请勿修改此标记之间的内容');
      buffer.writeln('# --- JSON DATA START ---');
      buffer.writeln(jsonString);
      buffer.writeln('# --- JSON DATA END ---');
      buffer.writeln();
      buffer.writeln('# 以上是JSON格式数据');

      // 保存到下载目录
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final fileName = 'task_cards_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(buffer.toString());

      // 自动打开文件夹并选中文件
      await _openFolderAndSelectFile(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出成功: ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    }
  }

  // 打开文件夹并选中文件
  Future<void> _openFolderAndSelectFile(String filePath) async {
    try {
      final file = File(filePath);
      final directory = file.parent.path;
      
      if (Platform.isWindows) {
        // Windows: 使用 explorer /select 打开文件夹并选中文件
        await Process.run('explorer', ['/select,', filePath.replaceAll('/', '\\')]);
      } else if (Platform.isMacOS) {
        // macOS: 使用 open 命令
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isLinux) {
        // Linux: 打开文件夹
        await Process.run('xdg-open', [directory]);
      } else {
        // 其他平台：使用 url_launcher 打开文件夹
        final uri = Uri.file(directory);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      print('打开文件夹失败: $e');
      // 如果失败，使用分享功能
      final file = File(filePath);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '任务卡数据导出',
      );
    }
  }

  Future<void> _importFromTxt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();

      Map<String, dynamic>? jsonData;

      // 首先尝试从导出的txt文件中提取JSON数据
      final startMarker = '# --- JSON DATA START ---';
      final endMarker = '# --- JSON DATA END ---';
      
      if (content.contains(startMarker) && content.contains(endMarker)) {
        // 是导出的txt格式，提取JSON部分
        final startIndex = content.indexOf(startMarker) + startMarker.length;
        final endIndex = content.indexOf(endMarker);
        
        if (startIndex > 0 && endIndex > startIndex) {
          String jsonString = content.substring(startIndex, endIndex).trim();
          // 移除可能的注释行
          jsonString = jsonString.split('\n')
              .where((line) => !line.trim().startsWith('#'))
              .join('\n');
          
          try {
            jsonData = jsonDecode(jsonString);
          } catch (e) {
            print('提取JSON失败: $e');
          }
        }
      }

      // 如果不是txt格式或提取失败，尝试直接解析整个内容为JSON
      if (jsonData == null) {
        try {
          jsonData = jsonDecode(content);
        } catch (e) {
          print('直接解析JSON失败: $e');
        }
      }

      // 解析数据并保存
      if (jsonData != null) {
        int groupCount = 0;
        int cardCount = 0;
        
        // 导入分组
        if (jsonData!.containsKey('groups')) {
          final groups = jsonData['groups'] as List?;
          if (groups != null) {
            for (var item in groups) {
              try {
                final group = TaskGroup.fromJson(item as Map<String, dynamic>);
                await _databaseService.saveTaskGroup(group);
                groupCount++;
              } catch (e) {
                print('导入分组失败: $e');
              }
            }
          }
        }
        
        // 导入任务卡
        if (jsonData.containsKey('taskCards')) {
          final cards = jsonData['taskCards'] as List?;
          if (cards != null) {
            for (var item in cards) {
              try {
                final card = TaskCard.fromJson(item as Map<String, dynamic>);
                final newCard = TaskCard(
                  id: card.id,
                  stockName: card.stockName,
                  groupId: card.groupId,
                  createdAt: card.createdAt,
                  updatedAt: DateTime.now(),
                  periods: card.periods,
                  dailyRecords: card.dailyRecords,
                );
                await _databaseService.saveTaskCard(newCard);
                cardCount++;
              } catch (e) {
                print('导入任务卡失败: $e');
              }
            }
          }
        }

        if (groupCount > 0 || cardCount > 0) {
          await _loadData();
          final message = groupCount > 0 && cardCount > 0
              ? '成功导入 $groupCount 个分组和 $cardCount 个任务卡'
              : groupCount > 0
                  ? '成功导入 $groupCount 个分组'
                  : '成功导入 $cardCount 个任务卡';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未能导入任何数据，请检查文件格式')),
          );
        }
      } else {
        // 无法解析，显示错误提示
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('导入失败'),
            content: const Text('无法识别文件格式。请确保导入的是通过本应用导出的txt文件或有效的JSON文件。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    }
  }

  void _showScoreHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('评分系统说明'),
        content: SingleChildScrollView(
          child: Text(scoreDescription),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _onGroupSelected(String groupId) {
    setState(() {
      _selectedGroupId = groupId;
    });
    _loadTaskCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务卡'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showScoreHelp,
            tooltip: '评分说明',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TaskGroupManageScreen(),
                ),
              );
              if (result == true) {
                await _loadData();
              }
            },
            tooltip: '分组管理',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _exportToTxt,
            tooltip: '导出',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _importFromTxt,
            tooltip: '导入',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 分组选择器
                _buildGroupSelector(),
                // 任务卡列表
                Expanded(
                  child: _taskCards.isEmpty
                      ? _buildEmptyView()
                      : _buildListView(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskCardEditScreen(),
            ),
          );
          if (result == true) {
            await _loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupSelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          final isSelected = _selectedGroupId == group.id;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(group.name),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onGroupSelected(group.id);
                }
              },
              selectedColor: group.id == TaskGroupPresets.allGroupId
                  ? Colors.blue
                  : group.id == TaskGroupPresets.ungroupedId
                      ? Colors.orange
                      : Colors.green,
              checkmarkColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _selectedGroupId == TaskGroupPresets.ungroupedId
                ? '暂无未分组的任务卡'
                : '暂无任务卡',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (_selectedGroupId != TaskGroupPresets.ungroupedId)
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskCardEditScreen(),
                  ),
                );
                if (result == true) {
                  await _loadData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('添加第一个任务卡'),
            ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _taskCards.length,
      itemBuilder: (context, index) {
        final card = _taskCards[index];
        return _TaskCardItem(
          card: card,
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskCardDetailScreen(taskCard: card),
              ),
            );
            if (result == true) {
              await _loadData();
            }
          },
          onEdit: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskCardEditScreen(taskCard: card),
              ),
            );
            if (result == true) {
              await _loadData();
            }
          },
          onDelete: () => _deleteTaskCard(card.id),
          onMoveToGroup: () => _moveTaskCardToGroup(card),
        );
      },
    );
  }
}

class _TaskCardItem extends StatelessWidget {
  final TaskCard card;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMoveToGroup;

  const _TaskCardItem({
    required this.card,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveToGroup,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = card.priorityLevel.color;
    final score = card.priorityScore;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      card.stockName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: score >= 0 ? Colors.red[50] : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: score >= 0 ? Colors.red[200]! : Colors.green[200]!,
                      ),
                    ),
                    child: Text(
                      score >= 0 ? '+${score.toStringAsFixed(2)}' : score.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: score >= 0 ? Colors.red[700] : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      card.priorityLevel.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: priorityColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '周期: ${card.periods.length}个',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(card.updatedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              if (card.periods.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: card.periods.map((period) {
                    final hasData = period.data != null;
                    return Chip(
                      label: Text(
                        period.periodType,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasData ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      backgroundColor: hasData ? Colors.blue : Colors.grey[200],
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.folder_open, size: 20, color: Colors.blue),
                    onPressed: onMoveToGroup,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: '移动到分组',
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
