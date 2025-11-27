import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/activity_log.dart';
import '../../providers/activity_log_provider.dart';
import '../../widgets/pagination_widget.dart';

class AdminActivityLogsScreen extends ConsumerStatefulWidget {
  const AdminActivityLogsScreen({super.key});

  @override
  ConsumerState<AdminActivityLogsScreen> createState() =>
      _AdminActivityLogsScreenState();
}

class _AdminActivityLogsScreenState
    extends ConsumerState<AdminActivityLogsScreen> {
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('MMM dd, yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    // Load logs on init
    Future.microtask(() => ref.read(activityLogProvider.notifier).loadActivityLogs());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(activityLogProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          _buildStatisticsCard(state),
          
          // Search Bar
          _buildSearchBar(),
          
          // Filter Chips
          if (_hasActiveFilters(state)) _buildActiveFilters(state),
          
          // Logs List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? _buildErrorState(state.error!)
                    : state.logs.isEmpty
                        ? _buildEmptyState()
                        : _buildLogsList(state),
          ),
          
          // Pagination
          if (state.totalPages > 1) _buildPagination(state),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(ActivityLogState state) {
    // Show simple statistics without calling RPC (until schema is deployed)
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Logs',
                  state.totalCount.toString(),
                  Icons.list,
                  Colors.blue,
                ),
                _buildStatItem(
                  'Current Page',
                  '${state.currentPage}/${state.totalPages}',
                  Icons.pages,
                  Colors.green,
                ),
                _buildStatItem(
                  'Showing',
                  state.logs.length.toString(),
                  Icons.analytics,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search logs by description...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(activityLogProvider.notifier).clearFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            ref.read(activityLogProvider.notifier).searchLogs(value);
          }
        },
      ),
    );
  }

  bool _hasActiveFilters(ActivityLogState state) {
    return state.filterAction != null ||
        state.filterEntity != null ||
        state.startDate != null ||
        state.endDate != null;
  }

  Widget _buildActiveFilters(ActivityLogState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (state.filterAction != null)
            Chip(
              label: Text('Action: ${state.filterAction!.value}'),
              onDeleted: () {
                ref.read(activityLogProvider.notifier).setActionFilter(null);
              },
            ),
          if (state.filterEntity != null)
            Chip(
              label: Text('Entity: ${state.filterEntity!.value}'),
              onDeleted: () {
                ref.read(activityLogProvider.notifier).setEntityFilter(null);
              },
            ),
          if (state.startDate != null || state.endDate != null)
            Chip(
              label: Text(
                'Date: ${state.startDate != null ? _dateFormat.format(state.startDate!) : 'All'} - ${state.endDate != null ? _dateFormat.format(state.endDate!) : 'Now'}',
              ),
              onDeleted: () {
                ref.read(activityLogProvider.notifier).setDateRange(null, null);
              },
            ),
          TextButton.icon(
            onPressed: () {
              ref.read(activityLogProvider.notifier).clearFilters();
            },
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsList(ActivityLogState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(activityLogProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: state.logs.length,
        itemBuilder: (context, index) {
          final log = state.logs[index];
          return _buildLogCard(log);
        },
      ),
    );
  }

  Widget _buildLogCard(ActivityLog log) {
    final actionColor = _getActionColor(log.action);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Action Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: actionColor),
                    ),
                    child: Text(
                      log.action.value,
                      style: TextStyle(
                        color: actionColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Entity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.entity.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Timestamp
                  Text(
                    _dateFormat.format(log.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              if (log.description != null && log.description!.isNotEmpty)
                Text(
                  log.description!,
                  style: theme.textTheme.bodyMedium,
                ),
              const SizedBox(height: 4),
              // User Info
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      log.userName ?? 'User #${log.userId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  if (log.entityId != null)
                    Text(
                      'ID: ${log.entityId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getActionColor(ActivityAction action) {
    switch (action) {
      case ActivityAction.create:
        return Colors.green;
      case ActivityAction.update:
        return Colors.blue;
      case ActivityAction.delete:
        return Colors.red;
      case ActivityAction.login:
        return Colors.purple;
      case ActivityAction.logout:
        return Colors.grey;
      case ActivityAction.publish:
        return Colors.teal;
      case ActivityAction.unpublish:
        return Colors.orange;
      case ActivityAction.enroll:
        return Colors.indigo;
      case ActivityAction.unenroll:
        return Colors.brown;
      case ActivityAction.submit:
        return Colors.cyan;
      case ActivityAction.grade:
        return Colors.amber;
      case ActivityAction.export:
        return Colors.deepPurple;
      case ActivityAction.import:
        return Colors.pink;
      case ActivityAction.archive:
        return Colors.blueGrey;
      case ActivityAction.restore:
        return Colors.lightGreen;
      case ActivityAction.approve:
        return Colors.green;
      case ActivityAction.reject:
        return Colors.red;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No activity logs found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Activity will appear here as users interact with the system',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading activity logs',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(activityLogProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(ActivityLogState state) {
    return PaginationWidget(
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      hasPreviousPage: state.hasPreviousPage,
      hasNextPage: state.hasNextPage,
      onPreviousPage: () => ref.read(activityLogProvider.notifier).previousPage(),
      onNextPage: () => ref.read(activityLogProvider.notifier).nextPage(),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const ActivityLogFilterDialog(),
    );
  }

  void _showLogDetails(ActivityLog log) {
    showDialog(
      context: context,
      builder: (context) => ActivityLogDetailDialog(log: log),
    );
  }
}

/// Filter Dialog
class ActivityLogFilterDialog extends ConsumerStatefulWidget {
  const ActivityLogFilterDialog({super.key});

  @override
  ConsumerState<ActivityLogFilterDialog> createState() =>
      _ActivityLogFilterDialogState();
}

class _ActivityLogFilterDialogState
    extends ConsumerState<ActivityLogFilterDialog> {
  ActivityAction? _selectedAction;
  EntityType? _selectedEntity;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final state = ref.read(activityLogProvider);
    _selectedAction = state.filterAction;
    _selectedEntity = state.filterEntity;
    _startDate = state.startDate;
    _endDate = state.endDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Activity Logs'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Filter
            const Text(
              'Action Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ActivityAction>(
              initialValue: _selectedAction,
              decoration: const InputDecoration(
                hintText: 'All Actions',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Actions'),
                ),
                ...ActivityAction.values.map(
                  (action) => DropdownMenuItem(
                    value: action,
                    child: Text(action.value),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedAction = value);
              },
            ),
            const SizedBox(height: 16),
            // Entity Filter
            const Text(
              'Entity Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<EntityType>(
              initialValue: _selectedEntity,
              decoration: const InputDecoration(
                hintText: 'All Entities',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Entities'),
                ),
                ...EntityType.values.map(
                  (entity) => DropdownMenuItem(
                    value: entity,
                    child: Text(entity.value),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedEntity = value);
              },
            ),
            const SizedBox(height: 16),
            // Date Range
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startDate != null
                          ? DateFormat('MMM dd, yyyy').format(_startDate!)
                          : 'Start Date',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: _startDate ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _endDate != null
                          ? DateFormat('MMM dd, yyyy').format(_endDate!)
                          : 'End Date',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(activityLogProvider.notifier).clearFilters();
            Navigator.pop(context);
          },
          child: const Text('Clear All'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(activityLogProvider.notifier)
              ..setActionFilter(_selectedAction)
              ..setEntityFilter(_selectedEntity)
              ..setDateRange(_startDate, _endDate);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

/// Log Detail Dialog
class ActivityLogDetailDialog extends StatelessWidget {
  final ActivityLog log;

  const ActivityLogDetailDialog({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');

    return AlertDialog(
      title: Text('${log.actionText} ${log.entityText}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Log ID', log.activityLogId.toString()),
            _buildInfoRow('User', log.userName ?? 'User #${log.userId}'),
            if (log.userEmail != null)
              _buildInfoRow('Email', log.userEmail!),
            _buildInfoRow('Action', log.action.value),
            _buildInfoRow('Entity', log.entity.value),
            if (log.entityId != null)
              _buildInfoRow('Entity ID', log.entityId.toString()),
            if (log.description != null && log.description!.isNotEmpty)
              _buildInfoRow('Description', log.description!),
            _buildInfoRow('Timestamp', dateFormat.format(log.createdAt)),
            if (log.ipAddress != null)
              _buildInfoRow('IP Address', log.ipAddress!),
            if (log.userAgent != null)
              _buildInfoRow('User Agent', log.userAgent!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
