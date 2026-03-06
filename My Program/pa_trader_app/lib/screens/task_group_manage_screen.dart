import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_group.dart';
import '../services/database_service.dart';

class TaskGroupManageScreen extends StatefulWidget {
  const TaskGroupManageScreen({Key? key}) : super(key: key);

  @override
  State<TaskGroupManageScreen> createState() => _TaskGroupManageScreenState();
}

class _TaskGroupManageScreenState extends State<TaskGroupManageScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<TaskGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final groups = await _databaseService.getAllTaskGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    }
  }

  Future<void> _deleteGroup(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个分组吗？分组下的任务卡将变为未分组状态。'),
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
        await _databaseService.deleteTaskGroup(id);
        await _loadGroups();
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

  Future<void> _editGroup(TaskGroup group) async {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description ?? '');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑分组'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '分组名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '分组描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入分组名称')),
                );
                return;
              }
              
              final updatedGroup = group.copyWith(
                name: nameController.text.trim(),
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                updatedAt: DateTime.now(),
              );
              
              await _databaseService.saveTaskGroup(updatedGroup);
              await _loadGroups();
              
              if (mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('更新成功')),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _addGroup() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建分组'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '分组名称',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '分组描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入分组名称')),
                );
                return;
              }
              
              final newGroup = TaskGroup(
                id: const Uuid().v4(),
                name: nameController.text.trim(),
                description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                sortOrder: _groups.length,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await _databaseService.saveTaskGroup(newGroup);
              await _loadGroups();
              
              if (mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('创建成功')),
                );
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );

    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _moveGroup(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    
    setState(() {
      final group = _groups.removeAt(oldIndex);
      _groups.insert(newIndex, group);
      
      for (int i = 0; i < _groups.length; i++) {
        _groups[i] = _groups[i].copyWith(sortOrder: i);
      }
    });

    try {
      for (final group in _groups) {
        await _databaseService.saveTaskGroup(group);
      }
    } catch (e) {
      await _loadGroups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('排序失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分组管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addGroup,
            tooltip: '新建分组',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _buildEmptyView()
              : ReorderableListView.builder(
                  itemCount: _groups.length,
                  onReorder: _moveGroup,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return _GroupListItem(
                      key: ValueKey(group.id),
                      group: group,
                      index: index,
                      onEdit: () => _editGroup(group),
                      onDelete: () => _deleteGroup(group.id),
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
          const Icon(Icons.folder_open, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '暂无自定义分组',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addGroup,
            icon: const Icon(Icons.add),
            label: const Text('创建第一个分组'),
          ),
        ],
      ),
    );
  }
}

class _GroupListItem extends StatelessWidget {
  final TaskGroup group;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GroupListItem({
    super.key,
    required this.group,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: group.description != null
            ? Text(
                group.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
              tooltip: '编辑',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }
}
